import 'package:flutter/widgets.dart';

class TexImage extends StatelessWidget {
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

  final String math;
  final bool displayMode;
  final Color? color;
  final double? fontSize;
  final Widget? placeholder;
  final ErrorWidgetBuilder? error;
  final AlignmentGeometry alignment;
  final bool keepAlive;

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}
