import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_constants.dart';
import '../../models/appointment.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/empty_view.dart';

/// Admin Screen to audit all appointments, filter across doctors/patients, and force-cancel visits.
class AppointmentsManagementScreen extends StatefulWidget {
  const AppointmentsManagementScreen({super.key});

  @override
  State<AppointmentsManagementScreen> createState() => _AppointmentsManagementScreenState();
}

class _AppointmentsManagementScreenState extends State<AppointmentsManagementScreen> {
  String _selectedStatus = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final apptProv = context.watch<AppointmentProvider>();
    final all = apptProv.appointments;

    // Filter
    final filtered = all.where((a) {
      if (_selectedStatus != 'All' &&
          a.status.toLowerCase() != _selectedStatus.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchPatient = a.patientId.toLowerCase().contains(query);
        final matchDoctor = a.doctorId.toLowerCase().contains(query);
        final matchSlot = a.slot.toLowerCase().contains(query);
        final matchDate = a.date.toLowerCase().contains(query);
        if (!matchPatient && !matchDoctor && !matchSlot && !matchDate) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments Management'),
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
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by patient, doctor, or date...',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
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

          // Appointment List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => apptProv.loadData(auth.currentUser),
              child: filtered.isEmpty
                  ? const Center(
                      child: EmptyView(
                        title: 'No Appointments Found',
                        message: 'No records match your search query or filter.',
                        icon: Icons.calendar_month_outlined,
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final appt = filtered[index];
                        final doctor = apptProv.getDoctorById(appt.doctorId);
                        final canForceCancel = appt.status == AppConstants.statusScheduled;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppointmentCard(
                            appointment: appt,
                            doctor: doctor,
                            trailingAction: canForceCancel
                                ? OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
                                      side: const BorderSide(color: Colors.redAccent),
                                    ),
                                    onPressed: () => _forceCancel(context, appt),
                                    icon: const Icon(Icons.cancel_outlined, size: 16),
                                    label: const Text('Force Cancel Appointment'),
                                  )
                                : null,
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.appointmentDetails,
                                arguments: appt,
                              );
                            },
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

  void _forceCancel(BuildContext context, Appointment appt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Force Cancel Appointment?'),
        content: Text('Are you sure you want to cancel appointment ${appt.id} for patient ${appt.patientId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep'),
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
            child: const Text('Cancel Visit'),
          ),
        ],
      ),
    );
  }
}
