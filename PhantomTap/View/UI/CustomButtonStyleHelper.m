//
//  CustomButtonStyleHelper.m
//  PhantomTap
//
//  Created by TheUser on 2025/12/11.
//

#import "CustomButtonStyleHelper.h"

@implementation CustomButtonStyleHelper

/// Brook 小按鈕用的藍綠色 #00C3D0
+ (UIColor *)brookCyanColor
{
    return [UIColor colorWithRed:0.0/255.0 green:195.0/255.0 blue:208.0/255.0 alpha:1.0];
}

+ (UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

/// 實心膠囊按鈕（像 StartUpViewController 的 Re-search / GotoAccount）
+ (void)applyFilledSmallButtonStyleTo:(UIButton *)aButton
{
    if (!aButton) return;
    if ([aButton bounds].size.height <= 0.0) return;
    
    // 背景色
    [aButton setBackgroundColor:[self brookCyanColor]];
    
    // 膠囊圓角：高度的一半
    [[aButton layer] setCornerRadius:CGRectGetHeight([aButton bounds]) / 2.0];
    [[aButton layer] setMasksToBounds:YES];
    
    // 文字樣式
    [aButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [[aButton titleLabel] setFont:[UIFont fontWithName:@"NotoSansTC-Black" size:14.0]];
    
    // 按下去稍微變暗
    UIColor *pressedColor = [[self brookCyanColor] colorWithAlphaComponent:0.7];
    UIImage *normalBg = [self imageWithColor:[self brookCyanColor]];
    UIImage *highlightBg = [self imageWithColor:pressedColor];
    [aButton setBackgroundImage:normalBg forState:UIControlStateNormal];
    [aButton setBackgroundImage:highlightBg forState:UIControlStateHighlighted];
}

/// 空心膠囊按鈕（像 Skip）
+ (void)applyOutlineSmallButtonStyleTo:(UIButton *)aButton
{
    if (!aButton) return;
    if ([aButton bounds].size.height <= 0.0) return;
    
    // 白底
    [aButton setBackgroundColor:[UIColor whiteColor]];
    
    // 膠囊圓角：高度的一半
    [[aButton layer] setCornerRadius:CGRectGetHeight([aButton bounds]) / 2.0];
    [[aButton layer] setMasksToBounds:YES];
    
    // 邊框
    [[aButton layer] setBorderWidth:2.0];
    [[aButton layer] setBorderColor:[self brookCyanColor].CGColor];
    
    // 文字顏色
    [aButton setTitleColor:[self brookCyanColor] forState:UIControlStateNormal];
    [[aButton titleLabel] setFont:[UIFont fontWithName:@"NotoSansTC-Black" size:14.0]];
    
    // 按下去讓底色稍微變淺一點
    UIColor *pressedColor = [[UIColor whiteColor] colorWithAlphaComponent:0.8];
    UIImage *normalBg = [self imageWithColor:[UIColor whiteColor]];
    UIImage *highlightBg = [self imageWithColor:pressedColor];
    [aButton setBackgroundImage:normalBg forState:UIControlStateNormal];
    [aButton setBackgroundImage:highlightBg forState:UIControlStateHighlighted];
    
    // [aButton setBackgroundColor:[UIColor clearColor]];
}

@end
