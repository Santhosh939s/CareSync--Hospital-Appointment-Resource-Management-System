import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Thin wrapper around [SharedPreferences] for CareSync local persistence.
///
/// Stores non-sensitive session metadata, theme preference and notification state.
/// Never stores raw passwords or MongoDB credentials.
class LocalStorage {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── Auth Session ──────────────────────────────────────────────────────

  /// Saves the user JSON (without password) for session restoration.
  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await _instance;
    await prefs.setString(AppConstants.keyUser, jsonEncode(user));
  }

  /// Returns the stored user JSON or null if no session exists.
  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await _instance;
    final raw = prefs.getString(AppConstants.keyUser);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Clears the stored session.
  Future<void> clearUser() async {
    final prefs = await _instance;
    await prefs.remove(AppConstants.keyUser);
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
