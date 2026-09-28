import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/storage/local_storage.dart';

/// CareSync Mobile entry point.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent SharedPreferences cache
  await LocalStorage.init();

  runApp(const CareSyncApp());
}
