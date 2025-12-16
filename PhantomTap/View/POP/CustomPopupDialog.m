// CustomPopupDialog.m

#import "CustomButtonStyleHelper.h"
#import "CustomPopupDialog.h"
#import "PhantomTap-Swift.h"

@interface CustomPopupDialog ()
{
    UIView *_dimmingView;
    UIView *_cardView;
    LottieView *_loadingView;
    UILabel *_titleLabel;
    UILabel *_messageLabel;
    UIView *_buttonsContainer;
    UIButton *_positiveButton;
    UIButton *_negativeButton;

    NSLayoutConstraint *_loadingHeightConstraint;
    NSLayoutConstraint *_buttonsContainerTopConstraint;

    // 單鈕 / 雙鈕用的 constraint
    NSLayoutConstraint *_singlePosLeading;
    NSLayoutConstraint *_singlePosTrailing;
    NSLayoutConstraint *_doublePosLeading;
    NSLayoutConstraint *_doublePosTrailing;
    NSLayoutConstraint *_doubleNegLeading;
    NSLayoutConstraint *_doubleNegTrailing;
}

@end

@implementation CustomPopupDialog

#pragma mark - Public

- (UIView *)cardView
{
    return _cardView;
}

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    [self setBackgroundColor:[UIColor clearColor]];

    // 1) 半透明背景
    _dimmingView = [[UIView alloc] initWithFrame:[self bounds]];
    [_dimmingView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_dimmingView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.5]];
    [self addSubview:_dimmingView];

    // 2) 卡片
    _cardView = [[UIView alloc] initWithFrame:CGRectZero];
    [_cardView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_cardView setBackgroundColor:[UIColor whiteColor]];
    [[_cardView layer] setCornerRadius:16.0];
    [[_cardView layer] setMasksToBounds:YES];
    [self addSubview:_cardView];

    // 3) Loading Lottie
    _loadingView = [[LottieView alloc] initWithFrame:CGRectZero];
    [_loadingView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_loadingView setBackgroundColor:[UIColor clearColor]];
    [_loadingView setAnimationName:@"loading"];
    [_loadingView setLoop:YES];
    [_cardView addSubview:_loadingView];

    // 4) Title
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [_titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_titleLabel setFont:[UIFont boldSystemFontOfSize:17.0]];
    [_titleLabel setTextAlignment:NSTextAlignmentCenter];
    [_titleLabel setTextColor:[UIColor blackColor]];
    [_titleLabel setNumberOfLines:0];
    [_cardView addSubview:_titleLabel];

    // 5) Message
    _messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [_messageLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_messageLabel setFont:[UIFont systemFontOfSize:15.0]];
    [_messageLabel setTextAlignment:NSTextAlignmentCenter];
    [_messageLabel setTextColor:[UIColor darkGrayColor]];
    [_messageLabel setNumberOfLines:0];
    [_cardView addSubview:_messageLabel];

    // 6) Buttons container
    _buttonsContainer = [[UIView alloc] initWithFrame:CGRectZero];
    [_buttonsContainer setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_cardView addSubview:_buttonsContainer];

    // 7) Positive button
    _positiveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_positiveButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_positiveButton addTarget:self action:@selector(handlePositiveTap) forControlEvents:UIControlEventTouchUpInside];
    [_buttonsContainer addSubview:_positiveButton];
    
    [_positiveButton setBackgroundColor:[CustomButtonStyleHelper brookCyanColor]];
    // 膠囊圓角：高度的一半
    [[_positiveButton layer] setCornerRadius:CGRectGetHeight([_positiveButton bounds]) / 2.0];
    [[_positiveButton layer] setMasksToBounds:YES];
    // 文字樣式
    [_positiveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [[_positiveButton titleLabel] setFont:[UIFont fontWithName:@"NotoSansTC-Black" size:14.0]];    
    // 按下去稍微變暗
    UIColor *pressedColor = [[CustomButtonStyleHelper brookCyanColor] colorWithAlphaComponent:0.7];
    UIImage *normalBg = [CustomButtonStyleHelper imageWithColor:[CustomButtonStyleHelper brookCyanColor]];
    UIImage *highlightBg = [CustomButtonStyleHelper imageWithColor:pressedColor];
    [_positiveButton setBackgroundImage:normalBg forState:UIControlStateNormal];
    [_positiveButton setBackgroundImage:highlightBg forState:UIControlStateHighlighted];

    // 8) Negative button
    _negativeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_negativeButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_negativeButton addTarget:self action:@selector(handleNegativeTap) forControlEvents:UIControlEventTouchUpInside];
    [_buttonsContainer addSubview:_negativeButton];
    // 白底
    [_negativeButton setBackgroundColor:[UIColor whiteColor]];
    // 膠囊圓角：高度的一半
    [[_negativeButton layer] setCornerRadius:CGRectGetHeight([_negativeButton bounds]) / 2.0];
    [[_negativeButton layer] setMasksToBounds:YES];
    // 邊框
    [[_negativeButton layer] setBorderWidth:2.0];
    [[_negativeButton layer] setBorderColor:[CustomButtonStyleHelper brookCyanColor].CGColor];
    // 文字顏色
    [_negativeButton setTitleColor:[CustomButtonStyleHelper brookCyanColor] forState:UIControlStateNormal];
    [[_negativeButton titleLabel] setFont:[UIFont fontWithName:@"NotoSansTC-Black" size:14.0]];
    // 按下去讓底色稍微變淺一點
    UIColor *pressedColorForNeg = [[UIColor whiteColor] colorWithAlphaComponent:0.8];
    UIImage *normalBgForNeg = [CustomButtonStyleHelper imageWithColor:[UIColor whiteColor]];
    UIImage *highlightBgForNeg = [CustomButtonStyleHelper imageWithColor:pressedColorForNeg];
    [_negativeButton setBackgroundImage:normalBgForNeg forState:UIControlStateNormal];
    [_negativeButton setBackgroundImage:highlightBgForNeg forState:UIControlStateHighlighted];

    //
    // ====== Auto Layout ======
    //

    // dimmingView 全畫面
    [NSLayoutConstraint activateConstraints:@[
        [[_dimmingView topAnchor] constraintEqualToAnchor:[self topAnchor]],
        [[_dimmingView bottomAnchor] constraintEqualToAnchor:[self bottomAnchor]],
        [[_dimmingView leadingAnchor] constraintEqualToAnchor:[self leadingAnchor]],
        [[_dimmingView trailingAnchor] constraintEqualToAnchor:[self trailingAnchor]],
    ]];

    // cardView 置中、寬度
    [NSLayoutConstraint activateConstraints:@[
        [[_cardView centerXAnchor] constraintEqualToAnchor:[self centerXAnchor]],
        [[_cardView centerYAnchor] constraintEqualToAnchor:[self centerYAnchor]],
        [[_cardView widthAnchor] constraintLessThanOrEqualToAnchor:[self widthAnchor] constant:-40.0],
        [[_cardView widthAnchor] constraintGreaterThanOrEqualToConstant:260.0],
    ]];

    // loading
    _loadingHeightConstraint = [[_loadingView heightAnchor] constraintEqualToConstant:0.0];   // 初始先 0
    [NSLayoutConstraint activateConstraints:@[
        [[_loadingView topAnchor] constraintEqualToAnchor:[_cardView topAnchor] constant:20.0],
        [[_loadingView centerXAnchor] constraintEqualToAnchor:[_cardView centerXAnchor]],
        [[_loadingView widthAnchor] constraintEqualToConstant:80.0],
        _loadingHeightConstraint,
    ]];

    // title
    [NSLayoutConstraint activateConstraints:@[
        [[_titleLabel topAnchor] constraintEqualToAnchor:[_loadingView bottomAnchor] constant: (CGFloat)12.0],
        [[_titleLabel leadingAnchor] constraintEqualToAnchor:[_cardView leadingAnchor] constant:16.0],
        [[_titleLabel trailingAnchor] constraintEqualToAnchor:[_cardView trailingAnchor] constant:-16.0],
    ]];

    // message
    [NSLayoutConstraint activateConstraints:@[
        [[_messageLabel topAnchor] constraintEqualToAnchor:[_titleLabel bottomAnchor] constant:8.0],
        [[_messageLabel leadingAnchor] constraintEqualToAnchor:[_cardView leadingAnchor] constant:16.0],
        [[_messageLabel trailingAnchor] constraintEqualToAnchor:[_cardView trailingAnchor] constant:-16.0],
    ]];

    // buttons container
    _buttonsContainerTopConstraint = [[_buttonsContainer topAnchor] constraintEqualToAnchor:_messageLabel.bottomAnchor constant:20.0];

    [NSLayoutConstraint activateConstraints:@[
        _buttonsContainerTopConstraint,
        [[_buttonsContainer leadingAnchor] constraintEqualToAnchor:[_cardView leadingAnchor] constant:16.0],
        [[_buttonsContainer trailingAnchor] constraintEqualToAnchor:[_cardView trailingAnchor] constant:-16.0],
        [[_buttonsContainer heightAnchor] constraintEqualToConstant:40.0],
        [[_buttonsContainer bottomAnchor] constraintEqualToAnchor:[_cardView bottomAnchor] constant:-20.0],
    ]];

    // 正負按鈕垂直頂底對齊
    [NSLayoutConstraint activateConstraints:@[
        [[_positiveButton topAnchor] constraintEqualToAnchor:[_buttonsContainer topAnchor]],
        [[_positiveButton bottomAnchor] constraintEqualToAnchor:[_buttonsContainer bottomAnchor]],
        [[_negativeButton topAnchor] constraintEqualToAnchor:[_buttonsContainer topAnchor]],
        [[_negativeButton bottomAnchor] constraintEqualToAnchor:[_buttonsContainer bottomAnchor]],
    ]];

    // 單鈕：正鍵佔滿整個 container
    _singlePosLeading = [[_positiveButton leadingAnchor] constraintEqualToAnchor:[_buttonsContainer leadingAnchor]];
    _singlePosTrailing = [[_positiveButton trailingAnchor] constraintEqualToAnchor:[_buttonsContainer trailingAnchor]];

    // 雙鈕：左右各一半
    _doublePosLeading = [[_positiveButton leadingAnchor] constraintEqualToAnchor:[_buttonsContainer leadingAnchor]];
    _doublePosTrailing = [[_positiveButton trailingAnchor] constraintEqualToAnchor:[_buttonsContainer centerXAnchor] constant:-6.0];
    _doubleNegLeading = [[_negativeButton leadingAnchor] constraintEqualToAnchor:[_buttonsContainer centerXAnchor] constant:6.0];
    _doubleNegTrailing = [[_negativeButton trailingAnchor] constraintEqualToAnchor:[_buttonsContainer trailingAnchor]];

    // 先全部 deactivate，之後 configureForStyle 會決定要哪一組
    [_singlePosLeading setActive:NO];
    [_singlePosTrailing setActive:NO];
    [_doublePosLeading setActive:NO];
    [_doublePosTrailing setActive:NO];
    [_doubleNegLeading setActive:NO];
    [_doubleNegTrailing setActive:NO];

    // 初始樣式：Loading
    self.style = CustomPopupDialogStyleLoading;
}

#pragma mark - Layout（只負責套 Button Style）

- (void)layoutSubviews
{
    [super layoutSubviews];

    switch (self.style)
    {
        case CustomPopupDialogStyleLoading:
            // 沒按鈕，不用套 style
            break;

        case CustomPopupDialogStyleSingleButton:
            [CustomButtonStyleHelper applyFilledSmallButtonStyleTo:_positiveButton];
            break;

        case CustomPopupDialogStyleDoubleButton:
            [CustomButtonStyleHelper applyFilledSmallButtonStyleTo:_positiveButton];
            [CustomButtonStyleHelper applyOutlineSmallButtonStyleTo:_negativeButton];
            break;
    }
}

#pragma mark - Public 靜態方法

+ (instancetype)showLoadingInView:(UIView *)aParentView
                            title:(nullable NSString *)aTitle
                          message:(nullable NSString *)aMessage
{
    CustomPopupDialog *popup = [[CustomPopupDialog alloc] initWithFrame:aParentView.bounds];
    [aParentView addSubview:popup];

    [popup configureForStyle:CustomPopupDialogStyleLoading
                       title:aTitle
                     message:aMessage
         positiveButtonLabel:nil
         negativeButtonLabel:nil
                  onPositive:nil
                  onNegative:nil];

    [popup setAlpha:0.0];
    [UIView animateWithDuration:0.2 animations:^{
        [popup setAlpha:1.0];
    }];
    return popup;
}

+ (instancetype)showInView:(UIView *)aParentView
                     style:(CustomPopupDialogStyle)aStyle
                     title:(nullable NSString *)aTitle
                   message:(nullable NSString *)aMessage
       positiveButtonLabel:(nullable NSString *)aPositiveButtonLabel
       negativeButtonLabel:(nullable NSString *)aNegativeButtonLabel
                 onPositive:(nullable CustomPopupHandler)aOnPositiveHandler
                 onNegative:(nullable CustomPopupHandler)aOnNegativeHanbler
{
    CustomPopupDialog *popup = [[CustomPopupDialog alloc] initWithFrame:aParentView.bounds];
    [aParentView addSubview:popup];

    [popup configureForStyle:aStyle
                       title:aTitle
                     message:aMessage
         positiveButtonLabel:aPositiveButtonLabel
         negativeButtonLabel:aNegativeButtonLabel
                  onPositive:aOnPositiveHandler
                  onNegative:aOnNegativeHanbler];

    [popup setAlpha:0.0];
    [UIView animateWithDuration:0.2 animations:^{
        [popup setAlpha:1.0];
    }];
    return popup;
}

#pragma mark - 更新樣式

- (void)updateToStyle:(CustomPopupDialogStyle)aStyle
                title:(nullable NSString *)aTitle
              message:(nullable NSString *)aMessage
  positiveButtonLabel:(nullable NSString *)aPositiveButtonLabel
  negativeButtonLabel:(nullable NSString *)aNegativeButtonLabel
           onPositive:(nullable CustomPopupHandler)aOnPositiveHandler
           onNegative:(nullable CustomPopupHandler)aOnNegativeHanbler
{
    [self configureForStyle:aStyle
                      title:aTitle
                    message:aMessage
        positiveButtonLabel:aPositiveButtonLabel
        negativeButtonLabel:aNegativeButtonLabel
                 onPositive:aOnPositiveHandler
                 onNegative:aOnNegativeHanbler];
}

#pragma mark - 關閉

- (void)dismiss
{
    [UIView animateWithDuration:0.2 animations:^{
        [self setAlpha:0.0];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

#pragma mark - 內部：套用樣式／約束

- (void)configureForStyle:(CustomPopupDialogStyle)aStyle
                    title:(nullable NSString *)aTitle
                  message:(nullable NSString *)aMessage
      positiveButtonLabel:(nullable NSString *)aPositiveButtonLabel
      negativeButtonLabel:(nullable NSString *)aNegativeButtonLabel
               onPositive:(nullable CustomPopupHandler)aOnPositiveHandler
               onNegative:(nullable CustomPopupHandler)aOnNegativeHanbler
{
    self.style = aStyle;

    [_titleLabel setText:aTitle];
    [_messageLabel setText:aMessage];

    self.onPositive = aOnPositiveHandler;
    self.onNegative = aOnNegativeHanbler;

    // 先關掉所有跟按鈕位置有關的 constraint
    [_singlePosLeading setActive:NO];
    [_singlePosTrailing setActive:NO];
    [_doublePosLeading setActive:NO];
    [_doublePosTrailing setActive:NO];
    [_doubleNegLeading setActive:NO];
    [_doubleNegTrailing setActive:NO];

    switch (aStyle)
    {
        case CustomPopupDialogStyleLoading:
        {
            [_loadingView setHidden:NO];
            [_loadingView play];
            _loadingHeightConstraint.constant = 80.0;

            [_buttonsContainer setHidden:YES];
            break;
        }

        case CustomPopupDialogStyleSingleButton:
        {
            [_loadingView setHidden:YES];
            [_loadingView stop];
            [_loadingHeightConstraint setConstant:0.0];

            [_buttonsContainer setHidden:NO];

            [_positiveButton setHidden:NO];
            [_negativeButton setHidden:YES];
            
            [CustomButtonStyleHelper applyFilledSmallButtonStyleTo:_positiveButton];

            NSString *btnTitle = aPositiveButtonLabel ?: NSLocalizedString(@"ok", nil);
            [_positiveButton setTitle:btnTitle forState:UIControlStateNormal];

            // 單鈕：正鍵佔滿
            [_singlePosLeading setActive:YES];
            [_singlePosTrailing setActive:YES];
            break;
        }

        case CustomPopupDialogStyleDoubleButton:
        {
            [_loadingView setHidden:YES];
            [_loadingView stop];
            [_loadingHeightConstraint setConstant:0.0];

            [_buttonsContainer setHidden:NO];

            [_positiveButton setHidden:NO];
            [_negativeButton setHidden:NO];
            
            [CustomButtonStyleHelper applyFilledSmallButtonStyleTo:_positiveButton];
            [CustomButtonStyleHelper applyOutlineSmallButtonStyleTo:_negativeButton];

            NSString *posTitle = aPositiveButtonLabel ?: NSLocalizedString(@"ok", nil);
            NSString *negTitle = aNegativeButtonLabel ?: NSLocalizedString(@"ok", nil);
            [_positiveButton setTitle:posTitle forState:UIControlStateNormal];
            [_negativeButton setTitle:negTitle forState:UIControlStateNormal];

            // 雙鈕：左右各一半
            [_doublePosLeading setActive:YES];
            [_doublePosTrailing setActive:YES];
            [_doubleNegLeading setActive:YES];
            [_doubleNegTrailing setActive:YES];
            break;
        }
    }

    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - Button actions

- (void)handlePositiveTap
{
    // if (self.onPositive) self.onPositive();
    if (self -> _onPositive)
    {
        self -> _onPositive();
    }
}

- (void)handleNegativeTap
{
    // if (self.onNegative) self.onNegative();
    if (self -> _onNegative)
    {
        self -> _onNegative();
    }
}

@end
