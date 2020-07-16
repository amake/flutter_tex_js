import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tex_js/flutter_tex_js.dart';

// 1x1 transparent pixel generated with ImageMagick:
//   convert -size 1x1 xc:transparent pixel.png
// and then compressed with ImageOptim
const pixel = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABAQMAAAAl21bKAAAAA1BMVEUAAACnej3a'
    'AAAAAXRSTlMAQObYZgAAAApJREFUeAFjZAAAAAQAAhq+CAMAAAAASUVORK5CYII=';

void main() {
  const channel = MethodChannel('flutter_tex_js');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((methodCall) async {
      switch (methodCall.method) {
        case 'render':
          return base64.decode(pixel);
        case 'cancel':
          return null;
        default:
          assert(false,
              'Unknown channel method called in test: ${methodCall.method}');
      }
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('render', () async {
    expect(
        await FlutterTexJs.render(
          '',
          requestId: '',
          color: Colors.black,
          maxWidth: double.infinity,
          fontSize: 12,
          displayMode: true,
        ),
        base64.decode(pixel));
  });

  testWidgets('create widget', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: TexImage('x^2'),
      ),
    );
  });
}
