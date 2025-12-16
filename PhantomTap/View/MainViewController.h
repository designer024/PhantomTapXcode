//
//  MainViewController.h
//  PhantomTap
//
//  Created by ethanlin on 2025/10/13.
//

#import <UIKit/UIKit.h>
#import <PhotosUI/PhotosUI.h>
#import "FloatingSidebarActions.h"
#import "CustomPopupDialog.h"

@interface MainViewController : UIViewController <FloatingSidebarActions, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *contentView;
// @property (weak, nonatomic) IBOutlet UIView *phantomViewContainer;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (nonatomic, strong) NSMutableArray<NSURL *> *jsonFileURLs;
@property (nonatomic, weak) CustomPopupDialog *jsonFilesPopup;

@end

