import 'dart:html';
import 'dart:js' as js;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

class TexImage extends StatefulWidget {
  const TexImage(
    this.math, {
    this.displayMode = true,
    this.color,
    this.fontSize,
    this.placeholder,
    this.error,
    this.alignment = Alignment.center,
    this.keepAlive = true,
    Key? key,
  }) : super(key: key);

  /// LaTeX markup to render. See here for supported syntax:
  /// https://katex.org/docs/supported.html
  final String math;

  /// [displayMode] is KaTeX's displayMode: math will be in display mode (\int,
  /// \sum, etc. will be large). This is appropriate for "block" display, as
  /// opposed to "inline" display. See also: https://katex.org/docs/options.html
  final bool displayMode;

  /// [color] is the color of the rendered text.
  final Color? color;

  /// [fontSize] is the size in pixels of the rendered text. You can use
  /// e.g. [TextStyle.fontSize] as-is.
  final double? fontSize;

  /// A widget to display while rendering. By default it is simply [math] as
  /// text.
  final Widget? placeholder;

  /// A builder supplying a widget to display in case of error, for instance
  /// when [math] contains invalid or unsupported LaTeX syntax. By default it is
  /// [Icons.error] and the error message.
  final ErrorWidgetBuilder? error;

  /// Controls the alignment of the image within its bounding box; see
  /// [Image.alignment].
  final AlignmentGeometry alignment;

  /// Whether or not the rendered image should be retained even when e.g. the
  /// widget has been scrolled out of view in a [ListView].
  final bool keepAlive;

  @override
  _TexImageState createState() => _TexImageState();
}

class _TexImageState extends State<TexImage> {
  String get _viewTypeId => 'flutter_tex_js:${widget.math}';

  @override
  void initState() {
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _viewTypeId,
      // ignore:avoid_types_on_closure_parameters
      (int _viewId) {
        final div = SpanElement()..id = _viewTypeId;
        js.context['katex'].callMethod('render', [
          widget.math,
          div,
          {'displayMode': widget.displayMode},
        ]);
        return div;
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 200, height: 200, child: HtmlElementView(viewType: _viewTypeId));
  }
}
