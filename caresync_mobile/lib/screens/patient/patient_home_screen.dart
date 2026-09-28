import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../services/app_update_service.dart';
import 'appointments_screen.dart';
import 'prescriptions_screen.dart';
import '../profile/profile_screen.dart';

/// Main Patient Screen with Bottom Navigation and Dashboard.
class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().currentUser;
    await context.read<AppointmentProvider>().loadData(user);
    if (!mounted) return;
    final updateInfo = await AppUpdateService().checkForUpdate();
    if (mounted && updateInfo != null && updateInfo.hasUpdate) {
      AppUpdateService.showUpdatePrompt(context, updateInfo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final apptProv = context.watch<AppointmentProvider>();
    final patientId = auth.currentUser?.id ?? '';
    final unreadCount = apptProv.getUnreadPrescriptionCount(patientId);

    final pages = [
      _PatientDashboardTab(onBookTap: () => Navigator.of(context).pushNamed(AppRoutes.bookAppointment)),
      const AppointmentsScreen(),
      const PrescriptionsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_selectedTabIndex],
      bottomNavigationBar: CareSyncBottomNavigation(
        currentIndex: _selectedTabIndex,
        unreadPrescriptionCount: unreadCount,
        onTap: (index) => setState(() => _selectedTabIndex = index),
      ),
      floatingActionButton: _selectedTabIndex == 0 || _selectedTabIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.bookAppointment),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Book Appointment'),
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}

class _PatientDashboardTab extends StatelessWidget {
  final VoidCallback onBookTap;

  const _PatientDashboardTab({required this.onBookTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final apptProv = context.watch<AppointmentProvider>();

    if (apptProv.isLoading && apptProv.appointments.isEmpty) {
      return const Scaffold(body: LoadingView(message: 'Loading hospital appointments...'));
    }

    if (apptProv.errorMessage != null && apptProv.appointments.isEmpty) {
      return Scaffold(
        body: ErrorView(
          message: apptProv.errorMessage!,
          onRetry: () => apptProv.loadData(auth.currentUser),
        ),
      );
    }

    final user = auth.currentUser;
    final patientName = user?.name ?? 'Patient';
    final patientId = user?.id ?? '';
    final upcoming = apptProv.getUpcomingAppointment(patientId);
    final doctor = upcoming != null ? apptProv.getDoctorById(upcoming.doctorId) : null;
    final recent = apptProv.getPatientAppointments(patientId);
    final unreadCount = apptProv.getUnreadPrescriptionCount(patientId);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
              child: Text(
                patientName.isNotEmpty ? patientName.substring(0, 1).toUpperCase() : 'P',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $patientName',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  'CareSync Patient Portal',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => apptProv.loadData(auth.currentUser),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => apptProv.loadData(auth.currentUser),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Upcoming Appointment Section
            const Text(
              'UPCOMING APPOINTMENT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),

            if (upcoming != null)
              AppointmentCard(
                appointment: upcoming,
                doctor: doctor,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.appointmentDetails,
                    arguments: upcoming,
                  );
                },
              )
            else
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      size: 40,
                      color: theme.colorScheme.primary.withOpacity(0.6),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No Upcoming Appointments',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Consult qualified specialists anytime.',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: onBookTap,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Schedule Now'),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Quick Service Cards
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.scanBooking),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.biotech_outlined, color: Colors.blueAccent, size: 20),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Book Scan',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'MRI, CT & X-Ray',
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppCard(
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.prescriptions),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryTeal.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.receipt_long_outlined, color: AppTheme.primaryTeal, size: 20),
                            ),
                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$unreadCount NEW',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Prescriptions',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Digital records',
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Consultations
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RECENT APPOINTMENTS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to Appointments tab
                  },
                  child: const Text('View All', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),

            if (recent.isEmpty)
              const EmptyView(
                title: 'No Appointments Found',
                message: 'Your booked appointments will appear here.',
                icon: Icons.calendar_today_outlined,
              )
            else
              ...recent.take(3).map((appt) {
                final doc = apptProv.getDoctorById(appt.doctorId);
                final isUnread = apptProv.isPrescriptionUnread(appt);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppointmentCard(
                    appointment: appt,
                    doctor: doc,
                    showNotificationDot: isUnread,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.appointmentDetails,
                        arguments: appt,
                      );
                    },
                  ),
                );
              }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
