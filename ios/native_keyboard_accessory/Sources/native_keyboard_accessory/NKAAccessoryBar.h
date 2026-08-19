// NKAAccessoryBar.h
//
// The bar itself: a `UIInputView` holding a rounded pill with up / down / done
// buttons. One shared instance is reused for every field, since at most one
// input view is first responder at a time and rebuilding it per field would
// re-animate it on every focus change.

#import <UIKit/UIKit.h>

#import "NKAConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NKAAction) {
    NKAActionPrevious = 0,
    NKAActionNext = 1,
    NKAActionDone = 2,
};

/// Serialized form used as the method-channel argument.
extern NSString *NKAActionToString(NKAAction action);

@interface NKAAccessoryBar : NSObject

/// The bar, built on first access. Main thread only.
+ (UIView *)sharedBar;

/// Whether the bar has been built yet. Lets configuration changes avoid
/// creating the view before any field has ever been focused.
+ (BOOL)isBarBuilt;

/// Applies `configuration` to the shared bar, if it exists.
+ (void)setConfiguration:(NKAConfiguration *)configuration;

/// Enables or disables the chevrons. Only the Dart side knows whether a
/// sibling field exists in the focus traversal order.
+ (void)setCanGoPrevious:(BOOL)canGoPrevious canGoNext:(BOOL)canGoNext;

/// Invoked on the main thread when a button is tapped.
@property (class, nonatomic, copy, nullable) void (^actionHandler)(NKAAction action);

@end

NS_ASSUME_NONNULL_END
