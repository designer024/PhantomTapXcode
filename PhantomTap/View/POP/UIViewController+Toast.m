//
//  UIViewController+Toast.m
//  PhantomTap
//
//  Created by TheUser on 2025/12/16.
//

#import "UIViewController+Toast.h"

@implementation UIViewController (Toast)

- (void)showBottomToast:(NSString *)aMessage
{
    if (![self isViewLoaded]) return;
    
    UILabel *toastLabel = [[UILabel alloc] init];
    [toastLabel setText:aMessage];
    [toastLabel setFont:[UIFont systemFontOfSize:12.0]];
    [toastLabel setTextColor:[[UIColor blackColor] colorWithAlphaComponent:0.8]];
    [toastLabel setBackgroundColor:[UIColor whiteColor]];
    [toastLabel setTextAlignment:NSTextAlignmentCenter];
    [toastLabel setNumberOfLines:0];
    [toastLabel setAlpha:0.0];
    [[toastLabel layer] setCornerRadius:18.0];
    [toastLabel setClipsToBounds:YES];
    
    CGSize maxSize = CGSizeMake([[self view] bounds].size.width - 40, [[self view] bounds].size.height);
    CGSize expectedSize = [toastLabel sizeThatFits:maxSize];
    CGFloat width = expectedSize.width + 40;
    CGFloat height = expectedSize.height + 20;
    
    [toastLabel setFrame:CGRectMake(([[self view] bounds].size.width - width) / 2, [[self view] bounds].size.height - 100, width, height)];
    
    [[self view] addSubview:toastLabel];
    
    [UIView animateWithDuration:0.3 animations:^{
        toastLabel.alpha = 1.0;
        NSLog(@"show toast: %@", aMessage);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:2.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            toastLabel.alpha = 0.0;
        } completion:^(BOOL finished) {
            NSLog(@"hide toast: %@", aMessage);
            [toastLabel removeFromSuperview];
        }];
    }];
}

@end
