import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'app.dart';
import 'providers/api_provider.dart';
import 'providers/settings_provider.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  final prefs = await SharedPreferences.getInstance();
  await NotificationService.init();

  // Shared ApiService instance — reuses the same Dio connection pool for
  // the warmup ping and all subsequent provider requests.
  final apiService = ApiService(prefs);
  // Fire-and-forget: opens the TCP connection early so the first real request
  // skips the handshake. /healthz is a lightweight probe with no response body.
  apiService.warmup().ignore();

  runApp(
    ProviderScope(
      overrides: [
        apiServiceProvider.overrideWithValue(apiService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ApexLegendsApp(),
    ),
  );
}
