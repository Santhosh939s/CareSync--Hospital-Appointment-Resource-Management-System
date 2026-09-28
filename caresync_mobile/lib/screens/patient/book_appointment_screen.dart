import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/doctor.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/doctor_card.dart';
import '../../widgets/primary_button.dart';

/// Appointment booking flow with real-time slot capacity checks (Max 3 patients/slot).
class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _problemController = TextEditingController();

  String? _selectedDepartment;
  Doctor? _selectedDoctor;
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAvailability();
    });
  }

  @override
  void dispose() {
    _problemController.dispose();
    super.dispose();
  }

  void _initAvailability() {
    final prov = context.read<AppointmentProvider>();
    if (prov.doctors.isNotEmpty) {
      final doc = prov.doctors.first;
      setState(() {
        _selectedDoctor = doc;
        _selectedDepartment = doc.department;
      });
      _refreshSlots(doc.id, _formattedDate);
    }
  }

  String get _formattedDate => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<void> _refreshSlots(String doctorId, String date) async {
    await context.read<AppointmentProvider>().checkSlotAvailability(
      doctorId: doctorId,
      date: date,
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null; // Reset slot selection on date change
      });
      if (_selectedDoctor != null) {
        _refreshSlots(_selectedDoctor!.id, DateFormat('yyyy-MM-dd').format(picked));
      }
    }
  }

  void _showConfirmationSheet() {
    if (_selectedDoctor == null || _selectedSlot == null) return;

    final theme = Theme.of(context);
    final auth = context.read<AuthProvider>();
    final apptProv = context.read<AppointmentProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Confirm Appointment',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Please verify the appointment details before confirming.',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  children: [
                    _buildSummaryRow('Doctor', _selectedDoctor!.name),
                    const Divider(height: 16),
                    _buildSummaryRow('Department', _selectedDoctor!.department),
                    const Divider(height: 16),
                    _buildSummaryRow('Date', DateFormat('EEE, MMM d, yyyy').format(_selectedDate)),
                    const Divider(height: 16),
                    _buildSummaryRow('Time Slot', _selectedSlot!),
                    if (_problemController.text.isNotEmpty) ...[
                      const Divider(height: 16),
                      _buildSummaryRow('Reason', _problemController.text),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                title: 'Confirm Booking',
                isLoading: apptProv.isLoading,
                icon: Icons.check_circle_rounded,
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final success = await apptProv.bookAppointment(
                    doctorId: _selectedDoctor!.id,
                    patientId: auth.currentUser?.id ?? '',
                    date: _formattedDate,
                    slot: _selectedSlot!,
                    problem: _problemController.text,
                  );

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Appointment scheduled successfully!'),
                        backgroundColor: AppTheme.healthGood,
                      ),
                    );
                    Navigator.of(context).pop();
                  } else if (mounted && apptProv.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(apptProv.errorMessage!),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final apptProv = context.watch<AppointmentProvider>();
    final doctors = apptProv.doctors;
    final slotBookings = apptProv.slotBookings;

    // Filter doctors by selected department if any
    final filteredDoctors = _selectedDepartment == null
        ? doctors
        : doctors.where((d) => d.department == _selectedDepartment).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Department Selection
              const Text(
                '1. SELECT DEPARTMENT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Cardiology',
                  'Neurology',
                  'Orthopedics',
                  'General Medicine',
                  'Pediatrics',
                ].map((dept) {
                  final isSelected = _selectedDepartment == dept;
                  return ChoiceChip(
                    label: Text(dept),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedDepartment = selected ? dept : null;
                        if (selected) {
                          // Auto-select first doctor in department
                          final match = doctors.where((d) => d.department == dept);
                          if (match.isNotEmpty) {
                            _selectedDoctor = match.first;
                            _refreshSlots(_selectedDoctor!.id, _formattedDate);
                          }
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // 2. Select Doctor
              const Text(
                '2. SELECT DOCTOR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),
              if (filteredDoctors.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No doctors available in this department.'),
                )
              else
                ...filteredDoctors.map((doc) {
                  final isSelected = _selectedDoctor?.id == doc.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DoctorCard(
                      doctor: doc,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedDoctor = doc;
                          _selectedSlot = null;
                        });
                        _refreshSlots(doc.id, _formattedDate);
                      },
                    ),
                  );
                }),

              const SizedBox(height: 24),

              // 3. Select Date
              const Text(
                '3. SELECT DATE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                onTap: _selectDate,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_month_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    Text(
                      'Change',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 4. Select Time Slot
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '4. SELECT TIME SLOT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  if (apptProv.isSlotChecking)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Max 3 patients per slot • Lunch break 12:00 PM – 2:00 PM',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AppConstants.timeSlots.map((slot) {
                  final booked = slotBookings[slot] ?? 0;
                  final isFull = booked >= AppConstants.maxPatientsPerSlot;
                  final isSelected = _selectedSlot == slot;

                  Color chipBorder = isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline;
                  Color chipBg = isSelected
                      ? theme.colorScheme.primary.withOpacity(0.12)
                      : (isFull ? theme.colorScheme.surfaceContainer : theme.colorScheme.surface);

                  return InkWell(
                    onTap: isFull
                        ? null
                        : () => setState(() => _selectedSlot = slot),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: (MediaQuery.of(context).size.width - 42) / 2,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: chipBorder, width: isSelected ? 2 : 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                slot,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isFull
                                      ? theme.colorScheme.onSurface.withOpacity(0.4)
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle, size: 16, color: theme.colorScheme.primary),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isFull
                                ? '3/3 FULL'
                                : (booked == 0 ? 'Available' : '$booked/3 booked'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isFull
                                  ? Colors.redAccent
                                  : (booked > 0 ? Colors.orange : AppTheme.healthGood),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // 5. Symptoms / Problem Input
              const Text(
                '5. SYMPTOMS / REASON (OPTIONAL)',
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
                hint: 'Describe your symptoms or reason for visit...',
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Submit Button
              PrimaryButton(
                title: 'Review & Confirm',
                icon: Icons.arrow_forward_rounded,
                onPressed: (_selectedDoctor != null && _selectedSlot != null)
                    ? _showConfirmationSheet
                    : null,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
