import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tex_js_example/comparison/catex.dart';
import 'package:flutter_tex_js_example/comparison/flutter_tex.dart';
import 'package:flutter_tex_js_example/comparison/flutter_tex_js.dart';

const _tabs = [
  Tab(child: Text('flutter_tex_js')),
  Tab(child: Text('flutter_tex')),
  Tab(child: Text('catex')),
];

class ComparisonPage extends StatelessWidget {
  static void pushRoute(BuildContext context) => Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => const ComparisonPage(),
        fullscreenDialog: true,
      ));

  const ComparisonPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Comparison'),
          bottom: const TabBar(
            tabs: _tabs,
          ),
        ),
        body: const TabBarView(
          children: [
            FlutterTexJsExample(),
            FlutterTexExample(),
            CatexExample(),
          ],
        ),
      ),
    );
  }
}
