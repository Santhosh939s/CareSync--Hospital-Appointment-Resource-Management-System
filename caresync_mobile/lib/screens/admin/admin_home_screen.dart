import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/resource_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/dashboard_metric_card.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/resource_card.dart';

/// Admin Mobile Dashboard summarizing hospital operations, inventory, and finances.
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    await Future.wait([
      context.read<ResourceProvider>().loadResources(),
      context.read<AppointmentProvider>().loadData(auth.currentUser),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resProv = context.watch<ResourceProvider>();
    final apptProv = context.watch<AppointmentProvider>();
    final resource = resProv.resource;

    if (resProv.isLoading && resource == null) {
      return const Scaffold(body: LoadingView(message: 'Loading hospital administration metrics...'));
    }

    // Blood bank total units
    int totalBloodUnits = 0;
    int criticalBloodTypes = 0;
    resource?.bloodBank.forEach((type, count) {
      totalBloodUnits += count;
      if (count <= 10) criticalBloodTypes++;
    });

    final totalAppts = apptProv.appointments.length;
    final totalDoctors = apptProv.doctors.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Administration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profile',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profile),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // KPI Metrics Row 1
            Row(
              children: [
                Expanded(
                  child: DashboardMetricCard(
                    title: 'Revenue Logged',
                    value: '\$${resProv.totalRevenue.toInt()}',
                    subtitle: '${resProv.financials.length} transactions',
                    icon: Icons.attach_money_rounded,
                    accentColor: AppTheme.healthGood,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DashboardMetricCard(
                    title: 'Total Visits',
                    value: totalAppts.toString(),
                    subtitle: 'All appointments',
                    icon: Icons.calendar_month_rounded,
                    accentColor: AppTheme.primaryTeal,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminAppointments),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DashboardMetricCard(
                    title: 'Medical Staff',
                    value: totalDoctors.toString(),
                    subtitle: 'Doctors roster',
                    icon: Icons.badge_rounded,
                    accentColor: Colors.blueAccent,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminDoctors),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Quick Navigation shortcuts
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminResources),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryTeal, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Inventory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Beds & Blood', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppCard(
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminAppointments),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.tune_rounded, color: Colors.blueAccent, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Manage Appts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('All visits', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Bed Capacity Overview
            const Text(
              'HOSPITAL BED CAPACITY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            if (resource != null)
              ResourceCard(
                title: 'Inpatient Beds',
                available: resource.beds.available,
                total: resource.beds.total,
                unit: 'beds',
                icon: Icons.hotel_rounded,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminResources),
              ),

            const SizedBox(height: 20),

            // Blood Bank Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'BLOOD BANK STATUS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (criticalBloodTypes > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$criticalBloodTypes Low Stock Alert',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            AppCard(
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminResources),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.water_drop_rounded, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Total Stock Units',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      Text(
                        '$totalBloodUnits Units',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (resource?.bloodBank.entries ?? []).map((entry) {
                      final isLow = entry.value <= 10;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isLow
                              ? Colors.redAccent.withOpacity(0.1)
                              : theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isLow ? Colors.redAccent.withOpacity(0.4) : theme.colorScheme.outline,
                          ),
                        ),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isLow ? Colors.redAccent : theme.colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Diagnostic Equipment Overview
            const Text(
              'EQUIPMENT & MACHINE STATUS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            if (resource != null)
              ...resource.equipment.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ResourceCard(
                    title: entry.key,
                    available: entry.value.available,
                    total: entry.value.total,
                    unit: 'machines',
                    icon: Icons.biotech_rounded,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminResources),
                  ),
                );
              }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
