//
//  FloatingSidebarBuilder.h
//  PhantomTap
//
//  Created by ethanlin on 2025/10/14.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FloatingSidebarActions.h"

NS_ASSUME_NONNULL_BEGIN

@interface FloatingSidebarBuilder : NSObject

+ (UIView *)collapsedBarWithTarget:(id<FloatingSidebarActions>)aTarget;
+ (UIView *)expandedBarWithTarget:(id<FloatingSidebarActions>)aTarget;

+ (NSInteger)getDragButtonTag;

@end

NS_ASSUME_NONNULL_END
