import '../core/storage/local_storage.dart';
import '../models/appointment.dart';

/// Service managing unread prescription and appointment notifications.
class NotificationService {
  final LocalStorage _storage;

  NotificationService({LocalStorage? storage})
      : _storage = storage ?? LocalStorage();

  /// Returns whether a given appointment has an unread prescription update.
  bool hasUnreadUpdate(Appointment appointment) {
    if (!appointment.isUpdated) return false;
    final viewedIds = _storage.getViewedPrescriptionIds();
    return !viewedIds.contains(appointment.id);
  }

  /// Calculates total unread prescription updates for a patient's appointments.
  int getUnreadCount(List<Appointment> appointments) {
    final viewedIds = _storage.getViewedPrescriptionIds();
    return appointments
        .where((a) => a.isUpdated && !viewedIds.contains(a.id))
        .length;
  }

  /// Marks an appointment prescription as viewed.
  Future<void> markAsViewed(String appointmentId) async {
    await _storage.markPrescriptionViewed(appointmentId);
  }
}
