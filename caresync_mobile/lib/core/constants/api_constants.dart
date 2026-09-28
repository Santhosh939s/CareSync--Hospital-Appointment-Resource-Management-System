/// API and application constants for CareSync Mobile.
class ApiConstants {
  ApiConstants._();

  /// Use 10.0.2.2 for Android emulator to reach host localhost.
  /// Switch to the Render URL for production builds.
  static const String baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'https://hospital-appointment-and-resource.onrender.com/api');

  // Auth
  static const String login = '/login';
  static const String register = '/users';
  static const String users = '/users';
  static const String guestLogin = '/guest-login';

  // Data
  static const String allData = '/data';
  static const String data = '/data';

  // Appointments
  static const String appointments = '/appointments';
  static String appointmentById(String id) => '$appointments/$id';

  // Scans
  static const String scans = '/scans';

  // Resources
  static const String resources = '/resources';
}
