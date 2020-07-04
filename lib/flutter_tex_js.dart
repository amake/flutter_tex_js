import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlutterTexJs {
  static const MethodChannel _channel = MethodChannel('flutter_tex_js');

  static Future<Uint8List> render(
    String text, {
    @required bool displayMode,
    @required Color color,
  }) async {
    assert(displayMode != null);
    assert(color != null);
    return _channel.invokeMethod<Uint8List>('render', {
      'text': text,
      'displayMode': displayMode,
      'color': _colorToCss(color),
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
    Key key,
  })  : assert(math != null),
        assert(displayMode != null),
        super(key: key);

  final String math;
  final bool displayMode;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: FlutterTexJs.render(
        math,
        displayMode: displayMode,
        color: color ?? DefaultTextStyle.of(context).style.color,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data,
            scale: MediaQuery.of(context).devicePixelRatio,
          );
        } else if (snapshot.hasError) {
          return Column(
            children: [
              const Icon(Icons.error),
              Text(snapshot.error.toString()),
            ],
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
