import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:media_kit/media_kit.dart';
import 'package:naughty_list_notifier/src/app.dart';
import 'package:naughty_list_notifier/src/shared/firebase_cloud_messaging/application/firebase_cloud_messaging_service.dart';
import 'package:naughty_list_notifier/src/utils/di/setup_di.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Firebase.initializeApp();
  setupDi();

  // Initialize Firebase Cloud Messaging
  final fcmService = GetIt.instance<FirebaseCloudMessagingService>();
  await fcmService.initialize();

  runApp(const App());
}
