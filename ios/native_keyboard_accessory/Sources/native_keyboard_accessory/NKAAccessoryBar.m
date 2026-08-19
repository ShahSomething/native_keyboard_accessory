#import "NKAAccessoryBar.h"

NSString *NKAActionToString(NKAAction action) {
    switch (action) {
        case NKAActionPrevious:
            return @"previous";
        case NKAActionNext:
            return @"next";
        case NKAActionDone:
            return @"done";
    }
    return @"done";
}

static const CGFloat kNKAButtonSide = 44.0;
static const CGFloat kNKAPillPadding = 4.0;
static const CGFloat kNKASymbolPointSize = 17.0;

#pragma mark - View

@interface NKABarView : UIInputView

@property (nonatomic, strong) UIView *pill;
@property (nonatomic, strong) UIButton *previousButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UIButton *doneButton;

@property (nonatomic, strong) NSLayoutConstraint *pillLeading;
@property (nonatomic, strong) NSLayoutConstraint *pillTrailing;
@property (nonatomic, strong) NSLayoutConstraint *pillTop;
@property (nonatomic, strong) NSLayoutConstraint *pillBottom;

@property (nonatomic, strong) NKAConfiguration *configuration;
@property (nonatomic) BOOL canGoPrevious;
@property (nonatomic) BOOL canGoNext;

- (void)applyConfiguration;
- (void)applyNavigationState;

@end

@implementation NKABarView

- (instancetype)initWithConfiguration:(NKAConfiguration *)configuration {
    CGRect frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, configuration.height);
    // `UIInputViewStyleDefault` draws nothing, so the host app's own background
    // shows through around the pill. `...StyleKeyboard` would paint the
    // keyboard's blurred material edge to edge instead.
    self = [super initWithFrame:frame inputViewStyle:UIInputViewStyleDefault];
    if (self != nil) {
        _configuration = configuration;
        self.backgroundColor = UIColor.clearColor;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self buildSubviews];
        [self applyConfiguration];
        [self applyNavigationState];
    }
    return self;
}

/// UIKit sizes an accessory view from its frame, but falls back to the
/// intrinsic size once the view participates in Auto Layout. Supply both.
- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, self.configuration.height);
}

- (void)buildSubviews {
    self.pill = [[UIView alloc] init];
    self.pill.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.pill];

    self.previousButton = [self buttonWithSymbolName:@"chevron.up" action:@selector(handlePrevious)];
    self.nextButton = [self buttonWithSymbolName:@"chevron.down" action:@selector(handleNext)];
    self.doneButton = [self buttonWithSymbolName:@"checkmark" action:@selector(handleDone)];

    [self.pill addSubview:self.previousButton];
    [self.pill addSubview:self.nextButton];
    [self.pill addSubview:self.doneButton];

    self.pillLeading = [self.pill.leadingAnchor constraintEqualToAnchor:self.leadingAnchor];
    self.pillTrailing = [self.pill.trailingAnchor constraintEqualToAnchor:self.trailingAnchor];
    self.pillTop = [self.pill.topAnchor constraintEqualToAnchor:self.topAnchor];
    self.pillBottom = [self.pill.bottomAnchor constraintEqualToAnchor:self.bottomAnchor];

    // Leading/trailing rather than left/right so the bar mirrors itself in a
    // right-to-left locale without any extra work.
    [NSLayoutConstraint activateConstraints:@[
        self.pillLeading,
        self.pillTrailing,
        self.pillTop,
        self.pillBottom,

        [self.previousButton.leadingAnchor constraintEqualToAnchor:self.pill.leadingAnchor
                                                         constant:kNKAPillPadding],
        [self.previousButton.centerYAnchor constraintEqualToAnchor:self.pill.centerYAnchor],
        [self.nextButton.leadingAnchor constraintEqualToAnchor:self.previousButton.trailingAnchor],
        [self.nextButton.centerYAnchor constraintEqualToAnchor:self.pill.centerYAnchor],
        [self.doneButton.trailingAnchor constraintEqualToAnchor:self.pill.trailingAnchor
                                                       constant:-kNKAPillPadding],
        [self.doneButton.centerYAnchor constraintEqualToAnchor:self.pill.centerYAnchor],
    ]];
}

- (UIButton *)buttonWithSymbolName:(NSString *)symbolName action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    UIImageSymbolConfiguration *symbol =
        [UIImageSymbolConfiguration configurationWithPointSize:kNKASymbolPointSize
                                                       weight:UIImageSymbolWeightSemibold];
    [button setImage:[UIImage systemImageNamed:symbolName withConfiguration:symbol]
            forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [NSLayoutConstraint activateConstraints:@[
        [button.widthAnchor constraintEqualToConstant:kNKAButtonSide],
        [button.heightAnchor constraintEqualToConstant:kNKAButtonSide],
    ]];
    return button;
}

- (void)applyConfiguration {
    NKAConfiguration *configuration = self.configuration;

    self.pillLeading.constant = configuration.horizontalInset;
    self.pillTrailing.constant = -configuration.horizontalInset;
    self.pillTop.constant = configuration.verticalInset;
    self.pillBottom.constant = -configuration.verticalInset;

    self.pill.backgroundColor = configuration.backgroundColor;
    self.pill.layer.cornerRadius = configuration.cornerRadius;
    self.pill.layer.cornerCurve = configuration.continuousCorners
        ? kCACornerCurveContinuous
        : kCACornerCurveCircular;
    self.pill.layer.shadowColor = UIColor.blackColor.CGColor;
    self.pill.layer.shadowOpacity = (float)configuration.shadowOpacity;
    self.pill.layer.shadowRadius = 8.0;
    self.pill.layer.shadowOffset = CGSizeMake(0, 2);

    for (UIButton *button in @[self.previousButton, self.nextButton, self.doneButton]) {
        button.tintColor = configuration.tintColor;
    }

    self.previousButton.accessibilityLabel = configuration.previousLabel;
    self.nextButton.accessibilityLabel = configuration.nextLabel;
    self.doneButton.accessibilityLabel = configuration.doneLabel;

    BOOL showsNavigation = configuration.layout != NKALayoutDoneOnly;
    BOOL showsDone = configuration.layout != NKALayoutNavigationOnly;
    self.previousButton.hidden = !showsNavigation;
    self.nextButton.hidden = !showsNavigation;
    self.doneButton.hidden = !showsDone;

    CGRect bounds = self.bounds;
    if (bounds.size.height != configuration.height) {
        bounds.size.height = configuration.height;
        self.bounds = bounds;
        [self invalidateIntrinsicContentSize];
    }

    [self setNeedsLayout];
}

- (void)applyNavigationState {
    self.previousButton.enabled = self.canGoPrevious;
    self.nextButton.enabled = self.canGoNext;
}

- (void)handlePrevious {
    [self emit:NKAActionPrevious];
}

- (void)handleNext {
    [self emit:NKAActionNext];
}

- (void)handleDone {
    [self emit:NKAActionDone];
}

- (void)emit:(NKAAction)action {
    void (^handler)(NKAAction) = NKAAccessoryBar.actionHandler;
    if (handler != nil) {
        handler(action);
    }
}

@end

#pragma mark - Facade

@implementation NKAAccessoryBar

static NKABarView *sBar = nil;
static NKAConfiguration *sConfiguration = nil;
static BOOL sCanGoPrevious = NO;
static BOOL sCanGoNext = NO;
static void (^sActionHandler)(NKAAction) = nil;

+ (NKAConfiguration *)currentConfiguration {
    if (sConfiguration == nil) {
        sConfiguration = [NKAConfiguration defaultConfiguration];
    }
    return sConfiguration;
}

+ (UIView *)sharedBar {
    NSCAssert(NSThread.isMainThread, @"the accessory bar must be built on the main thread");
    if (sBar == nil) {
        sBar = [[NKABarView alloc] initWithConfiguration:[self currentConfiguration]];
        sBar.canGoPrevious = sCanGoPrevious;
        sBar.canGoNext = sCanGoNext;
        [sBar applyNavigationState];
    }
    return sBar;
}

+ (BOOL)isBarBuilt {
    return sBar != nil;
}

+ (void)setConfiguration:(NKAConfiguration *)configuration {
    sConfiguration = configuration;
    // Deliberately does not build the bar: a configuration pushed at startup
    // should not create a view before any field has been focused.
    if (sBar != nil) {
        sBar.configuration = configuration;
        [sBar applyConfiguration];
    }
}

+ (void)setCanGoPrevious:(BOOL)canGoPrevious canGoNext:(BOOL)canGoNext {
    sCanGoPrevious = canGoPrevious;
    sCanGoNext = canGoNext;
    if (sBar != nil) {
        sBar.canGoPrevious = canGoPrevious;
        sBar.canGoNext = canGoNext;
        [sBar applyNavigationState];
    }
}

+ (void (^)(NKAAction))actionHandler {
    return sActionHandler;
}

+ (void)setActionHandler:(void (^)(NKAAction))actionHandler {
    sActionHandler = [actionHandler copy];
}

@end
