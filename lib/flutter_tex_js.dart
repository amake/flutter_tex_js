import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlutterTexJs {
  static const MethodChannel _channel = MethodChannel('flutter_tex_js');

  static Future<Uint8List> render(String text) async =>
      _channel.invokeMethod<Uint8List>('render', {'text': text});
}

class TexImage extends StatelessWidget {
  const TexImage(this.math, {Key key})
      : assert(math != null),
        super(key: key);

  final String math;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: FlutterTexJs.render(math),
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
