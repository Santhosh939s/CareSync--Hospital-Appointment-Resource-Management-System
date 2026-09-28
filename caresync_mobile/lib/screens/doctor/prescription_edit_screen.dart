import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/appointment.dart';
import '../../providers/appointment_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

/// Screen allowing a doctor to revise clinical notes and prescription after a consultation.
///
/// Sets `isUpdated = true` so the patient receives an unread prescription update notification.
class PrescriptionEditScreen extends StatefulWidget {
  final Appointment appointment;

  const PrescriptionEditScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<PrescriptionEditScreen> createState() => _PrescriptionEditScreenState();
}

class _PrescriptionEditScreenState extends State<PrescriptionEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _problemController;
  late TextEditingController _prescriptionController;

  @override
  void initState() {
    super.initState();
    _problemController = TextEditingController(text: widget.appointment.problem ?? '');
    _prescriptionController = TextEditingController(text: widget.appointment.prescription ?? '');
  }

  @override
  void dispose() {
    _problemController.dispose();
    _prescriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final apptProv = context.read<AppointmentProvider>();
    final success = await apptProv.updatePrescription(
      appointmentId: widget.appointment.id,
      problem: _problemController.text,
      prescription: _prescriptionController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prescription revised and patient notified.'),
          backgroundColor: AppTheme.healthGood,
        ),
      );
      Navigator.of(context).pop();
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
        title: const Text('Edit Prescription'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                      child: Icon(Icons.person_rounded, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patient: ${widget.appointment.patientId}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            'Visit Date: ${widget.appointment.date} • ${widget.appointment.slot}',
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
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active_outlined, size: 20, color: Colors.amber.shade900),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Updating this prescription will alert the patient with an update badge indicator.',
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              CustomTextField(
                controller: _problemController,
                label: 'Diagnosis / Clinical Observations',
                hint: 'Symptoms and clinical diagnosis',
                maxLines: 3,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Diagnosis is required';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              CustomTextField(
                controller: _prescriptionController,
                label: 'Medicines & Instructions',
                hint: 'Prescription details and instructions',
                maxLines: 5,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Prescription is required';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              PrimaryButton(
                title: 'Save & Update Prescription',
                icon: Icons.save_outlined,
                isLoading: apptProv.isLoading,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
