import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/appointment.dart';
import '../../models/prescription.dart';
import '../../providers/appointment_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_badge.dart';

/// Full screen view of appointment details, clinical notes, and prescription links.
class AppointmentDetailsScreen extends StatelessWidget {
  final Appointment appointment;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final apptProv = context.watch<AppointmentProvider>();
    final doctor = apptProv.getDoctorById(appointment.doctorId);

    final canCancel = appointment.status == AppConstants.statusScheduled;
    final isCompleted = appointment.status == AppConstants.statusCompleted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                    child: Icon(
                      Icons.medical_services_rounded,
                      size: 36,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    doctor?.name ?? appointment.doctorId,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor?.specialty ?? 'Hospital Department',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.65),
                    ),
                  ),
                  const SizedBox(height: 12),
                  StatusBadge(status: appointment.status),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Schedule info
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Schedule Details',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(context, Icons.calendar_today_rounded, 'Date', appointment.date),
                  const Divider(height: 16),
                  _buildDetailRow(context, Icons.access_time_rounded, 'Time Slot', appointment.slot),
                  const Divider(height: 16),
                  _buildDetailRow(context, Icons.tag_rounded, 'Appointment ID', appointment.id),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Patient Problem / Notes
            if (appointment.problem != null && appointment.problem!.isNotEmpty) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Clinical Notes / Symptoms',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      appointment.problem!,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Prescription link if completed
            if (isCompleted) ...[
              AppCard(
                color: theme.colorScheme.primary.withOpacity(0.06),
                borderColor: theme.colorScheme.primary.withOpacity(0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Prescription Ready',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        if (appointment.isUpdated) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'UPDATED',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Doctor has recorded consultation findings and medical prescription.',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () {
                        final prescription = Prescription.fromAppointment(
                          appointment,
                          doctorName: doctor?.name,
                          doctorSpecialty: doctor?.specialty,
                        );
                        Navigator.of(context).pushNamed(
                          AppRoutes.prescriptionDetails,
                          arguments: prescription,
                        );
                      },
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: const Text('View Digital Prescription'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Cancel action
            if (canCancel)
              PrimaryButton(
                title: 'Cancel Appointment',
                icon: Icons.cancel_outlined,
                color: Colors.redAccent,
                isLoading: apptProv.isLoading,
                onPressed: () => _confirmCancel(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: const Text(
          'Are you sure you want to cancel this scheduled appointment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Appointment'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await context.read<AppointmentProvider>().updateAppointmentStatus(
                appointmentId: appointment.id,
                status: AppConstants.statusCancelled,
              );
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment has been cancelled.')),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );
  }
}
