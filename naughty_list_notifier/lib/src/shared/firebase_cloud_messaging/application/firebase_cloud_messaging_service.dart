// notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:naughty_list_notifier/src/shared/firebase_cloud_messaging/data/firebase_cloud_messaging_repository.dart';
import 'package:naughty_list_notifier/src/utils/routing/routing.dart';

class FirebaseCloudMessagingService {
  final FirebaseCloudMessagingRepository _fcmRepository;
  static const String _allDevicesTopic = 'all_devices';

  FirebaseCloudMessagingService({
    required FirebaseCloudMessagingRepository fcmRepository,
  }) : _fcmRepository = fcmRepository;

  Future<void> initialize() async {
    // Request permission
    final hasPermission = await _fcmRepository.requestPermission();

    if (!hasPermission) {
      debugPrint('Notification permission denied');
      return;
    }

    // Subscribe to the all devices topic
    await _fcmRepository.subscribeToTopic(_allDevicesTopic);
    debugPrint('Subscribed to notifications');

    // Listen for foreground messages
    _fcmRepository.onMessage.listen((message) {
      _handleForegroundMessage(message);
    });

    // Listen for when user taps notification (app in background)
    _fcmRepository.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message);
    });

    // Check if app was opened from terminated state
    final initialMessage = await _fcmRepository.getInitialMessage();
    if (initialMessage != null) {
      // Defer navigation until after the app is fully initialized and router is ready
      Future.delayed(const Duration(milliseconds: 100), () {
        _handleNotificationTap(initialMessage);
      });
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      debugPrint('Foreground notification: ${notification.title}');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'];
    final downloadURL = message.data['downloadURL'] as String?;
    debugPrint('Notification tapped: $type');
    debugPrint('Download URL: $downloadURL');

    if (downloadURL != null) {
      final uri = Uri(
        path: '/video-evidence',
        queryParameters: {'downloadURL': downloadURL},
      );
      appRouter.go(uri.toString());
    }
  }

  Future<void> unsubscribe() async {
    await _fcmRepository.unsubscribeFromTopic(_allDevicesTopic);
  }
}
