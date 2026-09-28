import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';
import '../core/exceptions/app_exceptions.dart';
import '../core/network/api_client.dart';
import '../models/appointment.dart';

/// Service managing clinical consultations, diagnostic recordings, and prescription updates.
class ConsultationService {
  final ApiClient _client;

  ConsultationService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Completes a consultation by submitting clinical diagnosis, prescription,
  /// and any required bed, blood, or scan allocations.
  ///
  /// The backend automatically deducts beds/blood stock, records financial ledger
  /// entries, and raises purchase orders if safety thresholds are breached.
  Future<Appointment> completeConsultation({
    required String appointmentId,
    required String problem,
    required String prescription,
    bool admitPatientBed = false,
    String? bloodType,
    int bloodUnits = 0,
    String? scanRequired,
  }) async {
    final Map<String, dynamic> resources = {
      'bed': admitPatientBed,
      'blood': {
        'type': bloodType ?? '',
        'units': bloodUnits,
      },
      'scan': scanRequired,
    };

    final body = {
      'status': AppConstants.statusCompleted,
      'problem': problem.trim(),
      'prescription': prescription.trim(),
      'resources': resources,
    };

    try {
      final response = await _client.put(
        ApiConstants.appointmentById(appointmentId),
        body: body,
      );

      final apptJson = response['appointment'] as Map<String, dynamic>?;
      if (apptJson == null) {
        throw const ApiException(message: 'Failed to record consultation result.');
      }

      return Appointment.fromJson(apptJson);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Consultation completion failed: ${e.toString()}');
    }
  }

  /// Edits an existing prescription without re-allocating hospital resources.
  ///
  /// Sets `isUpdated = true` and records the ISO timestamp for notification tracking.
  Future<Appointment> updatePrescription({
    required String appointmentId,
    required String problem,
    required String prescription,
  }) async {
    final body = {
      'problem': problem.trim(),
      'prescription': prescription.trim(),
      'isUpdated': true,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      final response = await _client.put(
        ApiConstants.appointmentById(appointmentId),
        body: body,
      );

      final apptJson = response['appointment'] as Map<String, dynamic>?;
      if (apptJson == null) {
        throw const ApiException(message: 'Failed to update prescription.');
      }

      return Appointment.fromJson(apptJson);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Prescription update failed: ${e.toString()}');
    }
  }
}
