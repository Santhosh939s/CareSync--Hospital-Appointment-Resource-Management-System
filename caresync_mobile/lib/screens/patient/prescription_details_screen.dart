import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/prescription.dart';
import '../../widgets/app_card.dart';
import '../../widgets/primary_button.dart';

/// Detailed digital prescription view mimicking official hospital clinical slips.
class PrescriptionDetailsScreen extends StatelessWidget {
  final Prescription prescription;

  const PrescriptionDetailsScreen({
    super.key,
    required this.prescription,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Prescription'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Clinical Header
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_hospital_rounded, color: AppTheme.primaryTeal, size: 28),
                      const SizedBox(width: 8),
                      const Text(
                        'CareSync Healthcare',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Official Clinical Electronic Prescription',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prescription.doctorName ?? 'Consulting Doctor',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            prescription.doctorSpecialty ?? 'Specialist',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Date: ${prescription.date}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          Text(
                            'Rx #${prescription.appointmentId.substring(prescription.appointmentId.length > 6 ? prescription.appointmentId.length - 6 : 0)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (prescription.isUpdated) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, size: 14, color: Colors.amber.shade900),
                          const SizedBox(width: 6),
                          Text(
                            prescription.updatedAt != null
                                ? 'Updated on ${prescription.updatedAt!.substring(0, 10)}'
                                : 'Prescription was updated by doctor',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Diagnosis Section
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.healing_rounded, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Clinical Diagnosis',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    prescription.problem != null && prescription.problem!.isNotEmpty
                        ? prescription.problem!
                        : 'No specific diagnosis recorded.',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Medications Section
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.medication_rounded, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Prescribed Medications & Instructions',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    prescription.medication != null && prescription.medication!.isNotEmpty
                        ? prescription.medication!
                        : 'No oral medication prescribed.',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Allocated Hospital Resources
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Clinical Allocations',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildResourceTile(
                    context,
                    Icons.hotel_rounded,
                    'Hospital Bed Admission',
                    prescription.hasAssignedBed ? 'Assigned' : 'Not required',
                    prescription.hasAssignedBed ? AppTheme.healthGood : Colors.grey,
                  ),
                  const Divider(height: 16),
                  _buildResourceTile(
                    context,
                    Icons.water_drop_rounded,
                    'Blood Transfusion',
                    prescription.hasBloodTransfusion
                        ? '${prescription.assignedResources!.blood!.units} Units (${prescription.assignedResources!.blood!.type})'
                        : 'Not required',
                    prescription.hasBloodTransfusion ? Colors.redAccent : Colors.grey,
                  ),
                  const Divider(height: 16),
                  _buildResourceTile(
                    context,
                    Icons.biotech_rounded,
                    'Diagnostic Scan',
                    prescription.hasScanRequired
                        ? prescription.assignedResources!.scan!
                        : 'None',
                    prescription.hasScanRequired ? Colors.blueAccent : Colors.grey,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Scan Booking Action if prescribed
            if (prescription.hasScanRequired) ...[
              PrimaryButton(
                title: 'Book Prescribed Scan (${prescription.assignedResources!.scan})',
                icon: Icons.biotech_outlined,
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.scanBooking,
                    arguments: prescription.assignedResources!.scan,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResourceTile(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    Color statusColor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: statusColor),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
      ],
    );
  }
}
