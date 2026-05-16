import 'dart:io';

import 'package:background_fetch/background_fetch.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../env/env.dart';
import '../models/map_rotation.dart';
import 'notification_service.dart';

// Runs when the app is fully terminated (headless). Must be top-level.
@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessEvent event) async {
  if (event.timeout) {
    BackgroundFetch.finish(event.taskId);
    return;
  }
  await _fetchAndSchedule();
  BackgroundFetch.finish(event.taskId);
}

Future<void> _fetchAndSchedule() async {
  try {
    tz.initializeTimeZones();
    await NotificationService.init();

    final prefs = await SharedPreferences.getInstance();
    final minutesBefore = prefs.getInt('map_notify_minutes') ?? 0;
    if (minutesBefore <= 0) return;

    final notifyPubs = prefs.getBool('notify_pubs_map_rotation') ?? false;
    final notifyRanked = prefs.getBool('notify_ranked_map_rotation') ?? false;
    final notifyMixtape = prefs.getBool('notify_mixtape_map_rotation') ?? false;
    if (!notifyPubs && !notifyRanked && !notifyMixtape) return;

    final dio = Dio(BaseOptions(
      baseUrl: Env.proxyUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'x-client-token': Env.clientToken},
    ));

    final response = await dio.get(
      '/maprotation',
      queryParameters: {'version': '2'},
    );

    final rotation = MapRotation.fromJson(
      response.data as Map<String, dynamic>,
    );

    await NotificationService.scheduleAll(
      rotation,
      minutesBefore,
      notifyPubs: notifyPubs,
      notifyRanked: notifyRanked,
      notifyMixtape: notifyMixtape,
    );
  } catch (_) {
    // Silently swallow — background task must not crash
  }
}

class BackgroundService {
  static bool get _supported => Platform.isAndroid || Platform.isIOS;

  static Future<void> init() async {
    if (!_supported) return;

    await BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 30,
        stopOnTerminate: false,
        enableHeadless: true,
        startOnBoot: true,
      ),
      (String taskId) async {
        await _fetchAndSchedule();
        BackgroundFetch.finish(taskId);
      },
      (String taskId) {
        BackgroundFetch.finish(taskId);
      },
    );

    BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
  }

  /// Returns true if background fetch is available.
  /// On Android this is always true. On iOS it depends on the system setting.
  static Future<bool> isAvailable() async {
    if (!_supported) return false;
    final status = await BackgroundFetch.status;
    return status == BackgroundFetch.STATUS_AVAILABLE;
  }
}
