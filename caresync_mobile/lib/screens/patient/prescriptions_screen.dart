import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/prescription.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_view.dart';

/// Screen listing all clinical prescriptions for the authenticated patient.
class PrescriptionsScreen extends StatelessWidget {
  const PrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final apptProv = context.watch<AppointmentProvider>();
    final patientId = auth.currentUser?.id ?? '';
    final prescriptions = apptProv.getPatientPrescriptions(patientId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Prescriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => apptProv.loadData(auth.currentUser),
          ),
        ],
      ),
      body: prescriptions.isEmpty
          ? const EmptyView(
              title: 'No Prescriptions Yet',
              message: 'Digital prescriptions issued by doctors after consultations will appear here.',
              icon: Icons.receipt_long_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: prescriptions.length,
              itemBuilder: (context, index) {
                final rx = prescriptions[index];
                // Check matching appointment to determine unread status
                final apptMatch = apptProv.appointments.where((a) => a.id == rx.appointmentId);
                final isUnread = apptMatch.isNotEmpty && apptProv.isPrescriptionUnread(apptMatch.first);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: () {
                      apptProv.markPrescriptionRead(rx.appointmentId);
                      Navigator.of(context).pushNamed(
                        AppRoutes.prescriptionDetails,
                        arguments: rx,
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppTheme.primaryTeal.withOpacity(0.12),
                                  child: const Icon(
                                    Icons.receipt_long_rounded,
                                    color: AppTheme.primaryTeal,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          rx.doctorName ?? 'Consulting Doctor',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (isUnread) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Colors.redAccent,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      rx.doctorSpecialty ?? 'Specialist',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (rx.isUpdated)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'UPDATED',
                                  style: TextStyle(
                                    color: Colors.amber.shade900,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              rx.date,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            if (rx.hasScanRequired) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Scan: ${rx.assignedResources!.scan}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (rx.problem != null && rx.problem!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Diagnosis: ${rx.problem}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
