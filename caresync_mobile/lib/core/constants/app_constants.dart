/// Application-wide constants mirroring the backend business rules.
class AppConstants {
  AppConstants._();

  /// Available appointment time slots (matches backend TIME_SLOTS).
  static const List<String> timeSlots = [
    '10:00 AM',
    '11:00 AM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
  ];

  /// Maximum patients per doctor per time slot.
  static const int maxPatientsPerSlot = 3;

  /// Equipment scan time slots.
  static const List<String> scanSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
  ];

  /// Appointment statuses
  static const String statusScheduled = 'Scheduled';
  static const String statusCompleted = 'Completed';
  static const String statusCancelled = 'Cancelled';
  static const String statusPending = 'Pending';

  /// Roles
  static const String rolePatient = 'patient';
  static const String roleDoctor = 'doctor';
  static const String roleAdmin = 'admin';

  /// Local storage keys
  static const String keyUser = 'hms_currentUser';
  static const String keyThemeMode = 'caresync_theme';
  static const String keySeenUpdates = 'hms_seen_updates';
}
