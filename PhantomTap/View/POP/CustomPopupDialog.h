//
//  SignInStatusPopupView.h
//  PhantomTap
//
//  Created by ethanlin on 2025/11/28.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@class LottieView;

typedef NS_ENUM(NSInteger, CustomPopupDialogStyle)
{
    CustomPopupDialogStyleLoading = 0,   // 只有 Lottie loading、無按鈕
    CustomPopupDialogStyleSingleButton,  // 一個 OK 按鈕
    CustomPopupDialogStyleDoubleButton   // 兩個按鈕（Positive / Negative）
};

typedef void(^CustomPopupHandler)(void);

@interface CustomPopupDialog : UIView

/// 目前樣式（Loading / Single / Double），由 configure / update 設定
@property (nonatomic, assign) CustomPopupDialogStyle style;

/// 按下 Positive / Negative 時執行的 callback（由外面指定，預設為 nil）
@property (nonatomic, copy, nullable) CustomPopupHandler onPositive;
@property (nonatomic, copy, nullable) CustomPopupHandler onNegative;

/// 方便外部想客製卡片（加額外 subview 等）
- (UIView *)cardView;

/// 顯示「Loading」彈窗（只有 Lottie + 標題/訊息，無按鈕）
+ (instancetype)showLoadingInView:(UIView *)aParentView
                            title:(nullable NSString *)aTitle
                          message:(nullable NSString *)aMessage;

/// 一般彈窗（單顆或雙顆按鈕）
+ (instancetype)showInView:(UIView *)aParentView
                     style:(CustomPopupDialogStyle)aStyle
                     title:(nullable NSString *)aTitle
                   message:(nullable NSString *)aMessage
       positiveButtonLabel:(nullable NSString *)aPositiveButtonLabel
       negativeButtonLabel:(nullable NSString *)aNegativeButtonLabel
                 onPositive:(nullable CustomPopupHandler)aOnPositiveHandler
                 onNegative:(nullable CustomPopupHandler)aOnNegativeHanbler;

/// 從「Loading」或其它狀態更新到新的 Style（通常是 Loading → 結果視窗）
- (void)updateToStyle:(CustomPopupDialogStyle)aStyle
                title:(nullable NSString *)aTitle
              message:(nullable NSString *)aMessage
  positiveButtonLabel:(nullable NSString *)aPositiveButtonLabel
  negativeButtonLabel:(nullable NSString *)aNegativeButtonLabel
           onPositive:(nullable CustomPopupHandler)aOnPositiveHandler
           onNegative:(nullable CustomPopupHandler)aOnNegativeHanbler;

/// 關閉視窗
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
