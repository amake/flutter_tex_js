import 'dart:async';
import 'dart:typed_data';

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
    return _channel.invokeMethod<Uint8List>('render', {
      'requestId': requestId,
      'text': text,
      'displayMode': displayMode,
      'color': _colorToCss(color),
      'maxWidth': maxWidth,
    });
  }
}

String _colorToCss(Color color) =>
    'rgba(${color.red},${color.green},${color.blue},${color.opacity})';

class TexImage extends StatelessWidget {
  const TexImage(
    this.math, {
    this.displayMode = true,
    this.color,
    this.placeholder,
    Key key,
  })  : assert(math != null),
        assert(displayMode != null),
        super(key: key);

  final String math;
  final bool displayMode;
  final Color color;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => FutureBuilder<Uint8List>(
        future: FlutterTexJs.render(
          math,
          requestId: identityHashCode(this).toString(),
          displayMode: displayMode,
          color: color ?? DefaultTextStyle.of(context).style.color,
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
            return placeholder ?? Text(math);
          }
        },
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    if (error is PlatformException) {
      switch (error.code) {
        case 'UnsupportedOsVersion':
          return Text(math);
        case 'JobCancelled':
          return const SizedBox.shrink();
      }
    }
    return Column(
      children: [
        const Icon(Icons.error),
        Text(error.toString()),
      ],
    );
  }
}
