//
//  StartUpViewController.m
//  PhantomTap
//
//  Created by ethanlin on 2025/10/13.
//

#import "StartUpViewController.h"
#import "BTManager.h"
#import "MainViewController.h"
#import "CustomButtonStyleHelper.h"

@interface StartUpViewController ()
{
    BTManager *btManager;
    
    CBPeripheral *_foundPeripheral;
    
    BOOL _deviceFound;
}

@property (weak, nonatomic) IBOutlet UIView *searchingLayout;
@property (weak, nonatomic) IBOutlet UIView *noDeviceLayout;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIView *deviceFoundLayout;


@end

@implementation StartUpViewController

#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // [self initUi];
    
    self -> _deviceFound = NO;
    [self applyState:StartupStateSearching maybeWithErrorMessage:@""];
    
    [self initBTManager];
}

- (void)initUi
{
    [CustomButtonStyleHelper applyFilledSmallButtonStyleTo:self -> _retryButton];
    [CustomButtonStyleHelper applyOutlineSmallButtonStyleTo:self -> _skipButton];
    [CustomButtonStyleHelper applyFilledSmallButtonStyleTo:self -> _goToAccountButton];
}

- (void)dealloc
{
    if (btManager)
    {
        btManager.onState = nil;
        btManager.onScan = nil;
        btManager.onConnect = nil;
        btManager.onReady = nil;
        btManager.onData = nil;
    }
}


- (void)initBTManager
{
    __weak typeof(self) weakSelf = self;
    
    btManager = [BTManager shared]; 
    
    btManager.onState = ^(CBManagerState state) {
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) self_ = weakSelf;
            if (!self_) return;
            
            if (state == CBManagerStatePoweredOn)
            {
                self_ -> _deviceFound = NO;
                [self_ applyState:StartupStateSearching maybeWithErrorMessage:@""];
                
                [self_ -> btManager startScanWithNameSubstring:[GlobalConfig Brook_Keyboard_Name] timeout:8];
                
                // 8 秒後檢查：如果還沒找到，就顯示 No Device Layout
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    // 若在 8 秒內有找到，deviceFound 會被 set YES
                    if (!self_ -> _deviceFound)
                    {
                        [self_ applyState:StartupStateNoDevice maybeWithErrorMessage:@"confirm_phantom_tap_is_on_and_nearby"];
                    }
                });
            }
            else
            {
                [self_ applyState:StartupStateNoDevice maybeWithErrorMessage:@"must_be_enabled_to_start_scanning"];
            }
        });
    };
    
    btManager.onScan = ^(CBPeripheral * _Nonnull aPeripheral, NSDictionary * _Nonnull aAdv, NSNumber * _Nonnull aRSSI) {
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) self_ = weakSelf;
            if (!self_) return;
            
            self_ -> _deviceFound = YES;
            self_ -> _foundPeripheral = aPeripheral;
            NSLog(@"onScan, foundPeripheral: %@ %@", [self_ -> _foundPeripheral name], [self_ -> _foundPeripheral identifier]);
            [self_ applyState:StartupStateDeviceFound maybeWithErrorMessage:@""];
            [self_ -> btManager stopScan];
        });
    };
    
    btManager.onConnect = ^(CBPeripheral * _Nonnull aPeripheral, NSError * _Nullable aError) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        
        if (aError)
        {
            NSLog(@"[BLE] connect fail: %@", aError);
        }
        else
        {
            NSLog(@"[BLE] connect to: %@", [aPeripheral name]);
        }
    };
    
    btManager.onReady = ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        
    };
}

/// Retry：回到 Searching，清掉上一輪結果，再掃一次
- (IBAction)onTapRetry:(id)aSender
{
    [self onRetry];
}

- (IBAction)onTapGotoAccountPage:(id)aSender
{
    [self onGotoAccountPage];
}

- (IBAction)onTapSkip:(id)aSender
{
    [self onSkip];
}


#pragma mark - Button Actions

- (void)onGotoAccountPage
{
    if (!_foundPeripheral)
    {
        NSLog(@"[Error] foundPeripheral is null.");
        return;
    }
    
    [btManager connectTo:_foundPeripheral];
    
    UIStoryboard *sb = [self storyboard];
    UIViewController *mainViewController = [sb instantiateViewControllerWithIdentifier:@"SignInViewController"];
    [mainViewController setModalPresentationStyle:UIModalPresentationFullScreen];
    [self presentViewController:mainViewController animated:YES completion:nil];
}

- (void)onRetry
{
    self -> _deviceFound = NO;
    _foundPeripheral = nil;
    [self applyState:StartupStateSearching maybeWithErrorMessage:@""];
    
    [btManager startScanWithNameSubstring:[GlobalConfig Brook_Keyboard_Name] timeout:8];
    
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        typeof(self) self_ = weakSelf;
        if (!self_) return;
        if (!self_ -> _deviceFound)
        {
            [self_ applyState:StartupStateNoDevice maybeWithErrorMessage:@"confirm_phantom_tap_is_on_and_nearby"];
        }
    });
}

- (void)onSkip
{
    _foundPeripheral = nil;
    
    UIStoryboard *sb = [self storyboard];
    UIViewController *mainViewController = [sb instantiateViewControllerWithIdentifier:@"SignInViewController"];
    [mainViewController setModalPresentationStyle:UIModalPresentationFullScreen];
    [self presentViewController:mainViewController animated:YES completion:nil];
}


//---------------------------------------------
//--------------- 小幫手 -----------------------
//---------------------------------------------
- (void)applyState:(StartupState)aState maybeWithErrorMessage:(NSString *)aLocalizedKey
{
    [self -> _searchingLayout setHidden:YES];
    [self -> _noDeviceLayout setHidden:YES];
    [self -> _deviceFoundLayout setHidden:YES];
    
    switch (aState)
    {
        case StartupStateSearching:
        {
            [self -> _searchingLayout setHidden:NO];
        }
            break;
            
        case StartupStateNoDevice:
        {
            CustomPopupDialog *popup = [CustomPopupDialog showInView:[self view] style:CustomPopupDialogStyleDoubleButton title:NSLocalizedString(@"cannot_fine_your_device", nil) message:NSLocalizedString(aLocalizedKey, nil) positiveButtonLabel:NSLocalizedString(@"research", nil) negativeButtonLabel:NSLocalizedString(@"skip", nil) onPositive:nil onNegative:nil];
            
            __weak typeof(self) weakSelf = self;
            __weak CustomPopupDialog *weakPopup = popup;
            
            popup.onPositive = ^{
                [weakPopup dismiss];
                
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                
                [strongSelf onRetry];
                
                NSLog(@"[MainVC] research.");
            };
            
            popup.onNegative = ^{
                [weakPopup dismiss];
                
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                
                [strongSelf onSkip];
                
                NSLog(@"[MainVC] skip.");
            };
        }
            break;
            
        case StartupStateDeviceFound:
        {
            CustomPopupDialog *popup = [CustomPopupDialog showInView:[self view] style:CustomPopupDialogStyleSingleButton title:NSLocalizedString(@"device_found", nil) message:NSLocalizedString(aLocalizedKey, nil) positiveButtonLabel:NSLocalizedString(@"ok", nil) negativeButtonLabel:nil onPositive:nil onNegative:nil];
            
            __weak typeof(self) weakSelf = self;
            __weak CustomPopupDialog *weakPopup = popup;
            
            popup.onPositive = ^{
                [weakPopup dismiss];
                
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                
                [strongSelf onGotoAccountPage];
                
                NSLog(@"[MainVC] research.");
            };
        }
            
            break;
    }
    
    /*
    switch (aState)
    {
        case StartupStateSearching:
            [self -> _searchingLayout setHidden:NO];
            [self -> _noDeviceLayout setHidden:YES];
            [self -> _deviceFoundLayout setHidden:YES];
            break; 
            
        case StartupStateNoDevice:
            [self -> _searchingLayout setHidden:YES];
            [self -> _noDeviceLayout setHidden:NO];
            [self -> _statusLabel setText:NSLocalizedString(aLocalizedKey, nil)];
            [self -> _deviceFoundLayout setHidden:YES];
            break;
            
        case StartupStateDeviceFound:
            [self -> _searchingLayout setHidden:YES];
            [self -> _noDeviceLayout setHidden:YES];
            [self -> _deviceFoundLayout setHidden:NO];
            break;
    }
    */
}

@end
