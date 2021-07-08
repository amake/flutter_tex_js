import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_tex_js/flutter_tex_js.dart';
import 'package:flutter_tex_js_example/comparison/comparison.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
  const _EditableExample({Key? key}) : super(key: key);

  @override
  _EditableExampleState createState() => _EditableExampleState();
}

class _EditableExampleState extends State<_EditableExample> {
  late TextEditingController _textEditingController;
  late bool _displayMode;
  late double _fontSize;
  late Alignment _alignment;

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
    _fontSize = DefaultTextStyle.of(context).style.fontSize!;
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
            const SizedBox(height: 24),
            const Center(child: Text('Long text')),
            const SizedBox(height: 8),
            const _LongTextExample(),
            const SizedBox(height: 24),
            const Center(child: Text('Environments')),
            const SizedBox(height: 8),
            const _EnvironmentsExample(),
          ],
        ),
      ),
    );
  }
}

class _LaunchComparisonButton extends StatelessWidget {
  const _LaunchComparisonButton({Key? key}) : super(key: key);
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
      {required this.value, required this.onChanged, Key? key})
      : super(key: key);

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (value) => onChanged(value!),
      title: const Text('Display mode'),
    );
  }
}

class _FontSizeListTile extends StatelessWidget {
  const _FontSizeListTile({
    required this.value,
    required this.onChanged,
    Key? key,
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
  const _AlignmentListTile({required this.onChanged, Key? key})
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

// Text from https://en.wikipedia.org/wiki/Electric_field#Electric_potential
class _LongTextExample extends StatelessWidget {
  const _LongTextExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text.rich(
            TextSpan(
              text:
                  "If a system is static, such that magnetic fields are not time-varying, then by Faraday's law, the electric field is curl-free. In this case, one can define an electric potential, that is, a function ",
              children: [
                WidgetSpan(child: TexImage(r'\Phi', displayMode: false)),
                TextSpan(text: ' such that '),
                WidgetSpan(
                  child: TexImage(
                    r'\mathbf{E} = -\nabla \Phi',
                    displayMode: false,
                  ),
                ),
                TextSpan(
                  text:
                      '. This is analogous to the gravitational potential. The difference between the electric potential at two points in space is called the potential difference (or voltage) between the two points.\n',
                ),
              ],
            ),
          ),
          Text.rich(
            TextSpan(
              text:
                  'In general, however, the electric field cannot be described independently of the magnetic field. Given the magnetic vector potential, ',
              children: [
                TextSpan(
                  text: 'A',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ', defined so that '),
                WidgetSpan(
                  child: TexImage(
                    r'\mathbf{B} = \nabla \times \mathbf{A}',
                    displayMode: false,
                  ),
                ),
                TextSpan(
                  text: ', one can still define an electric potential ',
                ),
                WidgetSpan(child: TexImage(r'\Phi', displayMode: false)),
                TextSpan(text: ' such that:')
              ],
            ),
          ),
          SizedBox(height: 8),
          TexImage(
            r'\mathbf{E} = - \nabla \Phi - \frac { \partial \mathbf{A} } { \partial t }',
          ),
          SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: 'Where ',
              children: [
                WidgetSpan(child: TexImage(r'\Phi', displayMode: false)),
                TextSpan(
                  text: ' is the gradient of the electric potential and ',
                ),
                WidgetSpan(
                  child: TexImage(
                    r'\frac { \partial \mathbf{A} } { \partial t }',
                    displayMode: false,
                  ),
                ),
                TextSpan(
                  text:
                      ' is the partial derivative of A with respect to time.\n',
                ),
              ],
            ),
          ),
          Text(
            "Faraday's law of induction can be recovered by taking the curl of that equation",
          ),
          SizedBox(height: 8),
          TexImage(
            r'\nabla \times \mathbf{E} = -\frac{\partial (\nabla \times \mathbf{A})} {\partial t}= -\frac{\partial \mathbf{B}} {\partial t}',
          ),
          SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: 'which justifies, a posteriori, the previous form for ',
              children: [
                TextSpan(
                  text: 'E',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: '.'),
              ],
            ),
          ),
        ],
      );
}

class _EnvironmentsExample extends StatelessWidget {
  const _EnvironmentsExample({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        TexImage(r'''\begin{equation}
a = b + c
\end{equation}'''),
        SizedBox(height: 8),
        TexImage(r'''\begin{Bmatrix}
   a & b \\
   c & d
   \end{Bmatrix}'''),
        SizedBox(height: 8),
        TexImage(r'''\begin{cases}
   a &\text{if } b \\
   c &\text{if } d
   \end{cases}'''),
        SizedBox(height: 8),
        TexImage(r'''\begin{CD}
   A @>a>> B \\
@VbVV @AAcA \\
   C @= D
   \end{CD}'''),
        SizedBox(height: 8),
        TexImage(r'''\begin{equation}
\begin{split}
   a &=b+c\\
      &=e+f
\end{split}
\end{equation}'''),
        SizedBox(height: 8),
        TexImage(r'''\begin{Vmatrix}
   a & b \\
   c & d
\end{Vmatrix}''')
      ],
    );
  }
}
