import 'package:flutter/widgets.dart';
import 'package:libv_markdown/libv_markdown.dart';

class LibvMarkdownExample extends StatelessWidget {
  const LibvMarkdownExample({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, i) {
        final math = '\\sqrt[$i]{a^2 + b^2} = ' * 5;
        return Center(
          child: MarkdownView(
            markdownViewHTML: _toTexRun(math),
            loadingWidget: Text(math),
          ),
        );
      },
    );
  }
}

String _toTexRun(String math) => '\$\$$math\$\$';
