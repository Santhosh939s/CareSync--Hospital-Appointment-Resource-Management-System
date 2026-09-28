import '../core/constants/api_constants.dart';
import '../core/exceptions/app_exceptions.dart';
import '../core/network/api_client.dart';
import '../models/doctor.dart';

/// Service for querying doctors and medical departments.
class DoctorService {
  final ApiClient _client;

  DoctorService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Fetches all registered doctors from the backend.
  Future<List<Doctor>> getDoctors() async {
    try {
      final response = await _client.get(ApiConstants.data);
      final results = response['d']?['results'] as Map<String, dynamic>?;
      final usersRaw = results?['hms_users'] as List<dynamic>? ?? [];

      final doctors = usersRaw
          .where((u) => u is Map<String, dynamic> && u['role'] == 'doctor')
          .map((u) => Doctor.fromJson(u as Map<String, dynamic>))
          .toList();

      return doctors;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load doctors: ${e.toString()}');
    }
  }

  /// Groups doctors by medical specialty / department.
  List<String> extractSpecialties(List<Doctor> doctors) {
    final specialties = doctors.map((d) => d.specialty).toSet().toList();
    specialties.sort();
    return specialties;
  }
}
