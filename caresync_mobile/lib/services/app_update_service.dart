import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';

/// Metadata representing an available application update.
class AppUpdateInfo {
  final bool hasUpdate;
  final String latestVersion;
  final String currentVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.latestVersion,
    required this.currentVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    this.forceUpdate = false,
  });
}

/// Service checking for over-the-air (OTA) updates on app startup.
class AppUpdateService {
  final http.Client _client;

  AppUpdateService({http.Client? client}) : _client = client ?? http.Client();

  /// Queries the backend `/api/app-version` and compares against the local client version.
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.appVersion}');
      final response = await _client.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final latest = (data['latestVersion'] as String?) ?? '1.0.0';
        final downloadUrl = (data['downloadUrl'] as String?) ??
            'https://care-sync-hospital-appointment-reso.vercel.app/download-apk';
        final notes = (data['releaseNotes'] as String?) ?? 'Performance enhancements and bug fixes.';
        final force = (data['forceUpdate'] as bool?) ?? false;

        final hasUpdate = _isNewerVersion(latest, AppConstants.appVersion);

        return AppUpdateInfo(
          hasUpdate: hasUpdate,
          latestVersion: latest,
          currentVersion: AppConstants.appVersion,
          downloadUrl: downloadUrl,
          releaseNotes: notes,
          forceUpdate: force,
        );
      }
    } catch (_) {
      // Gracefully ignore offline or timeout issues during update check
    }
    return null;
  }

  /// Compares two semver strings (e.g., '1.0.1' > '1.0.0').
  bool _isNewerVersion(String latest, String current) {
    try {
      final lParts = latest.split('.').map(int.parse).toList();
      final cParts = current.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final l = i < lParts.length ? lParts[i] : 0;
        final c = i < cParts.length ? cParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (_) {}
    return false;
  }

  /// Displays an in-app update prompt dialog directly on the user's screen.
  static void showUpdatePrompt(BuildContext context, AppUpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.system_update_rounded, color: Color(0xFF14B8A6)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Update Available',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A newer version of CareSync (v${info.latestVersion}) is available (Current: v${info.currentVersion}).',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                info.releaseNotes,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          if (!info.forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Later'),
            ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF14B8A6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Clipboard.setData(ClipboardData(text: info.downloadUrl));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download URL copied! Downloading latest CareSync.apk...'),
                  backgroundColor: Color(0xFF14B8A6),
                ),
              );
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Update Now'),
          ),
        ],
      ),
    );
  }
}
