import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_tex_js_platform_interface/src/method_channel_tex_renderer.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class TexRendererPlatform extends PlatformInterface {
  /// Constructs a TexRendererPlatform.
  TexRendererPlatform() : super(token: _token);

  static final Object _token = Object();

  static TexRendererPlatform _instance = MethodChannelTexRenderer();

  /// The default instance of [TexRendererPlatform] to use.
  ///
  /// Defaults to [MethodChannelTexRenderer].
  static TexRendererPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [TexRendererPlatform] when they register themselves.
  static set instance(TexRendererPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Render the specified [text] to a PNG binary suitable for display with
  /// [Image.memory].
  ///
  /// [text] should be escaped so as to be embeddable in a JavaScript string
  /// literal.
  ///
  /// [color] should be a CSS color e.g. in the form of `rbga(255,255,255,1.0)`.
  Future<Uint8List> render(
    String text, {
    required String requestId,
    required bool displayMode,
    required String color,
    required double fontSize,
    required double maxWidth,
  }) =>
      throw UnimplementedError('render() has not been implemented.');

  /// Cancel the in-flight [render] request identified by [requestId].
  Future<void> cancel(String requestId) =>
      throw UnimplementedError('cancel() has not been implemented.');
}
