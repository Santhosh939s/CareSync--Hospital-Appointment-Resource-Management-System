import '../core/constants/api_constants.dart';
import '../core/exceptions/app_exceptions.dart';
import '../core/network/api_client.dart';
import '../core/storage/local_storage.dart';
import '../models/user.dart';

/// Authentication service handling login, registration, guest access, and session management.
class AuthService {
  final ApiClient _client;
  final LocalStorage _storage;

  AuthService({
    ApiClient? client,
    LocalStorage? storage,
  })  : _client = client ?? ApiClient(),
        _storage = storage ?? LocalStorage();

  /// Logs in a user with email and password via POST /api/login.
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.login,
        body: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      final userJson = response['user'] as Map<String, dynamic>?;
      if (userJson == null) {
        throw const ApiException(message: 'Malformed user profile received from server.');
      }

      final user = User.fromJson(userJson);
      await _storage.saveUser(user);
      return user;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to complete login: ${e.toString()}');
    }
  }

  /// Guest / Recruiter login for quick role evaluation.
  Future<User> guestLogin(String role) async {
    try {
      final response = await _client.post(
        ApiConstants.guestLogin,
        body: {'role': role},
      );

      final userJson = response['user'] as Map<String, dynamic>?;
      if (userJson == null) {
        throw const ApiException(message: 'Guest account not found.');
      }

      final user = User.fromJson(userJson);
      await _storage.saveUser(user);
      return user;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Guest login failed: ${e.toString()}');
    }
  }

  /// Registers a new patient via POST /api/users.
  Future<User> registerPatient({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final id = 'usr${DateTime.now().millisecondsSinceEpoch}';
      final response = await _client.post(
        ApiConstants.users,
        body: {
          'id': id,
          'role': 'patient',
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      final userJson = response['user'] as Map<String, dynamic>?;
      if (userJson == null) {
        throw const ApiException(message: 'Failed to create patient account.');
      }

      final user = User.fromJson(userJson);
      await _storage.saveUser(user);
      return user;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Registration failed: ${e.toString()}');
    }
  }

  /// Restores session from local storage.
  User? getCurrentUser() {
    return _storage.getUser();
  }

  /// Logs out the user and cleans up persistent session.
  Future<void> logout() async {
    await _storage.clearSession();
  }
}
