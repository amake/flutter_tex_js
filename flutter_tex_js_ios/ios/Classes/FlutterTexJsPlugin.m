#import "FlutterTexJsPlugin.h"
#if __has_include(<flutter_tex_js_ios/flutter_tex_js_ios-Swift.h>)
#import <flutter_tex_js_ios/flutter_tex_js_ios-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_tex_js_ios-Swift.h"
#endif

@implementation FlutterTexJsPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterTexJsPlugin registerWithRegistrar:registrar];
}
@end
