import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const LinuxInitializationSettings linuxSettings =
          LinuxInitializationSettings(defaultActionName: 'Open notification');

      final InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
        linux: linuxSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // Create Android Notification Channel with high importance for lock screen wake-up
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidImplementation =
            _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImplementation != null) {
          await androidImplementation.createNotificationChannel(
            const AndroidNotificationChannel(
              'vyapar_ai_alerts_v2',
              'VyaparAI Business & Voice Alerts',
              description: 'Real-time alerts, voice wakeup responses, and payment reminders',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
              showBadge: true,
            ),
          );
        }
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error (graceful fallback): $e');
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'vyapar_ai_alerts_v2',
        'VyaparAI Business & Voice Alerts',
        channelDescription: 'Real-time alerts, voice wakeup responses, and payment reminders',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'VyaparAI Alert',
        fullScreenIntent: true,
        enableLights: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  Future<void> showVoiceWakeupAlert({
    required String query,
    required String responseText,
    String language = 'en',
  }) async {
    String title = '🎙️ VyaparAI Voice Assistant';
    if (language == 'kn') {
      title = '🎙️ ವ್ಯಾಪಾರ್ AI ಧ್ವನಿ ಸಹಾಯಕ';
    } else if (language == 'hi') {
      title = '🎙️ व्यापार AI वॉयस सहायक';
    }

    await showNotification(
      id: 1001,
      title: title,
      body: responseText.isNotEmpty ? responseText : 'Processed query: "$query"',
      payload: 'voice_screen',
    );
  }

  Future<void> showDailyProfitAlert({
    required double profit,
    required double revenue,
    String language = 'en',
  }) async {
    String title = '📊 Daily Business Summary';
    String body = 'Today Profit: ₹${profit.toStringAsFixed(0)} | Revenue: ₹${revenue.toStringAsFixed(0)}';

    if (language == 'kn') {
      title = '📊 ದೈನಂದಿನ ವ್ಯಾಪಾರ ಸಾರಾಂಶ';
      body = 'ಇಂದಿನ ಲಾಭ: ₹${profit.toStringAsFixed(0)} | ಆದಾಯ: ₹${revenue.toStringAsFixed(0)}';
    } else if (language == 'hi') {
      title = '📊 दैनिक व्यापार सारांश';
      body = 'आज का लाभ: ₹${profit.toStringAsFixed(0)} | राजस्व: ₹${revenue.toStringAsFixed(0)}';
    }

    await showNotification(
      id: 1002,
      title: title,
      body: body,
      payload: 'home_screen',
    );
  }

  Future<void> showDueReminderNotification({
    required String customerName,
    required double amount,
    String language = 'en',
  }) async {
    String title = '⏰ Payment Due Alert';
    String body = 'Reminder: $customerName has a pending due of ₹${amount.toStringAsFixed(0)}';

    if (language == 'kn') {
      title = '⏰ ಬಾಕಿ ಪಾವತಿ ಎಚ್ಚರಿಕೆ';
      body = 'ಜ್ಞಾಪನೆ: $customerName ಅವರಿಂದ ₹${amount.toStringAsFixed(0)} ಬಾಕಿ ಬರಬೇಕಿದೆ.';
    } else if (language == 'hi') {
      title = '⏰ भुगतान देय चेतावनी';
      body = 'याद दिलाने के लिए: $customerName से ₹${amount.toStringAsFixed(0)} बकाया है।';
    }

    await showNotification(
      id: 2000 + customerName.hashCode.abs() % 5000,
      title: title,
      body: body,
      payload: 'reminders_screen',
    );
  }

  Future<void> showReminderCreatedAlert({
    required String title,
    double? amount,
    DateTime? dueAt,
    String language = 'en',
  }) async {
    String heading = '🔔 Reminder Scheduled';
    String body = amount != null && amount > 0
        ? 'Reminder set for "$title" (₹${amount.toStringAsFixed(0)})'
        : 'Reminder set for "$title"';

    if (dueAt != null) {
      body += ' due on ${dueAt.day.toString().padLeft(2, '0')}/${dueAt.month.toString().padLeft(2, '0')}/${dueAt.year}';
    }

    if (language == 'kn') {
      heading = '🔔 ಜ್ಞಾಪನೆ ನಿಗದಿಯಾಗಿದೆ';
      body = amount != null && amount > 0
          ? '"$title" ಗಾಗಿ ಜ್ಞಾಪನೆ ನಿಗದಿಯಾಗಿದೆ (₹${amount.toStringAsFixed(0)})'
          : '"$title" ಗಾಗಿ ಜ್ಞಾಪನೆ ನಿಗದಿಯಾಗಿದೆ';
      if (dueAt != null) {
        body += ' ದಿನಾಂಕ: ${dueAt.day.toString().padLeft(2, '0')}/${dueAt.month.toString().padLeft(2, '0')}/${dueAt.year}';
      }
    } else if (language == 'hi') {
      heading = '🔔 रिमाइंडर सेट किया गया';
      body = amount != null && amount > 0
          ? '"$title" के लिए रिमाइंडर सेट किया गया (₹${amount.toStringAsFixed(0)})'
          : '"$title" के लिए रिमाइंडर सेट किया गया';
      if (dueAt != null) {
        body += ' देय तिथि: ${dueAt.day.toString().padLeft(2, '0')}/${dueAt.month.toString().padLeft(2, '0')}/${dueAt.year}';
      }
    }

    await showNotification(
      id: 3000 + title.hashCode.abs() % 5000,
      title: heading,
      body: body,
      payload: 'reminders_screen',
    );
  }

  Future<void> scheduleReminderNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // If due date is already passed or right now, trigger immediately
    if (scheduledDate.isBefore(DateTime.now().add(const Duration(seconds: 5)))) {
      await showNotification(
        id: id,
        title: title,
        body: body,
        payload: payload ?? 'reminders_screen',
      );
      return;
    }

    // Schedule notification via Future.delayed for active session or show persistent alert
    final timeRemaining = scheduledDate.difference(DateTime.now());
    if (timeRemaining.inHours < 24) {
      Future.delayed(timeRemaining, () {
        showNotification(
          id: id,
          title: title,
          body: body,
          payload: payload ?? 'reminders_screen',
        );
      });
    }
  }
}
