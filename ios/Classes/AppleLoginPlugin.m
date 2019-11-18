#import "AppleLoginPlugin.h"
#import <firebase_apple_sign_in/firebase_apple_sign_in-Swift.h>

@implementation AppleLoginPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAppleLoginPlugin registerWithRegistrar:registrar];
}
@end
