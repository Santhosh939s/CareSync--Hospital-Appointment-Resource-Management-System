import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/appointment.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/empty_view.dart';

/// Doctor Schedule screen with date filtering, status tabs, and clinical actions.
class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  DateTime? _filterDate;
  String _selectedStatus = 'All';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null) {
      setState(() => _filterDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final apptProv = context.watch<AppointmentProvider>();
    final doctorId = auth.currentUser?.id ?? '';
    final all = apptProv.getDoctorAppointments(doctorId);

    // Apply filters
    final filtered = all.where((a) {
      if (_filterDate != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_filterDate!);
        if (a.date != dateStr) return false;
      }
      if (_selectedStatus != 'All') {
        if (a.status.toLowerCase() != _selectedStatus.toLowerCase()) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => apptProv.loadData(auth.currentUser),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Date picker chip
                ActionChip(
                  avatar: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(
                    _filterDate != null
                        ? DateFormat('MMM d, yyyy').format(_filterDate!)
                        : 'All Dates',
                  ),
                  onPressed: _pickDate,
                ),
                if (_filterDate != null) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    tooltip: 'Clear Date Filter',
                    onPressed: () => setState(() => _filterDate = null),
                  ),
                ],
              ],
            ),
          ),

          // Status Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                'All',
                AppConstants.statusScheduled,
                AppConstants.statusCompleted,
                AppConstants.statusCancelled,
              ].map((status) {
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedStatus = status);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Schedule List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => apptProv.loadData(auth.currentUser),
              child: filtered.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: EmptyView(
                          title: 'No Appointments Found',
                          message: 'No patient appointments match the selected filters.',
                          icon: Icons.calendar_month_outlined,
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final appt = filtered[index];
                        final isScheduled = appt.status == AppConstants.statusScheduled;
                        final isCompleted = appt.status == AppConstants.statusCompleted;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppointmentCard(
                            appointment: appt,
                            trailingAction: isScheduled
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.of(context).pushNamed(
                                              AppRoutes.consultation,
                                              arguments: appt,
                                            );
                                          },
                                          icon: const Icon(Icons.play_arrow_rounded, size: 16),
                                          label: const Text('Consult Patient'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.redAccent,
                                          side: const BorderSide(color: Colors.redAccent),
                                        ),
                                        onPressed: () => _cancelAppointment(context, appt),
                                        child: const Text('Decline'),
                                      ),
                                    ],
                                  )
                                : (isCompleted
                                    ? OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).pushNamed(
                                            AppRoutes.prescriptionEdit,
                                            arguments: appt,
                                          );
                                        },
                                        icon: const Icon(Icons.edit_note_rounded, size: 18),
                                        label: const Text('View / Edit Prescription'),
                                      )
                                    : null),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _cancelAppointment(BuildContext context, Appointment appt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Appointment?'),
        content: Text('Decline appointment for patient ${appt.patientId} at ${appt.slot}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<AppointmentProvider>().updateAppointmentStatus(
                appointmentId: appt.id,
                status: AppConstants.statusCancelled,
              );
            },
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }
}
