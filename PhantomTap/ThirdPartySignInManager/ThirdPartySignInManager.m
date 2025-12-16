//
//  ThirdPartySignInManager.m
//  PhantomTap
//
//  Created by ethanlin on 2025/11/25.
//

#import "ThirdPartySignInManager.h"
#import "Utils.h"

API_AVAILABLE(ios(13.0))
@implementation ThirdPartySignInManager

#pragma mark - Delegate
@synthesize signInManagerDelegate;

- (void)setSignInManagerDelegate:(id<SignInManagerDelegate>)aDelegate
{
    self -> signInManagerDelegate = aDelegate;
}


#pragma mark - Apple Sign In
- (void)handleAppleSignInRequest
{
    // 建立 Apple ID 登入請求
    ASAuthorizationAppleIDProvider *appleIDProvider = [ASAuthorizationAppleIDProvider alloc];
    ASAuthorizationAppleIDRequest *request = [appleIDProvider createRequest];
    
    // 請求使用者資訊範圍：全名和電子郵件
    [request setRequestedScopes:@[ASAuthorizationScopeFullName, ASAuthorizationScopeEmail]];
    
    // 建立授權 Controller
    ASAuthorizationController *authorizationController = [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[request]];
    [authorizationController setDelegate:self];
    [authorizationController setPresentationContextProvider:self];
    
    // 執行授權流程
    [authorizationController performRequests];
}

#pragma mark - Google Sign In
- (void)signInWithGoogleFromViewController:(UIViewController *)aPresentingViewController
{
    // 檢查之前是否已經登入過
    if ([[GIDSignIn sharedInstance] hasPreviousSignIn])
    {
        [[GIDSignIn sharedInstance] restorePreviousSignInWithCompletion:^(GIDGoogleUser * _Nullable user, NSError * _Nullable error) {
            if (error)
            {
                if ([self signInManagerDelegate] && [[self signInManagerDelegate] respondsToSelector:@selector(didFailSignInWithError:)])
                {
                    [[self signInManagerDelegate] didFailSignInWithError:error];
                }
                return;
            }
            [self handleGoogleUser:user];
        }];
    }
    else
    {
        // 如果沒有，開始新的登入流程
        [[GIDSignIn sharedInstance] signInWithPresentingViewController:aPresentingViewController completion:^(GIDSignInResult * _Nullable signInResult, NSError * _Nullable error) {
            if (error)
            {
                if ([self signInManagerDelegate] && [[self signInManagerDelegate] respondsToSelector:@selector(didFailSignInWithError:)])
                {
                    [[self signInManagerDelegate] didFailSignInWithError:error];
                }
                return;
            }
            [self  handleGoogleUser:[signInResult user]];
        }];
    }
}

#pragma mark - LINE Sign In

/// sign in with LINE
- (void)signInWithLineFromViewController:(UIViewController *)aPresentingViewController
{
    NSSet *permissions = [NSSet setWithObjects:
                          [LineSDKLoginPermission profile],
                          [LineSDKLoginPermission openID],
                          [LineSDKLoginPermission email], nil];
    
    [[LineSDKLoginManager sharedManager] loginWithPermissions:permissions inViewController:aPresentingViewController completionHandler:^(LineSDKLoginResult *result, NSError *error) {
        if (error)
        {
            if ([self signInManagerDelegate] && [[self signInManagerDelegate] respondsToSelector:@selector(didFailSignInWithError:)])
            {
                [[self signInManagerDelegate] didFailSignInWithError:error];
            }
            return;
        }
        
        if (!result)
        {
            NSError *err = [NSError errorWithDomain:@"ThirdPartySignIn" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"LINE 登入結果為空."}];
            if ([self signInManagerDelegate] && [[self signInManagerDelegate] respondsToSelector:@selector(didFailSignInWithError:)])
            {
                [[self signInManagerDelegate] didFailSignInWithError:err];
            }
            
            return;
        }
        
        NSString *userIdentifier = [[result userProfile] userID];   // 當成 sub
        NSString *fullName = [[result userProfile] displayName];
        NSString *idToken = [[result accessToken] IDTokenRaw];      // JWT
        
        NSString *email = nil;
        NSDictionary *jwtPayload = [Utils decodeJWTPayload:idToken];
        
        if (jwtPayload && jwtPayload[@"email"])
        {
            email = jwtPayload[@"email"];
        }
        
        NSString *picture = nil;
        if ([[result userProfile] pictureURL])
        {
            picture = [[[result userProfile] pictureURL] absoluteString];
        }
        else if (jwtPayload && jwtPayload[@"picture"])
        {
            picture = jwtPayload[@"picture"];
        }
        
        NSLog(@"🟢 LINE userID(sub) = %@", userIdentifier);
        NSLog(@"🟢 LINE email      = %@", email);
        NSLog(@"🟢 LINE name       = %@", fullName);
        NSLog(@"🟢 LINE picture    = %@", picture);
        
        [[APIClient sharedClient] lineSignInWithEmail:email sub:userIdentifier name:fullName picture:picture completion:^(NSString * _Nullable aAccessToken, NSError * _Nullable aError) {
            if (aError)
            {
                NSLog(@"❌ LINE Sign-In API error: %@", [aError localizedDescription]);
                if ([self signInManagerDelegate] && [[self signInManagerDelegate] respondsToSelector:@selector(didFailSignInWithError:)])
                {
                    [[self signInManagerDelegate] didFailSignInWithError:aError];
                }
                return;
            }
            
            if ([self signInManagerDelegate] && [[self signInManagerDelegate] respondsToSelector:@selector(didSignInSuccessfullyWithUserIdentifier:email:fullName:identityToken:)])
            {
                [[self signInManagerDelegate] didSignInSuccessfullyWithUserIdentifier:userIdentifier email:email fullName:fullName identityToken:idToken];
            }
        }];
        
    }];
}


#pragma mark - ASAuthorizationControllerDelegate
// 授權成功的 callback
- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithAuthorization:(ASAuthorization *)authorization
{
    if ([[authorization credential] isKindOfClass:[ASAuthorizationAppleIDCredential class]])
    {
        ASAuthorizationAppleIDCredential *appleIDCredential = (ASAuthorizationAppleIDCredential *)[authorization credential];
        
        NSString *userIdentifier = [appleIDCredential user];  // Apple 的 sub
        NSString *fullName =  [NSPersonNameComponentsFormatter localizedStringFromPersonNameComponents:[appleIDCredential fullName] style:NSPersonNameComponentsFormatterStyleDefault options:0];
        NSString *email = [appleIDCredential email];  // only for first time
        
        // 取得 identityToken，這個 token 通常會傳送到您的後端伺服器進行驗證
        NSData *tokenData = [appleIDCredential identityToken];
        NSString *identityToken = [[NSString alloc] initWithData:tokenData encoding:NSUTF8StringEncoding];
        
        NSLog(@"🍎 Apple userIdentifier (sub): %@", userIdentifier);
        NSLog(@"🍎 Apple email: %@", email);
        NSLog(@"🍎 Apple fullName: %@", fullName);
        NSLog(@"🍎 Apple identityToken length: %lu", (unsigned long)identityToken.length);
        
        [[APIClient sharedClient] appleSignInWithEmail:email sub:userIdentifier identityToken:identityToken completion:^(NSString * _Nullable aAccessToken, NSError * _Nullable aError) {
            if (aError)
            {
                NSLog(@"❌ Apple Sign In API Error: %@", [aError localizedDescription]);
                if ([self signInManagerDelegate] && [[self signInManagerDelegate] respondsToSelector:@selector(didFailSignInWithError:)])
                {
                    [[self signInManagerDelegate] didFailSignInWithError:aError];
                }
                return;
            }
            
            NSLog(@"✅ Apple Sign In success, token = %@", aAccessToken);
            
            if ([self signInManagerDelegate] && [[self signInManagerDelegate] respondsToSelector:@selector(didSignInSuccessfullyWithUserIdentifier:email:fullName:identityToken:)])
            {
                [[self signInManagerDelegate] didSignInSuccessfullyWithUserIdentifier:userIdentifier email:email fullName:fullName identityToken:identityToken];
            }
        }];
    }
}


// 授權失敗的 callback
- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithError:(NSError *)error
{
    if ([self signInManagerDelegate] && [[self signInManagerDelegate] respondsToSelector:@selector(didFailSignInWithError:)])
    {
        [[self signInManagerDelegate] didFailSignInWithError:error];
    }
}

#pragma mark - ASAuthorizationControllerPresentationContextProviding

// 告訴 Apple 登入視窗應該在哪個 window 上顯示
- (ASPresentationAnchor)presentationAnchorForAuthorizationController:(ASAuthorizationController *)controller
{
    for (UIScene *scene in [[UIApplication sharedApplication] connectedScenes])
    {
        if ([scene activationState] == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]])
        {
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            return [[windowScene windows] firstObject];
        }
    }
    
    
    // Fallback for edge cases where no active scene is found, though unlikely.
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [[[UIApplication sharedApplication] windows] firstObject];
    #pragma clang diagnostic pop
}


#pragma mark - 統一處理 Google 使用者資訊的方法
- (void)handleGoogleUser:(GIDGoogleUser *)aUser
{
    if (!aUser)
    {
        NSError *err = [NSError errorWithDomain:@"ThirdPartySignIn" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Google 使用者資料為空."}];
        if ([self signInManagerDelegate] && [[self signInManagerDelegate] respondsToSelector:@selector(didFailSignInWithError:)])
        {
            [[self signInManagerDelegate] didFailSignInWithError:err];
        }
        return;
    }
    
    NSString *sub = [aUser userID];            // 當成後端的 sub
    NSString *email = [[aUser profile] email];            // 可能為 nil (理論上通常有)
    NSString *fullName = [[aUser profile] name];
    NSString *idToken = [[aUser idToken] tokenString];    // 目前只是往 delegate 傳，API 不需要它
    
    NSLog(@"🟢 Google userID(sub) = %@", sub);
    NSLog(@"🟢 Google email      = %@", email);
    NSLog(@"🟢 Google fullName   = %@", fullName);
    
    BOOL emailVerified = YES;
    
    [[APIClient sharedClient] googleSignInWithEmail:email sub:sub emailVerified:emailVerified completion:^(NSString * _Nullable aAccessToken, NSError * _Nullable aError) {
        if (aError)
        {
            NSLog(@"❌ Google Sign-In API error: %@", [aError localizedDescription]);
            if ([self signInManagerDelegate] && [[self signInManagerDelegate] respondsToSelector:@selector(didFailSignInWithError:)])
            {
                [[self signInManagerDelegate] didFailSignInWithError:aError];
            }
            return;
        }
        
        NSLog(@"✅ Google Sign-In success, token = %@", aAccessToken);
        
        if ([self signInManagerDelegate] && [[self signInManagerDelegate] respondsToSelector:@selector(didSignInSuccessfullyWithUserIdentifier:email:fullName:identityToken:)])
        {
            [[self signInManagerDelegate] didSignInSuccessfullyWithUserIdentifier:sub email:email fullName:fullName identityToken:idToken];
        }
    }];
    
    
}


#pragma mark - Biometric Authentication

/// 生物辨識 (Face ID / Touch ID)
- (void)authenticateWithBiometricsWithReason:(NSString *)aReason completion:(void (^)(BOOL success, NSError * _Nullable error))aCompletion
{
    LAContext *context = [[LAContext alloc] init];
    NSError *authError = nil;
    
    // 檢查設備是否支援生物辨識
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError])
    {
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:aReason reply:^(BOOL success, NSError * _Nullable error) {
            
            // 回到主執行緒來執行 completion block，確保 UI 更新安全
            dispatch_async(dispatch_get_main_queue(), ^{
                if (aCompletion)
                {
                    aCompletion(success, error);
                }
            });
        }];
    }
    else
    {
        // 設備不支援生物辨識或未設定
        dispatch_async(dispatch_get_main_queue(), ^{
            if (aCompletion)
            {
                aCompletion(NO, authError);
            }
        });
    }
}

@end
