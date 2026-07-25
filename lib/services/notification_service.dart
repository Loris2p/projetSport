import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:vibration/vibration.dart';

class NotificationService {
  static NotificationService? _instance;
  factory NotificationService() => _instance ??= NotificationService._internal();
  NotificationService._internal();

  FlutterLocalNotificationsPlugin? _notificationsPlugin;
  bool _isInitialized = false;
  static const int _restTimerNotificationId = 888;
  static const int _restFinishedNotificationId = 889;

  Future<void> init() async {
    if (_isInitialized) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      _notificationsPlugin ??= FlutterLocalNotificationsPlugin();
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _notificationsPlugin!.initialize(settings: initializationSettings);
      _isInitialized = true;
      await requestPermissions();
    } catch (e) {
      debugPrint("NotificationService initialization error: $e");
    }
  }

  Future<void> requestPermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      if (Platform.isAndroid) {
        final androidImplementation =
            _notificationsPlugin?.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImplementation?.requestNotificationsPermission();
      } else if (Platform.isIOS) {
        final iosImplementation =
            _notificationsPlugin?.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        await iosImplementation?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      debugPrint("Error requesting notification permissions: $e");
    }
  }

  /// Show or update ongoing rest timer notification with chronometer / countdown
  Future<void> updateRestTimerNotification({
    required int remainingSeconds,
    required DateTime endTime,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (!_isInitialized) await init();
    if (_notificationsPlugin == null) return;

    try {
      final androidDetails = AndroidNotificationDetails(
        'rest_timer_channel',
        'Temps de repos',
        channelDescription: 'Affiche le chronomètre de repos en cours',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        onlyAlertOnce: true,
        showWhen: true,
        when: endTime.millisecondsSinceEpoch,
        usesChronometer: true,
        chronometerCountDown: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final minutes = remainingSeconds ~/ 60;
      final seconds = remainingSeconds % 60;
      final timeStr = minutes > 0
          ? "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}"
          : "${seconds}s";

      await _notificationsPlugin!.show(
        id: _restTimerNotificationId,
        title: '⏱️ Repos en cours',
        body: 'Temps restant: $timeStr',
        notificationDetails: details,
      );

      // Schedule exact/inexact notification for background completion
      await scheduleRestFinishedNotification(endTime);
    } catch (e) {
      debugPrint("Error showing rest timer notification: $e");
    }
  }

  /// Schedule notification when timer finishes in background
  Future<void> scheduleRestFinishedNotification(DateTime endTime) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (!_isInitialized) await init();
    if (_notificationsPlugin == null) return;

    try {
      await _notificationsPlugin!.cancel(id: _restFinishedNotificationId);

      const androidDetails = AndroidNotificationDetails(
        'rest_finished_channel',
        'Fin du repos',
        channelDescription: 'Notification lorsque le repos est terminé',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final scheduledDate = tz.TZDateTime.from(endTime, tz.local);
      if (scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
        await _notificationsPlugin!.zonedSchedule(
          id: _restFinishedNotificationId,
          title: '💪 Temps de repos terminé !',
          body: 'C\'est l\'heure d\'attaquer la série suivante !',
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint("Error scheduling rest finished notification: $e");
    }
  }

  /// Cancel active rest notifications
  Future<void> cancelRestTimerNotification() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (_notificationsPlugin == null) return;
    try {
      await _notificationsPlugin!.cancel(id: _restTimerNotificationId);
      await _notificationsPlugin!.cancel(id: _restFinishedNotificationId);
    } catch (e) {
      debugPrint("Error cancelling rest notification: $e");
    }
  }

  /// Notify immediately when rest timer finishes (vibration + notification)
  Future<void> notifyRestFinished() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await cancelRestTimerNotification();
    await triggerVibration();

    if (!_isInitialized) await init();
    if (_notificationsPlugin == null) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'rest_finished_channel',
        'Fin du repos',
        channelDescription: 'Notification envoyée lorsque le repos est terminé',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin!.show(
        id: _restFinishedNotificationId,
        title: '💪 Temps de repos terminé !',
        body: 'C\'est l\'heure d\'attaquer la série suivante !',
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint("Error showing rest finished notification: $e");
    }
  }

  /// Trigger vibration feedback
  Future<void> triggerVibration() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        bool? hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          await Vibration.vibrate(pattern: [0, 400, 200, 400, 200, 600]);
          return;
        }
      }
    } catch (e) {
      debugPrint("Vibration plugin failed, falling back to HapticFeedback: $e");
    }

    try {
      await HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 300));
      await HapticFeedback.vibrate();
    } catch (_) {}
  }
}
