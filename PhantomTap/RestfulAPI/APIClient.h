//
//  APIClient.h
//  PhantomTap
//
//  Created by ethanlin on 2025/11/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface APIClient : NSObject

+ (instancetype)sharedClient;

- (NSString *)getBaseURL;
- (void)setBaseURL:(NSString *)aURL;

- (NSString  * _Nullable)getAccessToken;
- (void)setAccessToken:(nullable NSString *)aToken;


/// Sign-in with Email / password
- (void)signInWithEmail:(NSString *)aEmail password:(NSString *)aPassword completion:(void (^)(NSString * _Nullable aAccessToken, NSError * _Nullable aError))aCompletion;

/// Sign-up with Email / password
- (void)signUpWithEmail:(NSString *)aEmail password:(NSString *)aPassword completion:(void (^)(NSError * _Nullable aError))aCompletion;


/// Google sign-in
- (void)googleSignInWithEmail:(NSString *)aEmail sub:(NSString *)aSub emailVerified:(BOOL)aEmailVerified completion:(void (^)(NSString * _Nullable aAccessToken, NSError * _Nullable aError))aCompletion;

/// Apple sign-in
- (void)appleSignInWithEmail:(nullable NSString *)aEmail sub:(NSString *)aSub identityToken:(NSString *)aIdentityToken completion:(void (^)(NSString * _Nullable aAccessToken, NSError * _Nullable aError))aCompletion;

/// LINE sign-in
- (void)lineSignInWithEmail:(nullable NSString *)aEmail sub:(NSString *)aSub name:(nullable NSString *)aName picture:(nullable NSString *)aPicture completion:(void (^)(NSString * _Nullable aAccessToken, NSError * _Nullable aError))aCompletion;


/// 取得 /auth/me
- (void)getMeWithCompletion:(void (^)(NSDictionary * _Nullable aJSON, NSError * _Nullable aError))aCompletion;

@end

NS_ASSUME_NONNULL_END
