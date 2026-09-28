import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/resource.dart';
import '../../providers/resource_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/resource_card.dart';

/// Admin Screen to view, audit, and calibrate hospital inventory limits.
class ResourceManagementScreen extends StatefulWidget {
  const ResourceManagementScreen({super.key});

  @override
  State<ResourceManagementScreen> createState() => _ResourceManagementScreenState();
}

class _ResourceManagementScreenState extends State<ResourceManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ResourceProvider>().loadResources();
    });
  }

  void _showEditBedsSheet(BedResource beds) {
    int available = beds.available;
    int total = beds.total;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Adjust Hospital Beds', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildCounterRow('Total Capacity', total, (val) => setSheetState(() => total = val)),
              const SizedBox(height: 12),
              _buildCounterRow('Available Beds', available, (val) => setSheetState(() => available = val)),
              const SizedBox(height: 24),
              PrimaryButton(
                title: 'Save Changes',
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final prov = context.read<ResourceProvider>();
                  final current = prov.resource;
                  if (current != null) {
                    final updated = current.copyWith(
                      beds: BedResource(total: total, available: available),
                    );
                    await prov.updateResourceTotals(updated);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounterRow(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Row(
          children: [
            IconButton.outlined(
              icon: const Icon(Icons.remove, size: 16),
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
            ),
            SizedBox(
              width: 48,
              child: Center(
                child: Text(
                  value.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            IconButton.outlined(
              icon: const Icon(Icons.add, size: 16),
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resProv = context.watch<ResourceProvider>();
    final resource = resProv.resource;

    if (resProv.isLoading && resource == null) {
      return const Scaffold(body: LoadingView(message: 'Loading resource status...'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => resProv.loadResources(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => resProv.loadResources(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Beds Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'INPATIENT BEDS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                TextButton.icon(
                  onPressed: resource != null ? () => _showEditBedsSheet(resource.beds) : null,
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (resource != null)
              ResourceCard(
                title: 'General & ICU Beds',
                available: resource.beds.available,
                total: resource.beds.total,
                unit: 'beds',
                icon: Icons.hotel_rounded,
                onTap: () => _showEditBedsSheet(resource.beds),
              ),

            const SizedBox(height: 24),

            // Blood Bank Section
            const Text(
              'BLOOD BANK INVENTORY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Thresholds: Critical (<10 units), Limited (10-20 units), Healthy (>20 units)',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),

            if (resource != null)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: resource.bloodBank.length,
                itemBuilder: (context, index) {
                  final key = resource.bloodBank.keys.elementAt(index);
                  final units = resource.bloodBank[key] ?? 0;

                  Color statusColor;
                  String label;
                  if (units < 10) {
                    statusColor = Colors.redAccent;
                    label = 'Critical';
                  } else if (units <= 20) {
                    statusColor = Colors.amber.shade700;
                    label = 'Limited';
                  } else {
                    statusColor = AppTheme.healthGood;
                    label = 'Good';
                  }

                  return AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              key,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              label,
                              style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Text(
                          '$units Units',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: statusColor),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 24),

            // Diagnostic Equipment Section
            const Text(
              'EQUIPMENT INVENTORY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),

            if (resource != null)
              ...resource.equipment.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ResourceCard(
                    title: entry.key,
                    available: entry.value.available,
                    total: entry.value.total,
                    unit: 'units',
                    icon: Icons.biotech_rounded,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
