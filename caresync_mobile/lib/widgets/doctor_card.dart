import 'package:flutter/material.dart';

import '../models/doctor.dart';
import 'app_card.dart';

/// Card showing doctor information, department, and specialty.
class DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final bool isSelected;
  final VoidCallback? onTap;

  const DoctorCard({
    super.key,
    required this.doctor,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      borderColor: isSelected ? theme.colorScheme.primary : null,
      color: isSelected
          ? theme.colorScheme.primary.withOpacity(0.08)
          : null,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
            child: Text(
              doctor.name.isNotEmpty
                  ? doctor.name.replaceAll('Dr. ', '').substring(0, 1).toUpperCase()
                  : 'D',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doctor.specialty,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dept: ${doctor.department} • Max ${doctor.maxPatients} patients/slot',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
        ],
      ),
    );
  }
}
