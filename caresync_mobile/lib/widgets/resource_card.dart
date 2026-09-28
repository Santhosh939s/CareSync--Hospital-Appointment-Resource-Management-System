import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'app_card.dart';

/// Resource indicator card with capacity progress bar and threshold status.
class ResourceCard extends StatelessWidget {
  final String title;
  final int available;
  final int total;
  final String unit;
  final IconData icon;
  final VoidCallback? onTap;

  const ResourceCard({
    super.key,
    required this.title,
    required this.available,
    required this.total,
    this.unit = '',
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = total > 0 ? (available / total).clamp(0.0, 1.0) : 0.0;

    // Threshold evaluation: <20% critical (red), 20-50% moderate (amber), >50% good (emerald)
    Color statusColor;
    String statusLabel;
    if (ratio < 0.20) {
      statusColor = AppTheme.healthCritical;
      statusLabel = 'Critical';
    } else if (ratio <= 0.50) {
      statusColor = AppTheme.healthModerate;
      statusLabel = 'Limited';
    } else {
      statusColor = AppTheme.healthGood;
      statusLabel = 'Healthy';
    }

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: statusColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$available / $total $unit available',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              Text(
                '${(ratio * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainer,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
