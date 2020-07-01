import 'dart:async';

import 'package:flutter/services.dart';

class FlutterTexJs {
  static const MethodChannel _channel =
      const MethodChannel('flutter_tex_js');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
