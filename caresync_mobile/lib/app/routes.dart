import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/prescription.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/admin/appointments_management_screen.dart';
import '../screens/admin/doctor_roster_screen.dart';
import '../screens/admin/resource_management_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/doctor/consultation_screen.dart';
import '../screens/doctor/doctor_home_screen.dart';
import '../screens/doctor/doctor_schedule_screen.dart';
import '../screens/doctor/prescription_edit_screen.dart';
import '../screens/patient/appointment_details_screen.dart';
import '../screens/patient/appointments_screen.dart';
import '../screens/patient/book_appointment_screen.dart';
import '../screens/patient/patient_home_screen.dart';
import '../screens/patient/prescription_details_screen.dart';
import '../screens/patient/prescriptions_screen.dart';
import '../screens/patient/scan_booking_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/splash/splash_screen.dart';

/// Centralized route definitions and dynamic route generation for CareSync Mobile.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Patient routes
  static const String patientHome = '/patient/home';
  static const String bookAppointment = '/patient/book-appointment';
  static const String patientAppointments = '/patient/appointments';
  static const String appointmentDetails = '/patient/appointment-details';
  static const String prescriptions = '/patient/prescriptions';
  static const String prescriptionDetails = '/patient/prescription-details';
  static const String scanBooking = '/patient/scan-booking';

  // Doctor routes
  static const String doctorHome = '/doctor/home';
  static const String doctorSchedule = '/doctor/schedule';
  static const String consultation = '/doctor/consultation';
  static const String prescriptionEdit = '/doctor/prescription-edit';

  // Admin routes
  static const String adminHome = '/admin/home';
  static const String adminResources = '/admin/resources';
  static const String adminAppointments = '/admin/appointments';
  static const String adminDoctors = '/admin/doctors';

  // Common
  static const String profile = '/profile';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      // Patient
      case patientHome:
        return MaterialPageRoute(builder: (_) => const PatientHomeScreen());
      case bookAppointment:
        return MaterialPageRoute(builder: (_) => const BookAppointmentScreen());
      case patientAppointments:
        return MaterialPageRoute(builder: (_) => const AppointmentsScreen());
      case appointmentDetails:
        final appt = settings.arguments as Appointment;
        return MaterialPageRoute(builder: (_) => AppointmentDetailsScreen(appointment: appt));
      case prescriptions:
        return MaterialPageRoute(builder: (_) => const PrescriptionsScreen());
      case prescriptionDetails:
        final rx = settings.arguments as Prescription;
        return MaterialPageRoute(builder: (_) => PrescriptionDetailsScreen(prescription: rx));
      case scanBooking:
        final eq = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => ScanBookingScreen(initialEquipment: eq));

      // Doctor
      case doctorHome:
        return MaterialPageRoute(builder: (_) => const DoctorHomeScreen());
      case doctorSchedule:
        return MaterialPageRoute(builder: (_) => const DoctorScheduleScreen());
      case consultation:
        final appt = settings.arguments as Appointment;
        return MaterialPageRoute(builder: (_) => ConsultationScreen(appointment: appt));
      case prescriptionEdit:
        final appt = settings.arguments as Appointment;
        return MaterialPageRoute(builder: (_) => PrescriptionEditScreen(appointment: appt));

      // Admin
      case adminHome:
        return MaterialPageRoute(builder: (_) => const AdminHomeScreen());
      case adminResources:
        return MaterialPageRoute(builder: (_) => const ResourceManagementScreen());
      case adminAppointments:
        return MaterialPageRoute(builder: (_) => const AppointmentsManagementScreen());
      case adminDoctors:
        return MaterialPageRoute(builder: (_) => const DoctorRosterScreen());

      // Common
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
