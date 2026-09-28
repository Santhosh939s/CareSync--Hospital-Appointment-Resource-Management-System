import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user.dart';
import '../constants/app_constants.dart';

/// Thin wrapper around [SharedPreferences] for CareSync local persistence.
///
/// Stores non-sensitive session metadata, theme preference and notification state.
/// Never stores raw passwords or MongoDB credentials.
class LocalStorage {
  static User? _cachedUser;
  static final Set<String> _viewedPrescriptions = {};
  SharedPreferences? _prefs;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyUser);
    if (raw != null) {
      try {
        _cachedUser = User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    final rawUpdates = prefs.getString(AppConstants.keySeenUpdates);
    if (rawUpdates != null) {
      try {
        final list = List<String>.from(jsonDecode(rawUpdates) as List);
        _viewedPrescriptions.addAll(list);
      } catch (_) {}
    }
  }

  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── Auth Session ──────────────────────────────────────────────────────

  /// Saves the user (without password) for session restoration.
  Future<void> saveUser(dynamic user) async {
    final prefs = await _instance;
    if (user is User) {
      _cachedUser = user;
      await prefs.setString(AppConstants.keyUser, jsonEncode(user.toJson()));
    } else if (user is Map<String, dynamic>) {
      _cachedUser = User.fromJson(user);
      await prefs.setString(AppConstants.keyUser, jsonEncode(user));
    }
  }

  /// Returns the cached user or null if no session exists.
  User? getUser() => _cachedUser;

  /// Clears the stored session.
  Future<void> clearUser() async {
    _cachedUser = null;
    final prefs = await _instance;
    await prefs.remove(AppConstants.keyUser);
  }

  /// Alias for clearing authentication session.
  Future<void> clearSession() => clearUser();

  /// Returns cached list of viewed prescription IDs.
  List<String> getViewedPrescriptionIds() => _viewedPrescriptions.toList();

  /// Marks a prescription update as viewed.
  Future<void> markPrescriptionViewed(String key) async {
    _viewedPrescriptions.add(key);
    await markUpdateSeen(key);
  }

  // ── Theme ─────────────────────────────────────────────────────────────

  /// Persists the theme mode: 'light' or 'dark'.
  Future<void> saveThemeMode(String mode) async {
    final prefs = await _instance;
    await prefs.setString(AppConstants.keyThemeMode, mode);
  }

  /// Returns the stored theme mode, defaulting to 'light'.
  Future<String> getThemeMode() async {
    final prefs = await _instance;
    return prefs.getString(AppConstants.keyThemeMode) ?? 'light';
  }

  // ── Seen Prescription Updates ─────────────────────────────────────────

  /// Returns the list of seen update keys (appointmentId + updatedAt).
  Future<List<String>> getSeenUpdates() async {
    final prefs = await _instance;
    final raw = prefs.getString(AppConstants.keySeenUpdates);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw) as List);
  }

  /// Marks a prescription update as seen.
  Future<void> markUpdateSeen(String key) async {
    final seen = await getSeenUpdates();
    if (!seen.contains(key)) {
      seen.add(key);
      final prefs = await _instance;
      await prefs.setString(AppConstants.keySeenUpdates, jsonEncode(seen));
    }
  }

  /// Clears all stored data (used on logout).
  Future<void> clearAll() async {
    final prefs = await _instance;
    await prefs.clear();
  }
}
