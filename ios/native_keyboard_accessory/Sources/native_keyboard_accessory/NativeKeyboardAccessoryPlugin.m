#import "include/NativeKeyboardAccessoryPlugin.h"

#import "NKAAccessoryBar.h"
#import "NKAConfiguration.h"
#import "NKATextInputPatch.h"

static NSString *const kNKAChannelName = @"native_keyboard_accessory";

@implementation NativeKeyboardAccessoryPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel =
        [FlutterMethodChannel methodChannelWithName:kNKAChannelName
                                    binaryMessenger:registrar.messenger];

    NativeKeyboardAccessoryPlugin *instance = [[NativeKeyboardAccessoryPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];

    // The bar reports intent; Dart decides what it means. Focus is a framework
    // concept, so traversal has to run there — resigning first responder
    // natively would move the keyboard without telling the framework, leaving
    // Flutter still believing the field is focused and liable to re-raise it.
    NKAAccessoryBar.actionHandler = ^(NKAAction action) {
        [channel invokeMethod:@"onAction" arguments:NKAActionToString(action)];
    };
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([call.method isEqualToString:@"install"]) {
        [NKATextInputPatch setConfiguration:
            [NKAConfiguration configurationWithDictionary:call.arguments]];
        result([NKATextInputPatch install]);
        return;
    }

    if ([call.method isEqualToString:@"setConfiguration"]) {
        [NKATextInputPatch setConfiguration:
            [NKAConfiguration configurationWithDictionary:call.arguments]];
        result(nil);
        return;
    }

    if ([call.method isEqualToString:@"setSuppressed"]) {
        [NKATextInputPatch setSuppressed:[call.arguments boolValue]];
        result(nil);
        return;
    }

    if ([call.method isEqualToString:@"setNavigationState"]) {
        NSDictionary *arguments = [call.arguments isKindOfClass:NSDictionary.class]
            ? (NSDictionary *)call.arguments
            : @{};
        [NKAAccessoryBar setCanGoPrevious:[arguments[@"canPrevious"] boolValue]
                                canGoNext:[arguments[@"canNext"] boolValue]];
        result(nil);
        return;
    }

    result(FlutterMethodNotImplemented);
}

@end
