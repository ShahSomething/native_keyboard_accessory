#import "NKAConfiguration.h"

/// Reads an ARGB integer as sent by Dart's `Color.toARGB32()`, or nil when the
/// key is absent — which the bar treats as "use the system material".
static UIColor *_Nullable NKAColorFromValue(id value) {
    if (![value isKindOfClass:NSNumber.class]) {
        return nil;
    }
    uint32_t argb = (uint32_t)[(NSNumber *)value unsignedIntValue];
    return [UIColor colorWithRed:((argb >> 16) & 0xFF) / 255.0
                           green:((argb >> 8) & 0xFF) / 255.0
                            blue:(argb & 0xFF) / 255.0
                           alpha:((argb >> 24) & 0xFF) / 255.0];
}

/// Pairs the light and dark values into a single dynamic color. When only one
/// side is given it is used for both, so a host that does not care about dark
/// mode can send one color and get a consistent bar.
static UIColor *_Nullable NKADynamicColor(id lightValue, id darkValue) {
    UIColor *light = NKAColorFromValue(lightValue);
    UIColor *dark = NKAColorFromValue(darkValue);
    if (light == nil && dark == nil) {
        return nil;
    }
    if (light == nil) {
        light = dark;
    }
    if (dark == nil) {
        dark = light;
    }
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traits) {
        return traits.userInterfaceStyle == UIUserInterfaceStyleDark ? dark : light;
    }];
}

static BOOL NKABoolFromValue(id value, BOOL fallback) {
    return [value isKindOfClass:NSNumber.class] ? [(NSNumber *)value boolValue] : fallback;
}

static CGFloat NKAFloatFromValue(id value, CGFloat fallback) {
    return [value isKindOfClass:NSNumber.class] ? (CGFloat)[(NSNumber *)value doubleValue] : fallback;
}

static NSString *NKAStringFromValue(id value, NSString *fallback) {
    return ([value isKindOfClass:NSString.class] && ((NSString *)value).length > 0)
        ? (NSString *)value
        : fallback;
}

@implementation NKAConfiguration

+ (instancetype)defaultConfiguration {
    return [self configurationWithDictionary:nil];
}

+ (instancetype)configurationWithDictionary:(NSDictionary *)dictionary {
    NKAConfiguration *configuration = [[NKAConfiguration alloc] init];
    if (configuration == nil) {
        return configuration;
    }

    configuration->_numericKeyboards = NKABoolFromValue(dictionary[@"numericKeyboards"], YES);
    configuration->_multilineFields = NKABoolFromValue(dictionary[@"multilineFields"], YES);
    configuration->_singleLineTextFields =
        NKABoolFromValue(dictionary[@"singleLineTextFields"], NO);

    configuration->_height = NKAFloatFromValue(dictionary[@"height"], 56.0);
    configuration->_horizontalInset = NKAFloatFromValue(dictionary[@"horizontalInset"], 16.0);
    configuration->_verticalInset = NKAFloatFromValue(dictionary[@"verticalInset"], 6.0);
    configuration->_cornerRadius = NKAFloatFromValue(dictionary[@"cornerRadius"], 22.0);
    configuration->_continuousCorners = NKABoolFromValue(dictionary[@"continuousCorners"], YES);
    configuration->_shadowOpacity = NKAFloatFromValue(dictionary[@"shadowOpacity"], 0.12);

    NSInteger layout = (NSInteger)NKAFloatFromValue(dictionary[@"layout"], NKALayoutNavigationAndDone);
    configuration->_layout = (layout >= NKALayoutNavigationAndDone && layout <= NKALayoutNavigationOnly)
        ? (NKALayout)layout
        : NKALayoutNavigationAndDone;

    configuration->_backgroundColor =
        NKADynamicColor(dictionary[@"backgroundColor"], dictionary[@"darkBackgroundColor"]);
    configuration->_tintColor = NKADynamicColor(dictionary[@"tintColor"], dictionary[@"darkTintColor"])
        ?: UIColor.labelColor;

    configuration->_previousLabel = [NKAStringFromValue(dictionary[@"previousLabel"], @"Previous") copy];
    configuration->_nextLabel = [NKAStringFromValue(dictionary[@"nextLabel"], @"Next") copy];
    configuration->_doneLabel = [NKAStringFromValue(dictionary[@"doneLabel"], @"Done") copy];

    return configuration;
}

- (BOOL)hasSameScopeAs:(NKAConfiguration *)other {
    return other != nil
        && other.numericKeyboards == self.numericKeyboards
        && other.multilineFields == self.multilineFields
        && other.singleLineTextFields == self.singleLineTextFields;
}

@end
