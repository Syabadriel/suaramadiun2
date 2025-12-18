//native_service.dart

import 'package:flutter/services.dart';

class NativeService {
  static const _channel = MethodChannel('radio_service');

  static Future<void> start() async {
    await _channel.invokeMethod('startService');
  }

  static Future<void> stop() async {
    await _channel.invokeMethod('stopService');
  }
}
