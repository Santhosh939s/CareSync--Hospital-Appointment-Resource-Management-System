import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/appointment.dart';
import '../../providers/appointment_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

/// Doctor Consultation Screen: records diagnosis, writes prescription,
/// and allocates hospital resources (Beds, Blood Bank units, Diagnostic scans).
class ConsultationScreen extends StatefulWidget {
  final Appointment appointment;

  const ConsultationScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _problemController;
  final _prescriptionController = TextEditingController();

  // Resource allocations
  bool _admitBed = false;
  bool _needBlood = false;
  String _bloodType = 'O+';
  int _bloodUnits = 1;
  String _scanRequired = 'None';

  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  final List<String> _scanOptions = ['None', 'MRI', 'CT-Scan', 'X-Ray', 'Ventilator'];

  @override
  void initState() {
    super.initState();
    _problemController = TextEditingController(text: widget.appointment.problem ?? '');
  }

  @override
  void dispose() {
    _problemController.dispose();
    _prescriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitConsultation() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final apptProv = context.read<AppointmentProvider>();
    final success = await apptProv.completeConsultation(
      appointmentId: widget.appointment.id,
      problem: _problemController.text,
      prescription: _prescriptionController.text,
      admitPatientBed: _admitBed,
      bloodType: _needBlood ? _bloodType : null,
      bloodUnits: _needBlood ? _bloodUnits : 0,
      scanRequired: _scanRequired != 'None' ? _scanRequired : null,
    );

    if (!mounted) return;

    if (success) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.healthGood, size: 48),
          title: const Text('Consultation Completed'),
          content: Text(
            'Prescription filed successfully for patient ${widget.appointment.patientId}.\n\n'
            'Backend business logic executed:\n'
            '• Consultation fee ($200) ledger logged\n'
            '${_admitBed ? '• Hospital bed allocated ($500)\n' : ''}'
            '${_needBlood ? '• $_bloodUnits units ($_bloodType) deducted and allocated\n' : ''}'
            '${_scanRequired != 'None' ? '• Prescribed diagnostic scan: $_scanRequired\n' : ''}',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // dialog
                Navigator.of(context).pop(); // screen
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } else if (apptProv.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(apptProv.errorMessage!),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final apptProv = context.watch<AppointmentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Consultation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Patient Banner
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                      child: Icon(Icons.person_rounded, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patient: ${widget.appointment.patientId}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            'Time Slot: ${widget.appointment.slot} • ${widget.appointment.date}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 1. Clinical Diagnosis
              const Text(
                '1. CLINICAL DIAGNOSIS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _problemController,
                hint: 'Enter patient symptoms, clinical observations, or diagnosis...',
                maxLines: 3,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Diagnosis / symptoms cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 2. Prescription & Medication
              const Text(
                '2. MEDICINES & DOSAGE INSTRUCTIONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _prescriptionController,
                hint: 'e.g. Paracetamol 500mg (1-0-1 after food) x 5 days\nRest and adequate hydration',
                maxLines: 4,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Prescription / medication instructions are required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 3. Hospital Resource Allocations
              const Text(
                '3. HOSPITAL RESOURCE ALLOCATION (OPTIONAL)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),

              // Bed Admission Switch
              AppCard(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.healthGood.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.hotel_rounded, color: AppTheme.healthGood, size: 20),
                  ),
                  title: const Text('Admit Patient to Bed', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Deducts 1 bed and logs \$500 admission ledger', style: TextStyle(fontSize: 12)),
                  value: _admitBed,
                  onChanged: (val) => setState(() => _admitBed = val),
                ),
              ),
              const SizedBox(height: 10),

              // Blood Requirement Switch & Pickers
              AppCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.water_drop_rounded, color: Colors.redAccent, size: 20),
                      ),
                      title: const Text('Blood Requirement', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Transfusion allocation and PO trigger', style: TextStyle(fontSize: 12)),
                      value: _needBlood,
                      onChanged: (val) => setState(() => _needBlood = val),
                    ),
                    if (_needBlood) ...[
                      const Divider(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _bloodType,
                              decoration: const InputDecoration(labelText: 'Blood Type'),
                              items: _bloodTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                              onChanged: (val) => setState(() => _bloodType = val ?? 'O+'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Row(
                              children: [
                                IconButton.outlined(
                                  icon: const Icon(Icons.remove, size: 16),
                                  onPressed: _bloodUnits > 1 ? () => setState(() => _bloodUnits--) : null,
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      '$_bloodUnits Units',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                ),
                                IconButton.outlined(
                                  icon: const Icon(Icons.add, size: 16),
                                  onPressed: _bloodUnits < 10 ? () => setState(() => _bloodUnits++) : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Diagnostic Scan Requirement
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.biotech_rounded, color: Colors.blueAccent, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Prescribe Diagnostic Scan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text('Enables patient to book machine slot', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _scanRequired,
                      decoration: const InputDecoration(labelText: 'Equipment / Machine'),
                      items: _scanOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => _scanRequired = val ?? 'None'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Complete Consultation Action
              PrimaryButton(
                title: 'Complete Consultation & Submit',
                icon: Icons.check_circle_rounded,
                isLoading: apptProv.isLoading,
                onPressed: _submitConsultation,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
