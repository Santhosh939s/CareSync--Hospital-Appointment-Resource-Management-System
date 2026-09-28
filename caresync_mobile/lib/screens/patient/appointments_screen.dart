import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_constants.dart';
import '../../models/appointment.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/empty_view.dart';

/// Screen listing patient appointments with status filtering and pull-to-refresh.
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final apptProv = context.watch<AppointmentProvider>();
    final patientId = auth.currentUser?.id ?? '';
    final all = apptProv.getPatientAppointments(patientId);

    // Apply filter
    final filtered = all.where((a) {
      if (_selectedFilter == 'All') return true;
      return a.status.toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
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
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                'All',
                AppConstants.statusScheduled,
                AppConstants.statusCompleted,
                AppConstants.statusCancelled,
              ].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = filter);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Appointment List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => apptProv.loadData(auth.currentUser),
              child: filtered.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: EmptyView(
                          title: 'No Appointments Found',
                          message: _selectedFilter == 'All'
                              ? 'You have not booked any appointments yet.'
                              : 'No appointments with status "$_selectedFilter".',
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
                        final doctor = apptProv.getDoctorById(appt.doctorId);
                        final isUnread = apptProv.isPrescriptionUnread(appt);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppointmentCard(
                            appointment: appt,
                            doctor: doctor,
                            showNotificationDot: isUnread,
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
}
