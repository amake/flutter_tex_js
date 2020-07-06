import 'package:flutter/material.dart';
import 'package:flutter_tex_js/flutter_tex_js.dart';
import 'package:flutter_tex_js_example/flutter_tex.dart';

void main() => runApp(const MyApp());

const _tabs = [
  Tab(child: Text('Edit')),
  Tab(child: Text('∞')),
  Tab(child: Text('Flutter TeX')),
];

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: DefaultTabController(
        length: _tabs.length,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Flutter TeX JS Example'),
            bottom: const TabBar(
              tabs: _tabs,
            ),
          ),
          body: const TabBarView(
            children: [
              EditableExample(),
              InfiniteExample(),
              FlutterTexExample(),
            ],
          ),
        ),
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
        child: ListView(
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
                return Center(
                  child: ColoredBox(
                    color: Colors.amber,
                    child: TexImage(
                      value.text,
                      displayMode: _displayMode,
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
                ),
              ),
            ),
            const Center(
              child: Text(
                'fin',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class InfiniteExample extends StatelessWidget {
  const InfiniteExample({Key key}) : super(key: key);

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
