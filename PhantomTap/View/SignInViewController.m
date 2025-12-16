//
//  SignInViewController.m
//  PhantomTap
//
//  Created by ethanlin on 2025/11/17.
//

#import "SignInViewController.h"
#import "ThirdPartySignInManager.h"
#import "Utils.h"

typedef NS_ENUM(NSInteger, ThirdPartyProvider)
{
    ThirdPartyProviderNone = 0,
    ThirdPartyProviderApple,
    ThirdPartyProviderGoogle,
    ThirdPartyProviderLine,
};

@interface SignInViewController () <SignInManagerDelegate>
{
    ThirdPartyProvider _currentProvider;
    ThirdPartySignInManager *_thirdPatySignInManager;
    
    CustomPopupDialog *_statusPopup;
}

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation SignInViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _thirdPatySignInManager = [[ThirdPartySignInManager alloc] init];
    [_thirdPatySignInManager setSignInManagerDelegate:self];
    
    [self setupUi];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [tap setCancelsTouchesInView:NO];
    [[self view] addGestureRecognizer:tap];
    // [self testPostAPI];
}

- (void)setupUi
{
    [self -> _emailTextField setTextColor:[UIColor whiteColor]];
    [self -> _emailTextField setTintColor:[UIColor systemBlueColor]];
    [self -> _emailTextField setPlaceholder:NSLocalizedString(@"email", nil)];
    
    [self -> _passwordTextField setTextColor:[UIColor whiteColor]];
    [self -> _passwordTextField setTintColor:[UIColor systemBlueColor]];
    [self -> _passwordTextField setPlaceholder:NSLocalizedString(@"password", nil)];
}

- (void)dismissKeyboard
{
    [[self view] endEditing:YES];
}

#pragma mark - Button Actions

/// sign in with Apple
- (IBAction)signWithApple:(id)aSender
{
    [self handleAppleSignInButtonPress];
}

/// sign in with Google
- (IBAction)signWithGoogle:(id)aSender
{
    [self handleGoogleSignInButtonPress];
}

/// sign in with LINE
- (IBAction)signWithLine:(id)aSender
{
    [self handleLineSignInButtonPress];
}

- (IBAction)signInAsGuest:(id)aSender
{
    [self handleLineSignInAsGuest];
}

/// 還沒有帳號？註冊
- (IBAction)onTapGotoSignUp:(id)aSender
{    
    UIStoryboard *sb = [self storyboard];
    UIViewController *mainViewController = [sb instantiateViewControllerWithIdentifier:@"SignUpViewController"];
    [mainViewController setModalPresentationStyle:UIModalPresentationFullScreen];
    [self presentViewController:mainViewController animated:YES completion:nil];
}

- (IBAction)handleSignInButtonPress:(id)aSender
{
    NSString *email = [Utils safeText:self -> _emailTextField];
    NSString *password = [Utils safeText:self -> _passwordTextField];
    
    if ([email length] == 0 || [password length] == 0)
    {
        NSLog(@"❌ Email 或密碼為空, %lu, %lu", [email length], [password length]);
        return;
    }
    
    if ([password length] < 8)
    {
        NSLog(@"❌ 密碼長度至少 8, %lu", [password length]);
        return;
    }
    
    NSLog(@"🔐 嘗試登入：%@", email);
    
    __weak typeof(self) weakSelf = self;
    [[APIClient sharedClient] signInWithEmail:email password:password completion:^(NSString * _Nullable aAccessToken, NSError * _Nullable aError) {
        if (aError)
        {
            NSLog(@"❌ 登入失敗: %@", [aError localizedDescription]);
        }
        else
        {
            NSLog(@"✅ 登入成功，token = %@", aAccessToken);
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf gotoMainPage];
            });
        }
    }];
}


#pragma mark - Sign In Methods
- (void)handleAppleSignInButtonPress
{
    // [_statusLabel setText:@"正在嘗試 Apple 登入..."];
    NSLog(@"正在嘗試 Apple 登入...");
    _currentProvider = ThirdPartyProviderApple;
    
    [self showLoadingPopupWithTitle:@"登入中..." message:@"正在使用 Apple 驗證身分，請稍候"];

    [_thirdPatySignInManager handleAppleSignInRequest];
}

- (void)handleGoogleSignInButtonPress
{
    NSLog(@"正在嘗試 Google 登入...");
    _currentProvider = ThirdPartyProviderGoogle;
    
    [self showLoadingPopupWithTitle:@"登入中..." message:@"正在使用 Google 驗證身分，請稍候"];
    
    [_thirdPatySignInManager signInWithGoogleFromViewController:self];
}

- (void)handleLineSignInButtonPress
{
    NSLog(@"正在嘗試 LINE 登入...");
    _currentProvider = ThirdPartyProviderLine;
    
    [self showLoadingPopupWithTitle:@"登入中..." message:@"正在使用 LINE 驗證身分，請稍候"];
    
    [_thirdPatySignInManager signInWithLineFromViewController:self];
}

- (void)handleLineSignInAsGuest
{
    [self gotoMainPage];
}


#pragma mark - SignInManagerDelegate
- (void)didSignInSuccessfullyWithUserIdentifier:(NSString *)aUserIdentifier email:(NSString *)aEmail fullName:(NSString *)aFullName identityToken:(NSString *)aIdentityToken
{
    NSLog(@"登入成功！");
    NSLog(@"User ID: %@", aUserIdentifier);
    NSLog(@"Email: %@", aEmail ?: @"N/A"); // 處理 nil 的情況
    NSLog(@"Full Name: %@", aFullName ?: @"N/A");
    NSLog(@"Token: %@", aIdentityToken);
    
    APIClient *client = [APIClient sharedClient];
    __weak typeof(self) weakSelf = self;
    
    // 先顯示「Loading」popup（共用同一個 statusPopup）
    if (!self -> _statusPopup)
    {
        self -> _statusPopup = [CustomPopupDialog showInView:[self view] style:CustomPopupDialogStyleLoading title:NSLocalizedString(@"signing_in", nil) message:@"正在驗證您的帳號，請稍候…" positiveButtonLabel:nil negativeButtonLabel:nil onPositive:nil onNegative:nil];
    }
    else
    {
        // 如果已經有，就更新成 Loading 狀態
        [self -> _statusPopup updateToStyle:CustomPopupDialogStyleLoading title:NSLocalizedString(@"signing_in", nil) message:@"正在驗證您的帳號，請稍候…" positiveButtonLabel:nil negativeButtonLabel:nil onPositive:nil onNegative:nil];
    }
    
    void (^handleError)(NSError *error) = ^(NSError *error)
    {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSString *msg = [error localizedDescription] ?: [NSString stringWithFormat:@"%@, %@", NSLocalizedString(@"sign_in_failed", nil), NSLocalizedString(@"try_again_later", nil)];
        
        if (strongSelf -> _statusPopup)
        {
            [strongSelf -> _statusPopup updateToStyle:CustomPopupDialogStyleSingleButton title:NSLocalizedString(@"sign_in_failed", nil) message:msg positiveButtonLabel:NSLocalizedString(@"ok", nil) negativeButtonLabel:nil onPositive:^{
                [strongSelf -> _statusPopup dismiss];
                strongSelf -> _statusPopup = nil;
            } onNegative:nil];
        }
        else
        {
            [strongSelf showError:msg];
        }
    };
    
    void (^handleSuccess)(NSString *accessToken, NSString *providerName) = ^(NSString *accessToken, NSString *providerName)
    {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [client setAccessToken:accessToken];
        NSLog(@"✅ %@ Sign In OK, accessToken prefix = %@", providerName, [accessToken length] >= 12 ? [accessToken substringToIndex:12] : accessToken);
        
        if (strongSelf -> _statusPopup)
        {
            NSString *msg = [aEmail length] > 0 ? [NSString stringWithFormat:@"%@ 登入成功：\n%@", providerName, aEmail] : [NSString stringWithFormat:@"%@ 登入成功。", providerName];
            
            [strongSelf -> _statusPopup updateToStyle:CustomPopupDialogStyleSingleButton title:NSLocalizedString(@"sign_in_success", nil) message:msg positiveButtonLabel:NSLocalizedString(@"ok", nil) negativeButtonLabel:nil onPositive:^{
                [strongSelf -> _statusPopup dismiss];
                strongSelf -> _statusPopup = nil;
                [strongSelf gotoMainPage];
            } onNegative:nil];
        }
        else
        {
            // 萬一沒 popup，就直接進主畫面
            [strongSelf gotoMainPage];
        }
    };
    
    switch (_currentProvider)
    {
        case ThirdPartyProviderApple:
        {
            NSLog(@"→ 呼叫 Apple API");
            [client appleSignInWithEmail:aEmail sub:aUserIdentifier identityToken:aIdentityToken completion:^(NSString * _Nullable aAccessToken, NSError * _Nullable aError) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (aError)
                    {
                        [weakSelf showError:[aError localizedDescription]];
                        return;
                    }
                    handleSuccess(aAccessToken, @"APPLE");
                    
                    // [client setAccessToken:aAccessToken];
                    // NSLog(@"✅ Apple Sign In OK, accessToken prefix = %@", [aAccessToken substringToIndex:12]);
                    // [weakSelf gotoMainPage];
                });
            }];
        }
            break;
            
        case ThirdPartyProviderGoogle:
        {
            NSLog(@"→ 呼叫 Google API");
            [client googleSignInWithEmail:aEmail sub:aUserIdentifier emailVerified:YES completion:^(NSString * _Nullable aAccessToken, NSError * _Nullable aError) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (aError)
                    {
                        [weakSelf showError:[aError localizedDescription]];
                        return;
                    }
                    
                    handleSuccess(aAccessToken, @"GOOGLE");
                   
                    // [client setAccessToken:aAccessToken];
                    // NSLog(@"✅ Google Sign In OK, accessToken prefix = %@", [aAccessToken substringToIndex:12]);
                    // [weakSelf gotoMainPage];
                });
            }];
        }
            break;
            
        case ThirdPartyProviderLine:
        {
            NSLog(@"→ 呼叫 LINE API");
            [client lineSignInWithEmail:aEmail sub:aUserIdentifier name:aFullName picture:nil completion:^(NSString * _Nullable aAccessToken, NSError * _Nullable aError) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (aError)
                    {
                        [weakSelf showError:[aError localizedDescription]];
                        return;
                    }
                    
                    handleSuccess(aAccessToken, @"LINE");
                    
                    // [client setAccessToken:aAccessToken];
                    // NSLog(@"✅ LINE Sign In OK, accessToken prefix = %@", [aAccessToken substringToIndex:12]);
                    // [weakSelf gotoMainPage];
                });
            }];
        }
            break;
            
        default:
        {
            NSLog(@"❌ Unknown provider");
            NSError *err = [NSError errorWithDomain:@"SignIn" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"未知的登入方式"}];
            handleError(err);
        }
            break;
    }
}


- (void)didFailSignInWithError:(NSError *)aError
{
    NSString *msg = [aError localizedDescription] ?: [NSString stringWithFormat:@"%@, %@", NSLocalizedString(@"sign_in_failed", nil), NSLocalizedString(@"try_again_later", nil)];
    
    if (self -> _statusPopup)
    {
        __weak typeof(self) weakSelf = self;
        
        [_statusPopup updateToStyle:CustomPopupDialogStyleSingleButton title:NSLocalizedString(@"sign_in_failed", nil) message:msg positiveButtonLabel:NSLocalizedString(@"ok", nil) negativeButtonLabel:nil onPositive:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf -> _statusPopup dismiss];
            strongSelf -> _statusPopup = nil;
        } onNegative:nil];
    }
    
    

    
    
    
    /*
    NSLog(@"登入失敗: %@", aError);
    // 檢查錯誤是否為使用者取消
    if ([[aError domain] isEqualToString:ASAuthorizationErrorDomain] && [aError code] == ASAuthorizationErrorCanceled)
    {
        NSLog(@"使用者取消登入");
        return;
    }
    NSLog(@"登入失敗:\n%@", [aError localizedDescription]);
    */
}


#pragma mark - SignInManagerDelegate Helper
- (void)showError:(NSString *)aMessage
{
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"登入失敗"
                                        message:aMessage
                                 preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)gotoMainPage
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"MainViewController"];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}


#pragma mark - Popup Helper

- (void)showLoadingPopupWithTitle:(NSString *)aTitle message:(NSString *)aMessage
{
    if (self -> _statusPopup)
    {
        [self -> _statusPopup dismiss];
        self -> _statusPopup = nil;
    }
    
    self -> _statusPopup = [CustomPopupDialog showLoadingInView:[self view] title:aTitle message:aMessage];
}


















// ----- API Test -----
- (void)testPostAPI {
    NSString *urlString = @"https://www.brookaccessory.com/Converter_API/GetToken";
    NSURL *url = [NSURL URLWithString:urlString];

    // ---- Body (JSON) ----
    NSDictionary *jsonDict = @{
        @"device_uid": @"A1B2C3D4E5F67890A1B2C3D4E5F67890",
        @"device_part_number": @"C24031"
    };

    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:&jsonError];
    if (jsonError) {
        NSLog(@"JSON build error: %@", jsonError.localizedDescription);
        return;
    }

    // ---- Request ----
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = jsonData;

    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    // ---- Session ----
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData * _Nullable data,
                                   NSURLResponse * _Nullable response,
                                   NSError * _Nullable error)
    {
        if (error) {
            NSLog(@"POST Error: %@", error.localizedDescription);
            return;
        }

        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
        NSLog(@"POST Success (status code: %ld)", (long)httpResp.statusCode);

        if (data) {
            NSString *respStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"Response body: %@", respStr);
        }
    }];

    [task resume];
}



#pragma mark - Private Color Helpers

/// #091522 (input 背景色)
+ (UIColor *)inputBackgroundColor
{
    return [Utils colorFromHex:0x091522 alpha:1.0];
}

@end
