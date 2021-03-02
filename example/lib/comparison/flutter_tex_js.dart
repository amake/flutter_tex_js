import 'package:flutter/material.dart';
import 'package:flutter_tex_js/flutter_tex_js.dart';

class FlutterTexJsExample extends StatelessWidget {
  const FlutterTexJsExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, i) => Center(
        child: TexImage(
          '\\sqrt[$i]{a^2 + b^2} = ' * 5,
          // No line wrap in displayMode
          displayMode: false,
          key: ValueKey(i),
        ),
      ),
    );
  }
}
