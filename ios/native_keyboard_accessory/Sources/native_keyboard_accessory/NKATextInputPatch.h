// NKATextInputPatch.h
//
// Attaches the accessory bar to Flutter's own text input view.
//
// Flutter has no accessory-view concept: `EditableText` never creates a
// `UITextField`, so no Flutter text field gets one. What it does create is
// `FlutterTextInputView` — the hidden `UIView` the engine makes first responder
// to drive the keyboard. That view is a plain `UIView` subclass which does not
// implement `-inputAccessoryView`, so it inherits `UIResponder`'s readonly
// implementation and returns nil. There is no engine API and no plugin hook to
// supply one, so this adds the method at runtime.
//
// This is the one part of the package that depends on engine internals. It is
// written to fail closed: every assumption is re-checked before patching, and
// `install` reports exactly what attached so a host can detect a Flutter
// version this no longer works on. See README "Engine coupling".

#import <UIKit/UIKit.h>

#import "NKAConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface NKATextInputPatch : NSObject

/// Installs the patch. Idempotent — repeat calls report the existing state.
///
/// Returns a diagnostics dictionary with boolean values for keys
/// `installed`, `inputAccessoryPatched`, and `keyboardTypeHookInstalled`.
/// `installed` is NO only when `FlutterTextInputView` could not be found at
/// all, which means the engine has been changed in a way this cannot support.
+ (NSDictionary<NSString *, NSNumber *> *)install;

/// Stops the bar from being returned, without unpatching. Method
/// implementations are deliberately left in place: restoring an original IMP is
/// not safe when another party may have swizzled the same method afterwards.
+ (void)setSuppressed:(BOOL)suppressed;

/// Applies a new configuration and, when the scope changed, forces UIKit to
/// re-query the currently focused field.
+ (void)setConfiguration:(NKAConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END
