export 'package:flutter_tex_js/src/stub.dart'
    if (dart.library.html) 'package:flutter_tex_js/src/web.dart'
    if (dart.library.io) 'package:flutter_tex_js/src/method_channel.dart';

/// A set listing the supported TeX environments; see
/// https://katex.org/docs/supported.html#environments
const Set<String> flutterTexJsSupportedEnvironments = {
  'matrix',
  'pmatrix',
  'vmatrix',
  'Bmatrix',
  'aligned',
  'gathered',
  'smallmatrix',
  'array',
  'bmatrix',
  'Vmatrix',
  'alignedat',
  'cases',
  'rcases',
  'darray',
  'dcases',
  'drcases',
};
