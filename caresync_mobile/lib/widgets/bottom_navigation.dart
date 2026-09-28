import 'package:flutter/material.dart';

/// Bottom navigation bar tailored for Patient and Admin screen switching.
class CareSyncBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int unreadPrescriptionCount;

  const CareSyncBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadPrescriptionCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: theme.colorScheme.surface,
      indicatorColor: theme.colorScheme.primary.withOpacity(0.15),
      elevation: 3,
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        const NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month_rounded),
          label: 'Appointments',
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: unreadPrescriptionCount > 0,
            label: Text(unreadPrescriptionCount.toString()),
            child: const Icon(Icons.medical_information_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: unreadPrescriptionCount > 0,
            label: Text(unreadPrescriptionCount.toString()),
            child: const Icon(Icons.medical_information_rounded),
          ),
          label: 'Prescriptions',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
