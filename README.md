# flutter_tex_js

A lightweight TeX plugin for Flutter based on [KaTeX](https://katex.org/), a
popular and full-featured JavaScript TeX rendering library.

# What's different about this plugin?

As of July 2020, there are several other TeX packages/plugins for Flutter, but
most of them are either a) very heavyweight, relying on webview_flutter, or b)
very immature, with poor support for common TeX syntax.

This plugin seeks a middle ground: It uses a single native webview under the
hood, in which it renders TeX markup to PNG. It then sends the PNG bytes back to
the Dart world where the result is displayed as an image.

# Supported platforms

- Android 4.1 (SDK 16) and higher
- iOS 11 and higher*
  - *You can include the plugin on iOS 9+, but it will only render on 11+. On
    iOS 9 and 10, the `TexImage` widget will simply show the supplied text
    as-is.

# Usage

```dart
import 'package:flutter_tex_js/flutter_tex_js.dart';

class MyMathWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return TexImage(r'a=\pm\sqrt{b^2+c^2} \int_\infty^\beta d\gamma');
  }
}
```
