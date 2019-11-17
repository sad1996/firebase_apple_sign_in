#import "AppleLoginPlugin.h"
#import <apple_login/apple_login-Swift.h>

@implementation AppleLoginPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAppleLoginPlugin registerWithRegistrar:registrar];
}
@end
