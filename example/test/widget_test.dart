import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tex_js_example/main.dart';

void main() {
  testWidgets('launch app', (tester) async {
    await tester.pumpWidget(const MyApp());
  });
}
