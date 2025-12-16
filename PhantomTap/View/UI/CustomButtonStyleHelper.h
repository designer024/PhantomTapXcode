//
//  CustomButtonStyleHelper.h
//  PhantomTap
//
//  Created by TheUser on 2025/12/11.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomButtonStyleHelper : NSObject

/// Brook 小按鈕用的藍綠色 #00C3D0
+ (UIColor *)brookCyanColor;

+ (UIImage *)imageWithColor:(UIColor *)aColor;

/// 實心膠囊按鈕（像 StartUpViewController 的 Re-search / GotoAccount）
+ (void)applyFilledSmallButtonStyleTo:(UIButton *)aButton;

/// 空心膠囊按鈕（像 Skip）
+ (void)applyOutlineSmallButtonStyleTo:(UIButton *)aButton;



@end

NS_ASSUME_NONNULL_END
