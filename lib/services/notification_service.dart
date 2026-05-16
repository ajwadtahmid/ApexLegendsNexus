import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/map_rotation.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _androidChannel = AndroidNotificationDetails(
    'map_rotation_v2',
    'Map Rotation',
    channelDescription: 'Alerts before the map rotates',
    importance: Importance.high,
    priority: Priority.high,
  );
  static const _details = NotificationDetails(
    android: _androidChannel,
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> init() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open',
    );
    await _plugin.initialize(
      InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        linux: linuxSettings,
      ),
    );
    _initialized = true;
  }

  static Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  static bool get _supportsScheduled => Platform.isAndroid || Platform.isIOS;

  static const _notifIdRanked = 11;
  static const _notifIdPubs = 12;
  static const _notifIdLtm = 13;

  // Schedule up to 3 notifications (one per mode) and cancel any old ones.
  static Future<void> scheduleAll(
    MapRotation rotation,
    int minutesBefore, {
    bool notifyRanked = false,
    bool notifyPubs = false,
    bool notifyMixtape = false,
  }) async {
    if (!_supportsScheduled) return;
    await _plugin.cancelAll();
    if (minutesBefore <= 0) return;

    if (notifyRanked) {
      await _scheduleMode(
        _notifIdRanked,
        'Ranked',
        rotation.rankedNext,
        rotation.rankedCurrent.remainingSecs,
        minutesBefore,
      );
    }
    if (notifyPubs) {
      await _scheduleMode(
        _notifIdPubs,
        'Pubs',
        rotation.battleRoyaleNext,
        rotation.battleRoyaleCurrent.remainingSecs,
        minutesBefore,
      );
    }
    if (notifyMixtape && rotation.ltmNext != null) {
      await _scheduleMode(
        _notifIdLtm,
        'Mixtape',
        rotation.ltmNext!,
        rotation.ltmCurrent!.remainingSecs,
        minutesBefore,
      );
    }
  }

  static Future<void> _scheduleMode(
    int id,
    String modeLabel,
    MapMode nextMap,
    int currentRemainingSecs,
    int minutesBefore,
  ) async {
    final notifyAt = tz.TZDateTime.now(tz.UTC)
        .add(Duration(seconds: currentRemainingSecs))
        .subtract(Duration(minutes: minutesBefore));

    if (!notifyAt.isAfter(tz.TZDateTime.now(tz.UTC))) return;

    await _plugin.zonedSchedule(
      id,
      '$modeLabel · Map Rotation',
      '${nextMap.map} starts in $minutesBefore min',
      notifyAt,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelAll() async => _plugin.cancelAll();
}
