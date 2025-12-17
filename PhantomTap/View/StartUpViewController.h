//
//  StartUpViewController.h
//  PhantomTap
//
//  Created by ethanlin on 2025/10/13.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, StartupState)
{
    StartupStateSearching,
    StartupStateDeviceFound,
    StartupStateNoDevice,
};


@interface StartUpViewController : UIViewController

@end
