//
//  UIViewController+Toast.h
//  PhantomTap
//
//  Created by TheUser on 2025/12/16.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (Toast)

- (void)showBottomToast:(NSString *)aMessage;

@end

NS_ASSUME_NONNULL_END
