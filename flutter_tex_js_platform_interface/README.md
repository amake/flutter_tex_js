# flutter\_tex\_js\_platform\_interface

A common platform interface for the [`flutter_tex_js`][1] plugin.

This interface allows platform-specific implementations of the `flutter_tex_js`
plugin, as well as the plugin itself, to ensure they are supporting the same
interface.

# Usage

To implement a new platform-specific implementation of `flutter_tex_js`, extend
[`TexRendererPlatform`][2] with an implementation that performs the
platform-specific behavior, and when you register your plugin, set the default
`TexRendererPlatform` by calling `TexRendererPlatform.instance =
MyPlatformTexRenderer()`.

[1]: ../
[2]: lib/flutter_tex_js_platform_interface.dart
