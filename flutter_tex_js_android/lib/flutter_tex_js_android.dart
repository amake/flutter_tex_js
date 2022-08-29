import 'package:flutter/services.dart';
import 'package:flutter_tex_js_platform_interface/flutter_tex_js_platform_interface.dart';

class TexRendererAndroid extends TexRendererPlatform {
  /// The method channel used to interact with the native platform.
  static const MethodChannel _channel = MethodChannel('flutter_tex_js');

  /// Registers this class as the default instance of [TexRendererPlatform]
  static void registerWith() =>
      TexRendererPlatform.instance = TexRendererAndroid();

  /// Render the specified [text] to a PNG binary suitable for display with
  /// [Image.memory].
  @override
  Future<Uint8List> render(
    String text, {
    required String requestId,
    required bool displayMode,
    required String color,
    required double fontSize,
    required double maxWidth,
  }) async {
    return await _channel.invokeMethod<Uint8List>('render', {
      'requestId': requestId,
      'text': text,
      'displayMode': displayMode,
      'color': color,
      'fontSize': fontSize,
      'maxWidth': maxWidth,
    }) as Uint8List;
  }

  /// Cancel the in-flight [render] request identified by [requestId].
  @override
  Future<void> cancel(String requestId) {
    return _channel.invokeMethod<void>('cancel', {
      'requestId': requestId,
    });
  }
}
