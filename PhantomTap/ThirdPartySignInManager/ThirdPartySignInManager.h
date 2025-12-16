//
//  ThirdPartySignInManager.h
//  PhantomTap
//
//  Created by ethanlin on 2025/11/25.
//

#import <Foundation/Foundation.h>
#import <GoogleSignIn/GoogleSignIn.h>
#import <AuthenticationServices/AuthenticationServices.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import "APIClient.h"

#import "CustomPopupDialog.h"

@import LineSDK;


NS_ASSUME_NONNULL_BEGIN

#pragma mark - Delegate
@protocol SignInManagerDelegate <NSObject>

- (void)didSignInSuccessfullyWithUserIdentifier:(NSString *)aUserIdentifier email:(nullable NSString *)aEmail fullName:(nullable NSString *)aFullName identityToken:(NSString *)aIdentityToken;

- (void)didFailSignInWithError:(NSError *)aError;

@end


#pragma mark - ThirdPartySignInManager
@interface ThirdPartySignInManager : NSObject <ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding>

@property (weak, nonatomic) id<SignInManagerDelegate> signInManagerDelegate;

- (void)setSignInManagerDelegate:(id<SignInManagerDelegate>)aDelegate;

/// 觸發 Apple 登入流程
- (void)handleAppleSignInRequest;

/// sign in with Google
- (void)signInWithGoogleFromViewController:(UIViewController *)aPresentingViewController;

/// sign in with LINE
- (void)signInWithLineFromViewController:(UIViewController *)aPresentingViewController;


/// 生物辨識 (Face ID / Touch ID)
- (void)authenticateWithBiometricsWithReason:(NSString *)aReason completion:(void (^)(BOOL success, NSError * _Nullable error))aCompletion;

@end

NS_ASSUME_NONNULL_END
