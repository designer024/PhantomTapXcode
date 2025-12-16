//
//  APIClient.m
//  PhantomTap
//
//  Created by ethanlin on 2025/11/25.
//

#import "APIClient.h"

/// AuthAPIAccessToken
static NSString * const kAccessTokenUserDefaultsKey = @"AuthAPIAccessToken";
/// APIClientErrorDomain
static NSString * const kAPIClientErrorDomain = @"APIClientErrorDomain";


@interface APIClient ()
{
    NSString *baseURL;
    
    NSURLSession *session;
    NSString * _Nullable accessToken;
}

@end


@implementation APIClient

#pragma mark - Singleton
+ (instancetype)sharedClient
{
    static APIClient *sSharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sSharedClient = [[APIClient alloc] initPrivate];
    });
    return sSharedClient;
}
// 私有 init，避免外面亂 new
- (instancetype)initPrivate
{
    self = [super init];
    if (self)
    {
        baseURL = @"https://api.ethanlin.online";
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        session = [NSURLSession sessionWithConfiguration:config];
        
        // 從 UserDefaults 載入之前存的 accessToken
        self -> accessToken = [[NSUserDefaults standardUserDefaults] stringForKey:kAccessTokenUserDefaultsKey];
    }
    return self;
}
// 防止外面直接用 init
- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton" reason:@"Please using [APIClient sharedClient]" userInfo:nil];
    return nil;
}


#pragma mark - get, set
- (NSString *)getBaseURL
{
    return self -> baseURL;
}
- (void)setBaseURL:(NSString *)aURL
{
    self -> baseURL = [aURL copy];
}

- (NSString  * _Nullable)getAccessToken
{
    return self -> accessToken;
}
- (void)setAccessToken:(nullable NSString *)aToken
{
    self -> accessToken = [aToken copy];
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (aToken)
    {
        [ud setObject:aToken forKey:kAccessTokenUserDefaultsKey];
    }
    else
    {
        [ud removeObjectForKey:kAccessTokenUserDefaultsKey];
    }
    [ud synchronize];
}

#pragma mark - Public APIs

/// Sign-in with Email / password
- (void)signInWithEmail:(NSString *)aEmail password:(NSString *)aPassword completion:(void (^)(NSString * _Nullable aAccessToken, NSError * _Nullable aError))aCompletion
{
    if ([baseURL length] == 0)
    {
        if (aCompletion)
        {
            NSError *err = [NSError errorWithDomain:kAPIClientErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Base URL 尚未設定."}];
            aCompletion(nil, err);
        }
        return;
    }
    
    NSDictionary *body = @{
        @"email": aEmail ?: @"",
        @"password": aPassword ?: @""
    };
    
    NSURLRequest *req = [self requestWithPath:@"auth/sign-in" method:@"POST" jsonBody:body];
    [self sendJSONRequest:req completion:^(NSDictionary * _Nullable json, NSHTTPURLResponse * _Nullable httpResp, NSError * _Nullable error) {
        if (error)
        {
            aCompletion(nil, error);
            return;
        }
        
        if ([httpResp statusCode] >= 200 && [httpResp statusCode] < 300)
        {
            NSString *token = json[@"access_token"];
            if ([token length] > 0)
            {
                [self setAccessToken:token];
                aCompletion(token, nil);
            }
            else
            {
                NSError *err = [NSError errorWithDomain:kAPIClientErrorDomain code:httpResp.statusCode userInfo:@{NSLocalizedDescriptionKey: @"Missing access_token"}];
                aCompletion(nil, err);
            }
        }
        else
        {
            NSString *msg = json[@"detail"] ?: @"Login failed";
            NSError *err = [NSError errorWithDomain:kAPIClientErrorDomain code:httpResp.statusCode userInfo:@{NSLocalizedDescriptionKey: msg}];
            aCompletion(nil, err);
        }
    }];
}

/// Sign-up with Email / password
- (void)signUpWithEmail:(NSString *)aEmail password:(NSString *)aPassword completion:(void (^)(NSError * _Nullable aError))aCompletion
{
    if ([baseURL length] == 0)
    {
        if (aCompletion)
        {
            NSError *err = [NSError errorWithDomain:kAPIClientErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Base URL 尚未設定."}];
            aCompletion(err);
        }
        return;
    }
    
    NSDictionary *body = @{
        @"email": aEmail ?: @"",
        @"password": aPassword ?: @""
    };
    NSURLRequest *req = [self requestWithPath:@"auth/sign-up" method:@"POST" jsonBody:body];
    [self sendJSONRequest:req completion:^(NSDictionary * _Nullable json, NSHTTPURLResponse * _Nullable httpResp, NSError * _Nullable error) {
        if (error)
        {
            aCompletion(error);
            return;
        }
        
        if ([httpResp statusCode] >= 200 && [httpResp statusCode] < 300)
        {
            aCompletion(nil);
        }
        else
        {
            NSString *msg = json[@"detail"] ?: @"Login failed";
            NSError *err = [NSError errorWithDomain:kAPIClientErrorDomain code:httpResp.statusCode userInfo:@{NSLocalizedDescriptionKey: msg}];
            aCompletion(err);
        }
    }];
}

/// Google sign-in
- (void)googleSignInWithEmail:(NSString *)aEmail sub:(NSString *)aSub emailVerified:(BOOL)aEmailVerified completion:(void (^)(NSString * _Nullable aAccessToken, NSError * _Nullable aError))aCompletion
{
    if ([baseURL length] == 0)
    {
        if (aCompletion)
        {
            NSError *err = [NSError errorWithDomain:kAPIClientErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Base URL 尚未設定."}];
            aCompletion(nil, err);
        }
        return;
    }
    
    NSDictionary *body = @{
        @"email": aEmail ?: @"",
        @"sub": aSub ?: @"",
        @"email_verified": @(aEmailVerified)
    };
    
    NSURLRequest *req = [self requestWithPath:@"auth/google-sign-in" method:@"POST" jsonBody:body];
    [self sendJSONRequest:req completion:^(NSDictionary * _Nullable json, NSHTTPURLResponse * _Nullable httpResp, NSError * _Nullable error) {
        if (error)
        {
            aCompletion(nil, error);
            return;
        }
        
        NSInteger code = [httpResp statusCode];
        if (code >= 200 && code < 300)
        {
            NSString *token = json[@"access_token"];
            if ([token length] > 0)
            {
                [self setAccessToken:token];
                aCompletion(token, nil);
            }
            else
            {
                NSError *err = [NSError errorWithDomain:kAPIClientErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: @"Missing access_token in response."}];
                aCompletion(nil, err);
            }
        }
        else
        {
            NSString *msg = json[@"detail"] ?: [NSString stringWithFormat:@"HTTP %ld", (long)code];
            NSError *err = [NSError errorWithDomain:kAPIClientErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: msg}];
            aCompletion(nil, err);
        }
    }];
}

/// Apple sign-in
- (void)appleSignInWithEmail:(nullable NSString *)aEmail sub:(NSString *)aSub identityToken:(NSString *)aIdentityToken completion:(void (^)(NSString * _Nullable aAccessToken, NSError * _Nullable aError))aCompletion
{
    if ([baseURL length] == 0)
    {
        if (aCompletion)
        {
            NSError *err = [NSError errorWithDomain:kAPIClientErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Base URL 尚未設定."}];
            aCompletion(nil, err);
        }
        return;
    }
    
    if ([aSub length] == 0 || [aIdentityToken length] == 0)
    {
        if (aCompletion)
        {
            NSError *err = [NSError errorWithDomain:kAPIClientErrorDomain code:400 userInfo:@{NSLocalizedDescriptionKey: @"Missing sub or identity_token."}];
            aCompletion(nil, err);
        }
        return;
    }
    
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"sub"] = aSub;
    body[@"identity_token"] = aIdentityToken;
    if ([aEmail length] > 0)
    {
        body[@"email"] = aEmail;
    }
    
    NSLog(@"📤 Apple Sign-In payload = %@", body);
    
    NSURLRequest *req = [self requestWithPath:@"auth/apple-sign-in" method:@"POST" jsonBody:body];
    [self sendJSONRequest:req completion:^(NSDictionary * _Nullable json, NSHTTPURLResponse * _Nullable httpResp, NSError * _Nullable error) {
        if (error)
        {
            aCompletion(nil, error);
            return;
        }
        
        NSInteger code = [httpResp statusCode];
        if (code >= 200 && code < 300)
        {
            NSString *token = json[@"access_token"];
            if ([token length] > 0)
            {
                [self setAccessToken:token];
                aCompletion(token, nil);
            }
            else
            {
                NSError *err = [NSError errorWithDomain:kAPIClientErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: @"Missing access_token in response."}];
                aCompletion(nil, err);
            }
        }
        else
        {
            NSString *msg = json[@"detail"] ?: [NSString stringWithFormat:@"HTTP %ld", (long)code];
            NSError *err = [NSError errorWithDomain:kAPIClientErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: msg}];
            aCompletion(nil, err);
        }
    }];
}

/// LINE sign-in
- (void)lineSignInWithEmail:(nullable NSString *)aEmail sub:(NSString *)aSub name:(nullable NSString *)aName picture:(nullable NSString *)aPicture completion:(void (^)(NSString * _Nullable aAccessToken, NSError * _Nullable aError))aCompletion
{
    if ([baseURL length] == 0)
    {
        if (aCompletion)
        {
            NSError *err = [NSError errorWithDomain:kAPIClientErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Base URL 尚未設定."}];
            aCompletion(nil, err);
        }
        return;
    }
    
    NSMutableDictionary *body = [@{@"sub": aSub ?: @""} mutableCopy];
    if (aEmail) body[@"email"] = aEmail;
    if (aName) body[@"name"] = aName;
    if (aPicture) body[@"picture"] = aPicture;
    
    NSURLRequest *req = [self requestWithPath:@"auth/line-sign-in" method:@"POST" jsonBody:body];
    [self sendJSONRequest:req completion:^(NSDictionary * _Nullable json, NSHTTPURLResponse * _Nullable httpResp, NSError * _Nullable error) {
        if (error)
        {
            aCompletion(nil, error);
            return;
        }
        
        NSInteger code = [httpResp statusCode];
        if (code >= 200 && code < 300)
        {
            NSString *token = json[@"access_token"];
            if ([token length] > 0)
            {
                [self setAccessToken:token];
                aCompletion(token, nil);
            }
            else
            {
                NSError *err = [NSError errorWithDomain:kAPIClientErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: @"Missing access_token in response."}];
                aCompletion(nil, err);
            }
        }
        else
        {
            NSString *msg = json[@"detail"] ?: [NSString stringWithFormat:@"HTTP %ld", (long)code];
            NSError *err = [NSError errorWithDomain:kAPIClientErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: msg}];
            aCompletion(nil, err);
        }
    }];
}


/// 取得 /auth/me
- (void)getMeWithCompletion:(void (^)(NSDictionary * _Nullable aJSON, NSError * _Nullable aError))aCompletion
{
    if ([self -> accessToken length] == 0)
    {
        if (aCompletion)
        {
            NSError *err = [NSError errorWithDomain:kAPIClientErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"No access token."}];
        }
        return;
    }
    
    NSURLRequest *req = [self requestWithPath:@"auth/me" method:@"GET" jsonBody:nil];
    [self sendJSONRequest:req completion:^(NSDictionary * _Nullable json, NSHTTPURLResponse * _Nullable httpResp, NSError * _Nullable error) {
        if (error)
        {
            if (aCompletion) aCompletion(nil, error);
            return;
        }
        
        NSInteger code = [httpResp statusCode];
        if (code >= 200 & code < 300)
        {
            if (aCompletion) aCompletion(json, nil);
        }
        else
        {
            NSString *msg = json[@"detail"] ?: [NSString stringWithFormat:@"HTTP %ld", (long)code];
            NSError *err = [NSError errorWithDomain:kAPIClientErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: msg}];
            if (aCompletion) aCompletion(nil, err);
        }
    }];
}


#pragma mark - Internal helpers

- (NSURLRequest *)requestWithPath:(NSString *)aPath method:(NSString *)aMethod jsonBody:(nullable NSDictionary *)aJsonBody
{
    if ([baseURL length] == 0)
    {
        return nil;
    }
    
    // NSString *urlString = [NSString stringWithFormat:@"%@/%@", self -> baseURL, aPath];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", self -> baseURL, aPath]];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:aMethod ?: @"GET"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    if ([self -> accessToken length] > 0)
    {
        NSString *auth = [NSString stringWithFormat:@"Bearer %@", self -> accessToken];
        [req setValue:auth forHTTPHeaderField:@"Authorization"];
    }
    
    if (aJsonBody)
    {
        NSError *err = nil;
        NSData *body = [NSJSONSerialization dataWithJSONObject:aJsonBody options:0 error:&err];
        if (!err)
        {
            [req setHTTPBody:body];
        }
    }
    
    return req;
}


- (void)sendJSONRequest:(NSURLRequest *)aRequest completion:(void (^)(NSDictionary * _Nullable json, NSHTTPURLResponse * _Nullable httpResp, NSError * _Nullable error))aCompletion
{
    NSURLSessionDataTask *task = [self -> session dataTaskWithRequest:aRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                aCompletion(nil, (NSHTTPURLResponse *)response, error);
            });
            return;
        }
        
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
        NSDictionary *json = nil;
        
        if ([data length] > 0)
        {
            NSError *jsonError = nil;
            id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (!jsonError && [obj isKindOfClass:[NSDictionary class]])
            {
                json = (NSDictionary *)obj;
            }
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            aCompletion(json, httpResp, nil);
        });
    }];
    [task resume];
}


@end
