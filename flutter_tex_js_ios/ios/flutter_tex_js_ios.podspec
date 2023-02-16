#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_tex_js.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_tex_js_ios'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<~DESC
    A new flutter plugin project.
  DESC
  s.homepage         = 'http://example.com'
  s.license          = { file: '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { path: '.' }
  s.source_files = 'Classes/**/*'
  s.resource_bundle = { 'flutter_tex_js_katex' => 'Assets/katex/**/*.{min.js,min.css,woff2}' }
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
end
