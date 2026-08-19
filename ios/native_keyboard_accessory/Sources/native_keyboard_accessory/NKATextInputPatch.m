#import "NKATextInputPatch.h"

#import <objc/runtime.h>

#import "NKAAccessoryBar.h"

static NSString *const kNKAFlutterTextInputViewClassName = @"FlutterTextInputView";

static BOOL sInstalled = NO;
static BOOL sInputAccessoryPatched = NO;
static BOOL sKeyboardTypeHookInstalled = NO;
static BOOL sSuppressed = NO;

static NKAConfiguration *sConfiguration = nil;

static NKAConfiguration *NKACurrentConfiguration(void) {
    if (sConfiguration == nil) {
        sConfiguration = [NKAConfiguration defaultConfiguration];
    }
    return sConfiguration;
}

#pragma mark - Eligibility

/// Whether iOS renders `keyboardType` with no return key at all. These are the
/// reason the bar exists: with no return key there is no built-in way to
/// dismiss the keyboard or advance to the next field.
static BOOL NKAKeyboardLacksReturnKey(UIKeyboardType keyboardType) {
    switch (keyboardType) {
        case UIKeyboardTypeNumberPad:
        case UIKeyboardTypeDecimalPad:
        case UIKeyboardTypePhonePad:
        case UIKeyboardTypeASCIICapableNumberPad:
            return YES;
        default:
            return NO;
    }
}

/// Reads a `UITextInputTraits` value that `FlutterTextInputView` backs with an
/// ivar. Key-value coding rather than a protocol cast because every
/// `UITextInputTraits` member is `@optional`, so a direct property access would
/// be a hard dependency on a declaration the engine is free to drop.
static NSInteger NKATraitValue(UIView *view, NSString *key, NSInteger fallback) {
    id value = nil;
    @try {
        value = [view valueForKey:key];
    } @catch (NSException *exception) {
        return fallback;
    }
    return [value isKindOfClass:NSNumber.class] ? [(NSNumber *)value integerValue] : fallback;
}

/// Whether the bar should appear for `view` under the current configuration.
///
/// Keyed on the resolved `UIKeyboardType` and `UIReturnKeyType` rather than on
/// Dart's `TextInputType`, so it stays correct however the engine chooses to
/// map a given Dart type — including the signed and decimal
/// `numberWithOptions` variants, which do not all land on the same iOS
/// keyboard.
static BOOL NKAShouldShowBarFor(UIView *view) {
    if (sSuppressed) {
        return NO;
    }

    NKAConfiguration *configuration = NKACurrentConfiguration();
    UIKeyboardType keyboardType =
        (UIKeyboardType)NKATraitValue(view, @"keyboardType", UIKeyboardTypeDefault);

    if (NKAKeyboardLacksReturnKey(keyboardType)) {
        return configuration.numericKeyboards;
    }

    // A return key type of Default is Flutter's mapping for
    // `TextInputAction.newline`, which is the framework default for a
    // multi-line field. Such a field has a return key, but pressing it inserts
    // a newline rather than dismissing, so it has no exit either.
    UIReturnKeyType returnKeyType =
        (UIReturnKeyType)NKATraitValue(view, @"returnKeyType", UIReturnKeyDone);
    if (returnKeyType == UIReturnKeyDefault) {
        return configuration.multilineFields;
    }

    return configuration.singleLineTextFields;
}

#pragma mark - Patched implementations

/// The input view UIKit most recently asked for an accessory view.
///
/// Recorded before the eligibility check, deliberately: UIKit queries the
/// getter for every input view that becomes first responder regardless of what
/// it returns, which makes it the one hook that also sees fields the current
/// configuration excludes. That is what lets a live reconfigure refresh a field
/// which is focused right now but showing no bar yet.
static __weak UIView *sLastQueriedInputView = nil;

/// What the getter last handed UIKit for `sLastQueriedInputView`, and therefore
/// what UIKit still has cached. Needed because the decision cannot be
/// recomputed after a configuration change to discover what it used to be.
static BOOL sLastReturnedBar = NO;

static UIView *_Nullable NKAInputAccessoryView(UIView *self, SEL _cmd) {
    BOOL showsBar = NKAShouldShowBarFor(self);
    sLastQueriedInputView = self;
    sLastReturnedBar = showsBar;
    return showsBar ? NKAAccessoryBar.sharedBar : nil;
}

static void (*sOriginalSetKeyboardType)(id, SEL, UIKeyboardType) = NULL;

static void NKASetKeyboardType(UIView *self, SEL _cmd, UIKeyboardType keyboardType) {
    BOOL wasEligible = NKAShouldShowBarFor(self);

    sOriginalSetKeyboardType(self, _cmd, keyboardType);

    // UIKit caches `inputAccessoryView` when a responder becomes first
    // responder. If the engine reuses one input view across two fields, a
    // keyboard-type change while focused would otherwise keep the stale
    // decision. Reload only when the decision actually flips — an
    // unconditional `reloadInputViews` here makes the keyboard flicker.
    if (wasEligible != NKAShouldShowBarFor(self) && self.isFirstResponder) {
        [self reloadInputViews];
    }
}

#pragma mark - Install

/// Whether `cls` itself implements `selector`, ignoring anything inherited.
///
/// `class_getInstanceMethod` walks up the superclass chain, so passing its
/// result to `method_setImplementation` would rewrite the *superclass's*
/// method. For `-inputAccessoryView` that means patching `UIResponder` and
/// putting this bar above the keyboard for every responder in the host app.
static BOOL NKAImplementsSelectorDirectly(Class cls, SEL selector) {
    unsigned int count = 0;
    Method *methods = class_copyMethodList(cls, &count);
    BOOL found = NO;
    for (unsigned int i = 0; i < count; i++) {
        if (method_getName(methods[i]) == selector) {
            found = YES;
            break;
        }
    }
    free(methods);
    return found;
}

@implementation NKATextInputPatch

+ (NSDictionary<NSString *, NSNumber *> *)install {
    if (sInstalled) {
        return [self diagnostics];
    }

    Class cls = NSClassFromString(kNKAFlutterTextInputViewClassName);
    if (cls == Nil) {
        return [self diagnostics];
    }
    sInstalled = YES;

    // `class_addMethod` attaches the override to FlutterTextInputView alone,
    // which is what is wanted while the class inherits the nil-returning
    // UIResponder implementation. It returns NO if the class has gained its own
    // implementation, in which case swizzling that one is safe.
    if (class_addMethod(cls, @selector(inputAccessoryView), (IMP)NKAInputAccessoryView, "@16@0:8")) {
        sInputAccessoryPatched = YES;
    } else {
        Method existing = class_getInstanceMethod(cls, @selector(inputAccessoryView));
        if (existing != NULL) {
            method_setImplementation(existing, (IMP)NKAInputAccessoryView);
            sInputAccessoryPatched = YES;
        }
    }

    // Optional: without it the bar still works, only a keyboard-type change on
    // an already-focused reused input view goes unnoticed. Guarded by the
    // direct-implementation check so a future engine dropping its own
    // `-setKeyboardType:` skips the hook instead of patching UIResponder's.
    SEL setKeyboardType = @selector(setKeyboardType:);
    if (NKAImplementsSelectorDirectly(cls, setKeyboardType)) {
        Method method = class_getInstanceMethod(cls, setKeyboardType);
        if (method != NULL) {
            sOriginalSetKeyboardType = (void (*)(id, SEL, UIKeyboardType))
                method_setImplementation(method, (IMP)NKASetKeyboardType);
            sKeyboardTypeHookInstalled = YES;
        }
    }

    return [self diagnostics];
}

+ (NSDictionary<NSString *, NSNumber *> *)diagnostics {
    return @{
        @"installed": @(sInstalled),
        @"inputAccessoryPatched": @(sInputAccessoryPatched),
        @"keyboardTypeHookInstalled": @(sKeyboardTypeHookInstalled),
    };
}

+ (void)setSuppressed:(BOOL)suppressed {
    if (suppressed == sSuppressed) {
        return;
    }
    sSuppressed = suppressed;
    [self refreshFocusedFieldIfDecisionChanged];
}

+ (void)setConfiguration:(NKAConfiguration *)configuration {
    NKAConfiguration *previous = NKACurrentConfiguration();
    sConfiguration = configuration;
    [NKAAccessoryBar setConfiguration:configuration];

    // A scope change does not change the field's keyboard type, so the
    // `-setKeyboardType:` hook never fires and UIKit keeps the accessory view
    // it cached on becoming first responder. Force the re-query here.
    if (![previous hasSameScopeAs:configuration]) {
        [self refreshFocusedFieldIfDecisionChanged];
    }
}

/// Re-queries the focused field, but only when the decision for that specific
/// field actually flipped, so a no-op change cannot flicker the keyboard.
+ (void)refreshFocusedFieldIfDecisionChanged {
    UIView *focused = sLastQueriedInputView;
    if (focused == nil || !focused.isFirstResponder) {
        return;
    }
    // Compared against the cached `sLastReturnedBar` rather than re-reading
    // `focused.inputAccessoryView`: that getter is this patch, so it would
    // answer with the *new* configuration and the two sides would always agree.
    if (sLastReturnedBar != NKAShouldShowBarFor(focused)) {
        [focused reloadInputViews];
    }
}

@end
