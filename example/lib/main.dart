import 'package:flutter/material.dart';
import 'package:flutter_tex_js/flutter_tex_js.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter TeX JS Example'),
        ),
        body: const EditableExample(),
      ),
    );
  }
}

class EditableExample extends StatefulWidget {
  const EditableExample({Key key}) : super(key: key);

  @override
  _EditableExampleState createState() => _EditableExampleState();
}

class _EditableExampleState extends State<EditableExample> {
  TextEditingController _textEditingController;
  bool _displayMode;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(
      text: r'a=\pm\sqrt{b^2+c^2} \int_\infty^\beta d\gamma',
    );
    _displayMode = true;
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(controller: _textEditingController),
            const SizedBox(height: 8),
            Builder(
              builder: (context) => Text(
                  'Resolution: ${MediaQuery.of(context).devicePixelRatio}x'),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _displayMode,
              onChanged: (value) => setState(() => _displayMode = value),
              title: const Text('Display mode'),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _textEditingController,
              builder: (context, value, child) {
                return TexImage(
                  value.text,
                  displayMode: _displayMode,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
