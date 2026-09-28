import 'package:flutter/material.dart';

import '../core/exceptions/app_exceptions.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Provider managing authentication state, session lifecycle, and current user info.
class AuthProvider with ChangeNotifier {
  final AuthService _authService;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isPatient => _currentUser?.role == 'patient';
  bool get isDoctor => _currentUser?.role == 'doctor';
  bool get isAdmin => _currentUser?.role == 'admin';

  /// Restores session on app startup.
  Future<bool> restoreSession() async {
    _setLoading(true);
    try {
      final user = _authService.getCurrentUser();
      _currentUser = user;
      _errorMessage = null;
      return user != null;
    } finally {
      _setLoading(false);
    }
  }

  /// Logs in with email and password.
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _currentUser = await _authService.login(email: email, password: password);
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during login.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Quick guest / recruiter login for evaluation.
  Future<bool> guestLogin(String role) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _currentUser = await _authService.guestLogin(role);
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Guest login failed.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Registers a new patient.
  Future<bool> registerPatient({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _currentUser = await _authService.registerPatient(
        name: name,
        email: email,
        password: password,
      );
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Registration failed.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logs out and resets authentication state.
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
