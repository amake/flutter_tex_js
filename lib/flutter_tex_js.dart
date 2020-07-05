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

class TexImage extends StatefulWidget {
  const TexImage(
    this.math, {
    this.displayMode = true,
    this.color,
    this.placeholder,
    this.keepAlive = true,
    Key key,
  })  : assert(math != null),
        assert(displayMode != null),
        super(key: key);

  final String math;
  final bool displayMode;
  final Color color;
  final Widget placeholder;
  final bool keepAlive;

  @override
  _TexImageState createState() => _TexImageState();
}

class _TexImageState extends State<TexImage>
    with AutomaticKeepAliveClientMixin<TexImage> {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
      builder: (context, constraints) => FutureBuilder<Uint8List>(
        future: FlutterTexJs.render(
          widget.math,
          requestId: identityHashCode(this).toString(),
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
    return Column(
      children: [
        const Icon(Icons.error),
        Text(error.toString()),
      ],
    );
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;
}
