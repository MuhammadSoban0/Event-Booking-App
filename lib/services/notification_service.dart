import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    // const AndroidInitializationSettings androidSettings =
    // AndroidInitializationSettings('@mipmap/ic_launcher');
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final plugin = _plugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await plugin?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      final plugin = _plugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await plugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  static void _onNotificationResponse(NotificationResponse response) {
    if (response.payload != null) {
      debugPrint('Notification payload: ${response.payload}');
    }
  }

  static Future<void> showBookingConfirmationNotification({
    required String eventTitle,
    required String eventDate,
    required int ticketQuantity,
    required String bookingId,
  }) async {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'booking_notifications',
        'Booking Notifications',
        channelDescription: 'Notifications for event booking confirmations',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        ticker: 'Booking Confirmed',
        // icon: '@mipmap/ic_launcher',
        icon: '@mipmap/ic_launcher',
        // largeIcon: DrawableResourceAndroidBitmap('app_logo'),
        color: Color(0xFF000000),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        attachments: [],
      ),
    );

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: '🎉 Booking Confirmed!',
      body:
      '$ticketQuantity ticket${ticketQuantity > 1 ? 's' : ''} for "$eventTitle" on $eventDate',
      notificationDetails: details,
      payload: 'booking_confirmed:$bookingId',
    );
  }

  static Future<void> showBookingReminderNotification({
    required String eventTitle,
    required String eventDate,
    required DateTime reminderDateTime,
  }) async {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'reminder_notifications',
        'Event Reminders',
        channelDescription: 'Reminders for upcoming events',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        // icon: '@mipmap/ic_launcher',
        icon: '@mipmap/ic_launcher',
        // largeIcon: DrawableResourceAndroidBitmap('app_logo'),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: '⏰ Event Reminder',
      body: 'Your event "$eventTitle" is tomorrow ($eventDate)!',
      scheduledDate: tz.TZDateTime.from(reminderDateTime, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> showPaymentFailedNotification({
    required String eventTitle,
  }) async {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'payment_notifications',
        'Payment Notifications',
        channelDescription: 'Notifications for payment status',
        // icon: '@mipmap/ic_launcher',
        icon: '@mipmap/ic_launcher',
        // largeIcon: DrawableResourceAndroidBitmap('app_logo'),
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFFFF0000),
        colorized: true,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: '❌ Payment Failed',
      body: 'Payment failed for "$eventTitle". Please try again.',
      notificationDetails: details,
      payload: 'payment_failed:$eventTitle',
    );
  }

  static Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  static Future<void> cancelNotification(int notificationId) async {
    await _plugin.cancel(id: notificationId);
  }

  static Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final plugin = _plugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await plugin?.requestNotificationsPermission();
      return await plugin?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      final plugin = _plugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      await plugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      final result = await plugin?.checkPermissions();
      return result?.isEnabled ?? false;
    }
    return false;
  }
}