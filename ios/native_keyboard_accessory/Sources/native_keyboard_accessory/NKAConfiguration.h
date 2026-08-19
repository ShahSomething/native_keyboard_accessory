// NKAConfiguration.h
//
// Everything the Dart side controls, in one object: which keyboards get the
// bar, how it looks, and what VoiceOver reads. Built from the method-channel
// dictionary so the native surface stays a single `setConfiguration` call
// rather than a dozen setters.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Which buttons the bar shows.
typedef NS_ENUM(NSInteger, NKALayout) {
    /// Chevrons on the leading edge, done on the trailing edge.
    NKALayoutNavigationAndDone = 0,
    /// Done only. Use when fields are not part of a traversable form.
    NKALayoutDoneOnly = 1,
    /// Chevrons only, no dismiss button.
    NKALayoutNavigationOnly = 2,
};

@interface NKAConfiguration : NSObject

#pragma mark - Scope

/// Keyboards iOS renders with no return key at all: number, decimal, phone,
/// and ASCII-number pads.
@property (nonatomic, readonly) BOOL numericKeyboards;

/// Fields whose return key inserts a newline, detected as a return key type of
/// `UIReturnKeyDefault`. There is no built-in way to dismiss these either.
@property (nonatomic, readonly) BOOL multilineFields;

/// Fields whose return key already dismisses or advances. A bar here duplicates
/// an affordance the user already has.
@property (nonatomic, readonly) BOOL singleLineTextFields;

#pragma mark - Style

@property (nonatomic, readonly) CGFloat height;
@property (nonatomic, readonly) CGFloat horizontalInset;
@property (nonatomic, readonly) CGFloat verticalInset;
@property (nonatomic, readonly) CGFloat cornerRadius;
/// Uses `kCACornerCurveContinuous` — the squircle curvature iOS itself uses.
@property (nonatomic, readonly) BOOL continuousCorners;
@property (nonatomic, readonly) CGFloat shadowOpacity;
@property (nonatomic, readonly) NKALayout layout;

/// Resolved per trait collection, so light and dark are one color object.
/// Nil means "use the system keyboard material".
@property (nonatomic, readonly, nullable) UIColor *backgroundColor;
@property (nonatomic, readonly, nullable) UIColor *tintColor;

#pragma mark - Labels

@property (nonatomic, readonly, copy) NSString *previousLabel;
@property (nonatomic, readonly, copy) NSString *nextLabel;
@property (nonatomic, readonly, copy) NSString *doneLabel;

#pragma mark - Construction

/// Defaults matching the Dart-side defaults, used before the first
/// `setConfiguration` arrives.
+ (instancetype)defaultConfiguration;

/// Missing or wrong-typed keys fall back to the default rather than throwing:
/// a malformed configuration should degrade the bar's appearance, never break
/// the host app's text entry.
+ (instancetype)configurationWithDictionary:(nullable NSDictionary *)dictionary;

/// Whether the two configurations would produce a different bar for the same
/// field, used to decide when a live reconfigure must force UIKit to re-query.
- (BOOL)hasSameScopeAs:(NKAConfiguration *)other;

@end

NS_ASSUME_NONNULL_END
