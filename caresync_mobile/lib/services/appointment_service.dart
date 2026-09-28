import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';
import '../core/exceptions/app_exceptions.dart';
import '../core/network/api_client.dart';
import '../models/appointment.dart';

/// Service managing appointments, booking logic, and slot availability validation.
class AppointmentService {
  final ApiClient _client;

  AppointmentService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Fetches all appointments from the system.
  Future<List<Appointment>> getAllAppointments() async {
    try {
      final response = await _client.get(ApiConstants.data);
      final results = response['d']?['results'] as Map<String, dynamic>?;
      final rawList = results?['hms_appointments'] as List<dynamic>? ?? [];

      return rawList
          .whereType<Map<String, dynamic>>()
          .map((json) => Appointment.fromJson(json))
          .toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to retrieve appointments: ${e.toString()}');
    }
  }

  /// Fetches appointments for a specific patient.
  Future<List<Appointment>> getPatientAppointments(String patientId) async {
    final all = await getAllAppointments();
    return all.where((a) => a.patientId == patientId).toList();
  }

  /// Fetches appointments for a specific doctor.
  Future<List<Appointment>> getDoctorAppointments(String doctorId) async {
    final all = await getAllAppointments();
    return all.where((a) => a.doctorId == doctorId).toList();
  }

  /// Checks the booking count for each time slot for a doctor on a specific date.
  ///
  /// Enforces maximum 3 patients per slot rule.
  Future<Map<String, int>> getSlotBookings({
    required String doctorId,
    required String date,
  }) async {
    final all = await getAllAppointments();
    final counts = <String, int>{};

    for (final slot in AppConstants.timeSlots) {
      counts[slot] = 0;
    }

    for (final appt in all) {
      if (appt.doctorId == doctorId &&
          appt.date == date &&
          appt.status != AppConstants.statusCancelled) {
        counts[appt.slot] = (counts[appt.slot] ?? 0) + 1;
      }
    }

    return counts;
  }

  /// Books a new appointment after verifying slot availability to prevent race conditions.
  Future<Appointment> bookAppointment({
    required String doctorId,
    required String patientId,
    required String date,
    required String slot,
    String? problem,
  }) async {
    // 1. Fresh availability check right before booking to avoid race conditions
    final currentBookings = await getSlotBookings(doctorId: doctorId, date: date);
    final currentCount = currentBookings[slot] ?? 0;

    if (currentCount >= AppConstants.maxPatientsPerSlot) {
      throw const ValidationException(
        message: 'This time slot is now fully booked (maximum 3 patients reached). Please select another slot.',
      );
    }

    // 2. Prevent duplicate booking for the same patient on same doctor/date/slot
    final all = await getAllAppointments();
    final hasDuplicate = all.any((a) =>
        a.patientId == patientId &&
        a.date == date &&
        a.slot == slot &&
        a.status != AppConstants.statusCancelled);

    if (hasDuplicate) {
      throw const ValidationException(
        message: 'You already have an appointment scheduled at this time.',
      );
    }

    // 3. Post new appointment
    final id = 'apt${DateTime.now().millisecondsSinceEpoch}';
    final payload = {
      'id': id,
      'doctorId': doctorId,
      'patientId': patientId,
      'date': date,
      'slot': slot,
      'status': AppConstants.statusScheduled,
      if (problem != null && problem.isNotEmpty) 'problem': problem,
    };

    final response = await _client.post(ApiConstants.appointments, body: payload);
    final apptJson = response['appointment'] as Map<String, dynamic>?;

    if (apptJson == null) {
      throw const ApiException(message: 'Failed to record appointment on server.');
    }

    return Appointment.fromJson(apptJson);
  }

  /// Updates appointment status (e.g., Cancelled, Scheduled, Completed).
  Future<Appointment> updateStatus({
    required String appointmentId,
    required String status,
  }) async {
    final response = await _client.put(
      ApiConstants.appointmentById(appointmentId),
      body: {'status': status},
    );

    final apptJson = response['appointment'] as Map<String, dynamic>?;
    if (apptJson == null) {
      throw const ApiException(message: 'Failed to update appointment status.');
    }

    return Appointment.fromJson(apptJson);
  }
}
