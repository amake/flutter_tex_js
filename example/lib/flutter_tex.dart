import 'package:flutter/widgets.dart';
import 'package:flutter_tex/flutter_tex.dart';

class FlutterTexExample extends StatelessWidget {
  const FlutterTexExample({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, i) => Center(
        child: TeXView(
          renderingEngine: const TeXViewRenderingEngine.katex(),
          child: TeXViewDocument(
            _toTexRun('\\sqrt[$i]{a^2 + b^2} = ' * 5),
          ),
        ),
      ),
    );
  }
}

String _toTexRun(String math) => '\$\$$math\$\$';
