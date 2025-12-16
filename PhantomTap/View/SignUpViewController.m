//
//  SignUpViewController.m
//  PhantomTap
//
//  Created by ethanlin on 2025/11/17.
//

#import "SignUpViewController.h"
#import "APIClient.h"
#import "Utils.h"

@interface SignUpViewController ()

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordConfirmTextField;

@end

@implementation SignUpViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupUi];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [tap setCancelsTouchesInView:NO];
    [[self view] addGestureRecognizer:tap];
}

- (void)setupUi
{
    [self -> _emailTextField setTextColor:[UIColor whiteColor]];
    [self -> _emailTextField setTintColor:[UIColor systemBlueColor]];
    [self -> _emailTextField setPlaceholder:NSLocalizedString(@"email", nil)];
    [self -> _passwordTextField setTextColor:[UIColor whiteColor]];
    [self -> _passwordTextField setTintColor:[UIColor systemBlueColor]];
    [self -> _passwordTextField setPlaceholder:NSLocalizedString(@"password", nil)];
    [self -> _passwordConfirmTextField setTextColor:[UIColor whiteColor]];
    [self -> _passwordConfirmTextField setTintColor:[UIColor systemBlueColor]];
    [self -> _passwordConfirmTextField setPlaceholder:NSLocalizedString(@"password_confirm", nil)];
}

- (void)dismissKeyboard
{
    [[self view] endEditing:YES];
}


#pragma mark - IBAction

- (IBAction)onTapGotoSignIn:(id)aSender
{
    [self goToSignInPage];
}


/// Sign Up
- (IBAction)handleSignUpButtonPress:(id)aSender
{
    NSString *email = [Utils safeText:self -> _emailTextField];
    NSString *password = [Utils safeText:self -> _passwordTextField];
    NSString *passwordConfirmed = [Utils safeText:self -> _passwordConfirmTextField];
    
    if ([email length] == 0 || [password length] == 0 || [passwordConfirmed length] == 0)
    {
        NSLog(@"❌ Email 或密碼為空, %lu, %lu, %lu", [email length], [password length], [passwordConfirmed length]);
        return;
    }
    
    if ([password length] < 8 || [passwordConfirmed length] < 8)
    {
        NSLog(@"❌ 密碼長度至少 8, %lu, %lu", [password length], [passwordConfirmed length]);
        return;
    }
    
    if (![password isEqual:passwordConfirmed])
    {
        NSLog(@"❌ 密碼不一樣");
        return;
    }
    
    NSLog(@"🔧 嘗試註冊：%@", email);
    
    __weak typeof(self) weakSelf = self;
    [[APIClient sharedClient] signUpWithEmail:email password:password completion:^(NSError * _Nullable aError) {
        if (aError)
        {
            NSLog(@"❌ 註冊失敗: %@", [aError localizedDescription]);
        }
        else
        {
            NSLog(@"✅ 註冊成功！");
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf goToSignInPage];
            });
        }
    }];
}


- (void)goToSignInPage
{
    UIStoryboard *sb = [self storyboard];
    UIViewController *mainViewController = [sb instantiateViewControllerWithIdentifier:@"SignInViewController"];
    [mainViewController setModalPresentationStyle:UIModalPresentationFullScreen];
    [self presentViewController:mainViewController animated:YES completion:nil];
}

@end
