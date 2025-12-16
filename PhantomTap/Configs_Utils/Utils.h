//
//  Utils.h
//  PhantomTap
//
//  Created by ethanlin on 2025/11/25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Utils : NSObject

+ (NSString *)currentTimestampString;

+ (NSString *)currentISO8601String;

+ (NSString *)sha256OfString:(NSString *)aInput;

+ (NSString *)urlEncode:(NSString *)aInput;

/// 解析 JWT Token 的 Payload 部分並回傳 Dictionary
/// @param aToken JWT 字串 (idToken)
/// @return 解析後的 JSON Dictionary，若失敗則回傳 nil
+ (nullable NSDictionary *)decodeJWTPayload:(NSString *)aToken;

+ (UIColor *)colorFromHex:(uint32_t)aHex alpha:(CGFloat)aAlpha;

+ (NSString *)safeText:(UITextField *)aTextField;

@end

NS_ASSUME_NONNULL_END
