import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlutterTexJs {
  static const MethodChannel _channel = MethodChannel('flutter_tex_js');

  static Future<Uint8List> render(
    String text, {
    @required String requestId,
    @required bool displayMode,
    @required Color color,
    @required double maxWidth,
  }) async {
    assert(requestId != null);
    assert(displayMode != null);
    assert(color != null);
    assert(maxWidth != null);
    final escapedText = _escapeForJavaScript(text);
    if (escapedText != text && !kReleaseMode) {
      debugPrint(
          'Escaped text to render; was: "$text"; escaped: "$escapedText"');
    }
    return _channel.invokeMethod<Uint8List>('render', {
      'requestId': requestId,
      'text': escapedText,
      'displayMode': displayMode,
      'color': _colorToCss(color),
      'maxWidth': maxWidth,
    });
  }

  static Future<void> cancel(String requestId) {
    assert(requestId != null);
    return _channel.invokeMethod<void>('cancel', {
      'requestId': requestId,
    });
  }
}

final _unescapedBackslashPattern = RegExp(r'(?<!\\)(?:\\\\)*\\');
final _unescapedAposPattern = RegExp(r"(?<!\\)(?:\\\\)*'");

// Native layer will concatenate with apostrophes to form a JavaScript string
// literal; prepare here for that.
String _escapeForJavaScript(String string) => string
    .replaceAll(_unescapedBackslashPattern, r'\\')
    .replaceAll('\n', r'\n')
    .replaceAll('\r', r'\r')
    .replaceAll(_unescapedAposPattern, r"\'");

String _colorToCss(Color color) =>
    'rgba(${color.red},${color.green},${color.blue},${color.opacity})';

/// A set listing the supported TeX environments; see
/// https://katex.org/docs/supported.html#environments
const Set<String> flutterTexJsSupportedEnvironments = {
  'matrix',
  'pmatrix',
  'vmatrix',
  'Bmatrix',
  'aligned',
  'gathered',
  'smallmatrix',
  'array',
  'bmatrix',
  'Vmatrix',
  'alignedat',
  'cases',
  'rcases',
  'darray',
  'dcases',
  'drcases',
};

typedef ErrorWidgetBuilder = Widget Function(
    BuildContext context, Object error);

class TexImage extends StatefulWidget {
  const TexImage(
    this.math, {
    this.displayMode = true,
    this.color,
    this.placeholder,
    this.error,
    this.keepAlive = true,
    Key key,
  })  : assert(math != null),
        assert(displayMode != null),
        super(key: key);

  final String math;
  final bool displayMode;
  final Color color;
  final Widget placeholder;
  final ErrorWidgetBuilder error;
  final bool keepAlive;

  @override
  _TexImageState createState() => _TexImageState();
}

class _TexImageState extends State<TexImage>
    with AutomaticKeepAliveClientMixin<TexImage> {
  String get id =>
      widget.key?.hashCode?.toString() ?? identityHashCode(this).toString();

  @override
  void dispose() {
    FlutterTexJs.cancel(id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
      builder: (context, constraints) => FutureBuilder<Uint8List>(
        future: FlutterTexJs.render(
          widget.math,
          requestId: id,
          displayMode: widget.displayMode,
          color: widget.color ?? DefaultTextStyle.of(context).style.color,
          maxWidth: constraints.maxWidth,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data,
              scale: MediaQuery.of(context).devicePixelRatio,
            );
          } else if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error);
          } else {
            return widget.placeholder ?? Text(widget.math);
          }
        },
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    if (error is PlatformException) {
      switch (error.code) {
        case 'UnsupportedOsVersion':
          return Text(widget.math);
        case 'JobCancelled':
          return const SizedBox.shrink();
      }
    }
    final errorBuilder = widget.error ?? defaultError;
    return errorBuilder(context, error);
  }

  Widget defaultError(BuildContext context, Object error) => Column(
        children: [
          const Icon(Icons.error),
          Text(error.toString()),
        ],
      );

  @override
  bool get wantKeepAlive => widget.keepAlive;
}
