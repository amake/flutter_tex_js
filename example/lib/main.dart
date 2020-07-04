import 'package:flutter/material.dart';
import 'package:flutter_tex_js/flutter_tex_js.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(
      text: r'a=\pm\sqrt{b^2+c^2} \int_\infty^\beta d\gamma',
    );
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter TeX JS Example'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextField(controller: _textEditingController),
                const SizedBox(height: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _textEditingController,
                  builder: (context, value, child) {
                    return TexImage(value.text);
                  },
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) =>
                      Text('${MediaQuery.of(context).devicePixelRatio}x'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
