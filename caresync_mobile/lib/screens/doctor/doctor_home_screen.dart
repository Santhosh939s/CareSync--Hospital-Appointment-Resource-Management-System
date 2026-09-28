import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/appointment.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/dashboard_metric_card.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/loading_view.dart';

/// Doctor home dashboard showing today's queue, KPI metrics, and clinical actions.
class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      context.read<AppointmentProvider>().loadData(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final apptProv = context.watch<AppointmentProvider>();
    final doctorUser = auth.currentUser;
    final doctorId = doctorUser?.id ?? '';
    final doctorName = doctorUser?.name ?? 'Doctor';

    if (apptProv.isLoading && apptProv.appointments.isEmpty) {
      return const Scaffold(body: LoadingView(message: 'Loading clinical schedule...'));
    }

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayList = apptProv.getDoctorTodayAppointments(doctorId, todayStr);
    final pendingList = apptProv.getDoctorPendingAppointments(doctorId);
    final completedList = apptProv.getDoctorCompletedAppointments(doctorId);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              doctorName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Doctor Clinical Portal',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'View Full Schedule',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.doctorSchedule),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profile',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profile),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => apptProv.loadData(auth.currentUser),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // KPI Metrics Row
            Row(
              children: [
                Expanded(
                  child: DashboardMetricCard(
                    title: "Today's Visits",
                    value: todayList.length.toString(),
                    subtitle: todayStr,
                    icon: Icons.calendar_today_rounded,
                    accentColor: AppTheme.primaryTeal,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.doctorSchedule),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DashboardMetricCard(
                    title: 'Pending Queue',
                    value: pendingList.length.toString(),
                    subtitle: 'Needs review',
                    icon: Icons.pending_actions_rounded,
                    accentColor: Colors.amber.shade700,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.doctorSchedule),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DashboardMetricCard(
                    title: 'Completed',
                    value: completedList.length.toString(),
                    subtitle: 'Prescriptions filed',
                    icon: Icons.task_alt_rounded,
                    accentColor: AppTheme.healthGood,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.doctorSchedule),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Next Patient in Queue
            const Text(
              'NEXT PATIENT IN QUEUE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),

            if (pendingList.isNotEmpty) ...[
              _buildActivePatientCard(context, pendingList.first),
            ] else ...[
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 38,
                        color: AppTheme.healthGood.withOpacity(0.8),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'All Patients Attended To',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No pending appointments waiting for consultation.',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Today's Scheduled Visits
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "TODAY'S APPOINTMENTS",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.doctorSchedule),
                  child: const Text('View All', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),

            if (todayList.isEmpty)
              const EmptyView(
                title: 'No Visits for Today',
                message: 'No patient appointments scheduled for today.',
                icon: Icons.event_available_outlined,
              )
            else
              ...todayList.map((appt) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppointmentCard(
                    appointment: appt,
                    trailingAction: appt.status == AppConstants.statusScheduled
                        ? ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.consultation,
                                arguments: appt,
                              );
                            },
                            icon: const Icon(Icons.medical_information_outlined, size: 16),
                            label: const Text('Start Consultation'),
                          )
                        : (appt.status == AppConstants.statusCompleted
                            ? OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                    AppRoutes.prescriptionEdit,
                                    arguments: appt,
                                  );
                                },
                                icon: const Icon(Icons.edit_note_rounded, size: 16),
                                label: const Text('Edit Prescription'),
                              )
                            : null),
                    onTap: () {
                      if (appt.status == AppConstants.statusScheduled) {
                        Navigator.of(context).pushNamed(
                          AppRoutes.consultation,
                          arguments: appt,
                        );
                      } else {
                        Navigator.of(context).pushNamed(
                          AppRoutes.prescriptionEdit,
                          arguments: appt,
                        );
                      }
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePatientCard(BuildContext context, Appointment appt) {
    final theme = Theme.of(context);

    return AppCard(
      color: theme.colorScheme.primary.withOpacity(0.06),
      borderColor: theme.colorScheme.primary.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                    child: Icon(Icons.person_rounded, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient: ${appt.patientId}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'Slot: ${appt.slot} • ${appt.date}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'READY',
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (appt.problem != null && appt.problem!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Symptoms: ${appt.problem}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRoutes.consultation,
                arguments: appt,
              );
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Begin Consultation'),
          ),
        ],
      ),
    );
  }
}
