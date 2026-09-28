import 'package:flutter/material.dart';

import 'primary_button.dart';

/// Clean empty state with icon, message, and optional call to action.
class EmptyView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionTitle;
  final VoidCallback? onAction;

  const EmptyView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionTitle,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 52,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.65),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (actionTitle != null && onAction != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                title: actionTitle!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
