import 'package:flutter/widgets.dart';
// import 'package:flutter_tex/flutter_tex.dart';

class FlutterTexExample extends StatelessWidget {
  const FlutterTexExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, i) {
        final math = '\\sqrt[$i]{a^2 + b^2} = ' * 5;
        return Center(
          // child: TeXView(
          //   renderingEngine: const TeXViewRenderingEngine.katex(),
          //   child: TeXViewDocument(_toTexRun(math)),
          //   loadingWidgetBuilder: (context) => Text(math),
          // ),
          child: Text('Not NNBD / ${_toTexRun(math)}'),
        );
      },
    );
  }
}

String _toTexRun(String math) => '\$\$$math\$\$';
