//
//  FloatingSidebarBuilder.m
//  PhantomTap
//
//  Created by ethanlin on 2025/10/14.
//

#import "FloatingSidebarBuilder.h"

/// ✅ 收合/展開同寬
static const CGFloat kSidebarWidth = 56.0;

static const NSInteger kDragButtonTag = 9999;


@implementation FloatingSidebarBuilder

+ (NSInteger)getDragButtonTag
{
    return kDragButtonTag;
}


+ (UIButton *)makeIconButton:(NSString *)aImageName target:(id)aTarget action:(SEL)aSEL
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *img = [[UIImage imageNamed:aImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [btn setImage:img forState:UIControlStateNormal];
    [btn setTintColor:[UIColor clearColor]];
    
    /*
    if (@available(iOS 15.0, *))
    {
        
    }
    else
    {
        [btn setContentEdgeInsets:UIEdgeInsetsMake(6, 6, 6, 6)];
    }
    */
    
    UIButtonConfiguration *btnConfig = [UIButtonConfiguration filledButtonConfiguration];
    [btnConfig setContentInsets:NSDirectionalEdgeInsetsMake(5, 5, 5, 5)];
    // [btnConfig setContentInsets:NSDirectionalEdgeInsetsZero];
    [btnConfig setImagePadding:6];
    
    // UIImageSymbolConfiguration *symbolConfig = [UIImageSymbolConfiguration configurationWithPointSize:22]; // 試試 22 點
    // [btnConfig setPreferredSymbolConfigurationForImage:symbolConfig];
    [[btn imageView] setContentMode:UIViewContentModeScaleAspectFit];
    
    [btn setConfiguration:btnConfig];
    
    [btn setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[[btn heightAnchor] constraintEqualToConstant:55] setActive:YES];
    
    NSLayoutConstraint *wLE = [[btn widthAnchor] constraintLessThanOrEqualToConstant:55];
    [wLE setActive:YES];
    
    if (aTarget && aSEL)
    {
        [btn addTarget:aTarget action:aSEL forControlEvents:UIControlEventTouchUpInside];
    }
    
    return btn;
}

+ (UIView *)baseBar
{
    UIView *v = [UIView new];
    [v setTranslatesAutoresizingMaskIntoConstraints:NO];
    [v setBackgroundColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5]];
    [[v layer] setCornerRadius:8];
    // ✅ 固定單一寬度，避免來回加不同寬度造成衝突
    [[[v widthAnchor] constraintEqualToConstant:kSidebarWidth] setActive:YES];
    
    return v;
}

+ (UIStackView *)makeStackInto:(UIView *)aHost
{
    UIStackView *stackView = [[UIStackView alloc] init];
    [stackView setAxis:UILayoutConstraintAxisVertical];
    [stackView setSpacing:8];
    [stackView setAlignment:UIStackViewAlignmentCenter];
    [stackView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [aHost addSubview:stackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [[stackView topAnchor] constraintEqualToAnchor:[aHost topAnchor] constant:8],
        [[stackView leadingAnchor] constraintEqualToAnchor:[aHost leadingAnchor] constant:8],
        [[stackView trailingAnchor] constraintEqualToAnchor:[aHost trailingAnchor] constant:-8],
        [[stackView bottomAnchor] constraintEqualToAnchor:[aHost bottomAnchor] constant:-8],
    ]];
    
    
    return stackView;
}


+ (UIView *)collapsedBarWithTarget:(id<FloatingSidebarActions>)aTarget
{
    UIView *bar = [self baseBar];
    UIStackView *stackView = [self makeStackInto:bar];
    
    UIButton *drag = [self makeIconButton:@"icon_drag" target:nil action:NULL];
    [drag setTag:kDragButtonTag];
    UIButton *pickPhoto = [self makeIconButton:@"icon_photo" target:aTarget action:@selector(onTapPickPhoto)];    
    UIButton *expand = [self makeIconButton:@"icon_expand" target:aTarget action:@selector(toggleSidebar)];
    
    [stackView addArrangedSubview:drag];
    [stackView addArrangedSubview:pickPhoto];
    [stackView addArrangedSubview:expand];
    
    return bar;
}

+ (UIView *)expandedBarWithTarget:(id<FloatingSidebarActions>)aTarget
{
    UIView *bar = [self baseBar];
    
    UIStackView *mainStackView = [[UIStackView alloc] init];
    [mainStackView setAxis:UILayoutConstraintAxisVertical];
    [mainStackView setSpacing:8];
    [mainStackView setAlignment:UIStackViewAlignmentCenter];
    [mainStackView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [bar addSubview:mainStackView];
    
    UIButton *drag = [self makeIconButton:@"icon_drag" target:nil action:NULL];
    [drag setTag:kDragButtonTag];
    [mainStackView addArrangedSubview:drag];
    
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    [scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [scrollView setShowsVerticalScrollIndicator:NO];
    [scrollView setShowsHorizontalScrollIndicator:NO];
    [mainStackView addArrangedSubview:scrollView];
    
    UIView *containerView = [[UIView alloc] init];
    [containerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [scrollView addSubview:containerView];
    
    UIStackView *buttonStackView = [[UIStackView alloc] init];
    [buttonStackView setAxis:UILayoutConstraintAxisVertical];
    [buttonStackView setSpacing:8];
    [buttonStackView setAlignment:UIStackViewAlignmentCenter];
    [buttonStackView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [containerView addSubview:buttonStackView];
    
    NSLayoutConstraint *mainTop = [[mainStackView topAnchor] constraintEqualToAnchor:[bar topAnchor] constant:8];
    NSLayoutConstraint *mainLeading = [[mainStackView leadingAnchor] constraintEqualToAnchor:[bar leadingAnchor] constant:8];
    NSLayoutConstraint *mainTrailing = [[mainStackView trailingAnchor] constraintEqualToAnchor:[bar trailingAnchor] constant:-8];
    NSLayoutConstraint *mainBottom = [[mainStackView bottomAnchor] constraintEqualToAnchor:[bar bottomAnchor] constant:-8];
    
    NSLayoutConstraint *scrollWidth = [[scrollView widthAnchor] constraintEqualToAnchor:[mainStackView widthAnchor]];
    
    NSLayoutConstraint *scrollViewIdealHeight = [[scrollView heightAnchor] constraintEqualToAnchor:[buttonStackView heightAnchor]];
    [scrollViewIdealHeight setPriority:UILayoutPriorityDefaultLow];
    
    UILayoutGuide *contentGuide = [scrollView contentLayoutGuide];
    UILayoutGuide *frameGuide = [scrollView frameLayoutGuide];
    NSLayoutConstraint *containerTop = [[containerView topAnchor] constraintEqualToAnchor:[contentGuide topAnchor]];
    NSLayoutConstraint *containerLeading = [[containerView leadingAnchor] constraintEqualToAnchor:[contentGuide leadingAnchor]];
    NSLayoutConstraint *containerTrailing = [[containerView trailingAnchor] constraintEqualToAnchor:[contentGuide trailingAnchor]];
    NSLayoutConstraint *containerBottom = [[containerView bottomAnchor] constraintEqualToAnchor:[contentGuide bottomAnchor]];
    NSLayoutConstraint *containerWidth = [[containerView widthAnchor] constraintEqualToAnchor:[frameGuide widthAnchor]];
    
    NSLayoutConstraint *btnStackTop = [[buttonStackView topAnchor] constraintEqualToAnchor:[containerView topAnchor]];
    NSLayoutConstraint *btnStackLeading = [[buttonStackView leadingAnchor] constraintEqualToAnchor:[containerView leadingAnchor]];
    NSLayoutConstraint *btnStackTrailing = [[buttonStackView trailingAnchor] constraintEqualToAnchor:[containerView trailingAnchor]];
    NSLayoutConstraint *btnStackBottom = [[buttonStackView bottomAnchor] constraintEqualToAnchor:[containerView bottomAnchor]];
    
    [NSLayoutConstraint activateConstraints:@[
        mainTop, mainLeading, mainTrailing, mainBottom,
        scrollWidth, scrollViewIdealHeight,
        containerTop, containerLeading, containerTrailing, containerBottom, containerWidth,
        btnStackTop, btnStackLeading, btnStackTrailing, btnStackBottom
    ]];
    
    // ✅【關鍵修正】只加入功能按鈕
    UIButton *add = [self makeIconButton:@"add_donut" target:aTarget action:@selector(onTapAddPhantomTap)];
    UIButton *save = [self makeIconButton:@"save_config_to_json" target:aTarget action:@selector(onTapSave)];
    UIButton *upload = [self makeIconButton:@"load_from_json" target:aTarget action:@selector(onTapUpload)];
    UIButton *clear = [self makeIconButton:@"icon_clear" target:aTarget action:@selector(onTapClear)];
    UIButton *writeToKeyboard = [self makeIconButton:@"flash_to_keyboard" target:aTarget action:@selector(onWriteToKeyboard)];
    UIButton *user = [self makeIconButton:@"icon_user" target:aTarget action:nil];
    UIButton *collapse= [self makeIconButton:@"icon_collapse" target:aTarget action:@selector(toggleSidebar)];

    [buttonStackView addArrangedSubview:add];
    [buttonStackView addArrangedSubview:save];
    [buttonStackView addArrangedSubview:upload];
    [buttonStackView addArrangedSubview:clear];
    [buttonStackView addArrangedSubview:writeToKeyboard];
    [buttonStackView addArrangedSubview:user];
    [buttonStackView addArrangedSubview:collapse];
    
    return bar;
}

// 原來的 expandedBar
//+ (UIView *)expandedBarWithTarget:(id<FloatingSidebarActions>)aTarget
//{
//    UIView *bar = [self baseBar];
//    
//    UIScrollView *scrollView = [[UIScrollView alloc] init];
//    [scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
//    [bar addSubview:scrollView];
//    
//    NSLayoutConstraint *scrollTop = [[scrollView topAnchor] constraintEqualToAnchor:[bar topAnchor]];
//    NSLayoutConstraint *scrollLeading = [[scrollView leadingAnchor] constraintEqualToAnchor:[bar leadingAnchor]];
//    NSLayoutConstraint *scrollTrailing = [[scrollView trailingAnchor] constraintEqualToAnchor:[bar trailingAnchor]];
//    NSLayoutConstraint *scrollBottom = [[scrollView bottomAnchor] constraintEqualToAnchor:[bar bottomAnchor]];
//    
//    UIView *containerView = [[UIView alloc] init];
//    [containerView setTranslatesAutoresizingMaskIntoConstraints:NO];
//    [scrollView addSubview:containerView];
//    
//    UILayoutGuide *contentGuide = [scrollView contentLayoutGuide];
//    UILayoutGuide *frameGuide = [scrollView frameLayoutGuide];
//    
//    NSLayoutConstraint *containerTop = [[containerView topAnchor] constraintEqualToAnchor:[contentGuide topAnchor]];
//    NSLayoutConstraint *containerLeading = [[containerView leadingAnchor] constraintEqualToAnchor:[contentGuide leadingAnchor]];
//    NSLayoutConstraint *containerTrailing = [[containerView trailingAnchor] constraintEqualToAnchor:[contentGuide trailingAnchor]];
//    NSLayoutConstraint *containerBottom = [[containerView bottomAnchor] constraintEqualToAnchor:[contentGuide bottomAnchor]];
//    NSLayoutConstraint *containerWidth = [[containerView widthAnchor] constraintEqualToAnchor:[frameGuide widthAnchor]];
//    
//    NSLayoutConstraint *heightConstratint = [[bar heightAnchor] constraintEqualToAnchor:[containerView heightAnchor]];
//    [heightConstratint setPriority:UILayoutPriorityDefaultHigh];
//    
//    [NSLayoutConstraint activateConstraints:@[
//        scrollTop, scrollLeading, scrollTrailing, scrollBottom,
//        containerTop, containerBottom, containerLeading, containerTrailing, containerWidth,
//        heightConstratint
//    ]];
//            
//    UIStackView *stackView = [self makeStackInto:containerView];
//    
//    UIButton *drag    = [self makeIconButton:@"icon_drag" target:nil action:NULL];
//    [drag setTag:kDragButtonTag];
//    UIButton *add    = [self makeIconButton:@"icon_donut" target:aTarget action:@selector(onTapAddPhantomTap)];
//    UIButton *save    = [self makeIconButton:@"icon_save" target:aTarget action:@selector(onTapSave)];
//    UIButton *upload    = [self makeIconButton:@"icon_upload" target:aTarget action:@selector(onTapUpload)];
//    UIButton *clear   = [self makeIconButton:@"icon_clear" target:aTarget action:@selector(onTapClear)];
//    UIButton *writeToKeyboard   = [self makeIconButton:@"icon_write_to_keyboard" target:aTarget action:@selector(onWriteToKeyboard)];
//    UIButton *collapse= [self makeIconButton:@"icon_collapse" target:aTarget action:@selector(toggleSidebar)];
//
//    [stackView addArrangedSubview:drag];
//    [stackView addArrangedSubview:add];
//    [stackView addArrangedSubview:save];
//    [stackView addArrangedSubview:upload];
//    [stackView addArrangedSubview:clear];
//    [stackView addArrangedSubview:writeToKeyboard];
//    [stackView addArrangedSubview:collapse];
//    
//    return bar;
//}



@end
