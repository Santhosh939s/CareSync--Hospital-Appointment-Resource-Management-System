import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/constants/app_constants.dart';

/// Pill badge for displaying appointment and allocation lifecycle statuses.
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;

    switch (status) {
      case AppConstants.statusCompleted:
        textColor = AppTheme.statusCompleted;
        bgColor = AppTheme.statusCompleted.withOpacity(0.12);
        break;
      case AppConstants.statusCancelled:
        textColor = AppTheme.statusCancelled;
        bgColor = AppTheme.statusCancelled.withOpacity(0.12);
        break;
      case AppConstants.statusScheduled:
      default:
        textColor = AppTheme.statusScheduled;
        bgColor = AppTheme.statusScheduled.withOpacity(0.12);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
