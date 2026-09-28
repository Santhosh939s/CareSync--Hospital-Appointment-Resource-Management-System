import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/resource_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/primary_button.dart';

/// Equipment / Diagnostic Scan booking screen for patients.
class ScanBookingScreen extends StatefulWidget {
  final String? initialEquipment;

  const ScanBookingScreen({
    super.key,
    this.initialEquipment,
  });

  @override
  State<ScanBookingScreen> createState() => _ScanBookingScreenState();
}

class _ScanBookingScreenState extends State<ScanBookingScreen> {
  late String _selectedEquipment;
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;

  final List<Map<String, dynamic>> _equipmentOptions = [
    {'name': 'MRI', 'icon': Icons.scanner_rounded, 'desc': 'Magnetic Resonance Imaging'},
    {'name': 'CT-Scan', 'icon': Icons.radiology_rounded, 'desc': 'Computed Tomography 3D'},
    {'name': 'X-Ray', 'icon': Icons.broken_image_outlined, 'desc': 'Digital Radiography'},
    {'name': 'Ventilator', 'icon': Icons.air_rounded, 'desc': 'Respiratory Support System'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedEquipment = widget.initialEquipment ?? 'MRI';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ResourceProvider>().loadResources();
    });
  }

  String get _formattedDate => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
      });
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedSlot == null) return;

    final auth = context.read<AuthProvider>();
    final resProv = context.read<ResourceProvider>();
    final patientId = auth.currentUser?.id ?? '';

    final success = await resProv.bookScan(
      patientId: patientId,
      equipment: _selectedEquipment,
      date: _formattedDate,
      slot: _selectedSlot!,
    );

    if (!mounted) return;

    if (success) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline, color: AppTheme.healthGood, size: 48),
          title: const Text('Scan Scheduled!'),
          content: Text(
            'Your $_selectedEquipment scan has been successfully confirmed for $_formattedDate at $_selectedSlot.\n\nA financial ledger record and room allocation have been logged.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // dialog
                Navigator.of(context).pop(); // screen
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      );
    } else if (resProv.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resProv.errorMessage!),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resProv = context.watch<ResourceProvider>();
    final resource = resProv.resource;
    final eqData = resource?.equipment[_selectedEquipment];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Diagnostic Scan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Select Diagnostic Machine
            const Text(
              '1. SELECT DIAGNOSTIC EQUIPMENT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),

            ..._equipmentOptions.map((opt) {
              final isSelected = _selectedEquipment == opt['name'];
              final liveEq = resource?.equipment[opt['name']];

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  onTap: () => setState(() {
                    _selectedEquipment = opt['name'];
                    _selectedSlot = null;
                  }),
                  borderColor: isSelected ? theme.colorScheme.primary : null,
                  color: isSelected ? theme.colorScheme.primary.withOpacity(0.08) : null,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withOpacity(0.15)
                              : theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(opt['icon'] as IconData, color: isSelected ? theme.colorScheme.primary : null),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              opt['desc'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (liveEq != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${liveEq.available}/${liveEq.total}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: liveEq.available > 0 ? AppTheme.healthGood : Colors.redAccent,
                              ),
                            ),
                            Text(
                              liveEq.available > 0 ? 'Available' : 'In use',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 20),
                      ],
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // 2. Select Date
            const Text(
              '2. SELECT SCAN DATE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),
            AppCard(
              onTap: _selectDate,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  Text(
                    'Change',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Time Slots
            const Text(
              '3. SELECT TIME SLOT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppConstants.timeSlots.map((slot) {
                final isSelected = _selectedSlot == slot;
                return ChoiceChip(
                  label: Text(slot),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedSlot = selected ? slot : null);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Confirm Button
            PrimaryButton(
              title: 'Schedule Scan',
              icon: Icons.check_circle_outline_rounded,
              isLoading: resProv.isLoading,
              onPressed: (_selectedSlot != null && (eqData?.available ?? 1) > 0)
                  ? _confirmBooking
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
