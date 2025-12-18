// main.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:lppl_93fm_suara_madiun/Home2.dart';
import 'package:lppl_93fm_suara_madiun/newUI/homepage/menubaru/radio_handler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lppl_93fm_suara_madiun/newUI/constants/audio_handler.dart';


late final AudioHandler audioHandler;

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global = MyHttpOverrides();

  audioHandler = await AudioService.init(
    builder: () => RadioAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.kominfo.lppl_93fm',
      androidNotificationChannelName: 'Radio Suara Madiun',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidShowNotificationBadge: true,
    ),
  );

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage2(),
    );
  }
}
