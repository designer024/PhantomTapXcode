//
//  PhantomTapView.h
//  PhantomTap
//
//  Created by ethanlin on 2025/10/20.
//

#import <UIKit/UIKit.h>
#import "KeymapModels.h"

NS_ASSUME_NONNULL_BEGIN

@class PhantomTapView;

typedef void (^PhantomTapViewSelectedHandler)(PhantomTapView *aPhantomTapView);
typedef void (^PhantomTapViewDeleteHandler)(PhantomTapView *aPhantomTapView);
typedef void (^PhantomTapViewPositionCommittedHandler)(PhantomTapView *aPhantomTapView);

@interface PhantomTapView : UIView

@property (nonatomic, strong, readonly) TapAction *action;
@property (nonatomic, assign) BOOL viewSelected;

/// 建構：提供模型與回呼（任何一個可為 nil）
- (instancetype)initWithAction:(TapAction *)aAction
                onSelected:(nullable PhantomTapViewSelectedHandler)aOnSelected
                onDelete:(nullable PhantomTapViewDeleteHandler)aOnDelete
              onPositionCommed:(nullable PhantomTapViewPositionCommittedHandler)aOnPositionCommitted NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFrame:(CGRect)aFrame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aCoder NS_UNAVAILABLE;


/// 更新顯示用 key，並寫回 action.keyCode（空字串視為 @"null"）
- (void)updateKeyCode:(NSString *)aKey;


/// 取得「螢幕座標系」下的視覺中心（for 送封包）
- (CGPoint)centerOnScreen;


/// 夾回容器可見範圍（預設使用 superview.safeAreaLayoutGuide.frame）
- (void)clampIntoSuperviewBounds;

@end

NS_ASSUME_NONNULL_END
