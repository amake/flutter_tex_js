import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_tex_js/flutter_tex_js.dart';
import 'package:flutter_tex_js_example/comparison/comparison.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(title: const Text('Flutter TeX JS Example')),
        body: const _EditableExample(),
        floatingActionButton: const _LaunchComparisonButton(),
      ),
    );
  }
}

class _EditableExample extends StatefulWidget {
  const _EditableExample({Key key}) : super(key: key);

  @override
  _EditableExampleState createState() => _EditableExampleState();
}

class _EditableExampleState extends State<_EditableExample> {
  TextEditingController _textEditingController;
  bool _displayMode;
  double _fontSize;
  Alignment _alignment;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(
      text: r'a=\pm\sqrt{b^2+c^2} \int_\infty^\beta d\gamma',
    );
    _displayMode = true;
    _alignment = Alignment.center;
  }

  @override
  void didChangeDependencies() {
    _fontSize = DefaultTextStyle.of(context).style.fontSize;
    super.didChangeDependencies();
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
        child: ListView(
          children: [
            TextField(controller: _textEditingController),
            const SizedBox(height: 8),
            _DisplayModeListTile(
              value: _displayMode,
              onChanged: (value) => setState(() => _displayMode = value),
            ),
            _FontSizeListTile(
              value: _fontSize,
              onChanged: (value) => setState(() => _fontSize = value),
            ),
            _AlignmentListTile(
              onChanged: (value) => setState(() => _alignment = value),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _textEditingController,
              builder: (context, value, child) {
                return AnimatedAlign(
                  duration: const Duration(seconds: 1),
                  alignment: _alignment,
                  child: ColoredBox(
                    color: Colors.amber,
                    child: TexImage(
                      value.text,
                      displayMode: _displayMode,
                      fontSize: _fontSize,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Center(child: Text('Horizontal scroll')),
            const SizedBox(height: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _textEditingController,
              builder: (context, value, child) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: TexImage(
                  [value.text, value.text, value.text].join(' '),
                  displayMode: _displayMode,
                  fontSize: _fontSize,
                ),
              ),
            ),
            const Center(
              child: Text(
                'fin',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LaunchComparisonButton extends StatelessWidget {
  const _LaunchComparisonButton({Key key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: const Icon(Icons.all_inclusive),
      onPressed: () => ComparisonPage.pushRoute(context),
    );
  }
}

class _DisplayModeListTile extends StatelessWidget {
  const _DisplayModeListTile(
      {@required this.value, @required this.onChanged, Key key})
      : super(key: key);

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: const Text('Display mode'),
    );
  }
}

class _FontSizeListTile extends StatelessWidget {
  const _FontSizeListTile({
    @required this.value,
    @required this.onChanged,
    Key key,
  }) : super(key: key);

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Font size'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value px',
              style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()])),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => onChanged(value - 1),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _AlignmentListTile extends StatelessWidget {
  const _AlignmentListTile({@required this.onChanged, Key key})
      : super(key: key);

  final ValueChanged<Alignment> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Animate'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_left),
            onPressed: () => onChanged(Alignment.centerLeft),
          ),
          IconButton(
            icon: const Icon(Icons.adjust),
            onPressed: () => onChanged(Alignment.center),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_right),
            onPressed: () => onChanged(Alignment.centerRight),
          )
        ],
      ),
    );
  }
}
