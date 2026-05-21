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
  s.source_files = 'flutter_tex_js_ios/Sources/flutter_tex_js_ios/**/*.swift'
  s.resource_bundles = { 'flutter_tex_js_katex' => [
    'flutter_tex_js_ios/Sources/flutter_tex_js_ios/katex/*'
  ] }
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
