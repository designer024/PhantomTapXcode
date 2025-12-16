//
//  Utils.m
//  PhantomTap
//
//  Created by ethanlin on 2025/11/25.
//

#import "Utils.h"
#import <CommonCrypto/CommonDigest.h>

@implementation Utils

+ (NSString *)currentTimestampString
{
    NSTimeInterval sec = floor([[NSDate date] timeIntervalSince1970]);
    return [NSString stringWithFormat:@"%.0f", sec];
}

+ (NSString *)currentISO8601String
{
    // 例：2025-11-28T15:50:27+0800
    NSDate *now = [NSDate date];
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    [fmt setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [fmt setTimeZone:[NSTimeZone localTimeZone]];
    [fmt setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    return [fmt stringFromDate:now];
}

+ (NSString *)sha256OfString:(NSString *)aInput
{
    const char *cstr = [aInput cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:strlen(cstr)];
    
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256([data bytes], (CC_LONG)[data length], digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++)
    {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return output;
}


+ (NSString *)urlEncode:(NSString *)aInput
{
    NSCharacterSet *cs = [NSCharacterSet characterSetWithCharactersInString:@"!*'();:@&=+$,/?%#[] "].invertedSet;
    return [aInput stringByAddingPercentEncodingWithAllowedCharacters:cs];
}

+ (nullable NSDictionary *)decodeJWTPayload:(NSString *)aToken
{
    if (!aToken || [aToken length] == 0)
    {
        return nil;
    }
    
    // JWT 結構通常是 Header.Payload.Signature
    NSArray *segments = [aToken componentsSeparatedByString:@"."];
    if ([segments count] < 2)
    {
        return nil;
    }
    
    NSString *payloadSegment = segments[1];
    
    // Base64 URL Safe -> Standard Base64 轉換
    // 1. 將 URL Safe 字元替換回標準 Base64 字元
    NSString *base64String = [[payloadSegment stringByReplacingOccurrencesOfString:@"-" withString:@"+"] stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    
    // 2. 補齊 Padding (Base64 長度必須是 4 的倍數)
    NSInteger padLength = (4 - ([base64String length] % 4)) % 4;
    if (padLength > 0)
    {
        base64String = [base64String stringByPaddingToLength:[base64String length] + padLength withString:@"=" startingAtIndex:0];
    }
    
    // 3. 解碼為 NSData
    NSData *decodeData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    if (!decodeData)
    {
        return nil;
    }
    
    // 4. 解析 JSON 為 Dictionary
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:decodeData options:0 error:&error];
    
    if (error || ![jsonObject isKindOfClass:[NSDictionary class]])
    {
        return nil;
    }
    
    return (NSDictionary *)jsonObject;
    
}

+ (UIColor *)colorFromHex:(uint32_t)aHex alpha:(CGFloat)aAlpha
{
    CGFloat r = ((aHex >> 16) & 0xFF) / 255.0;
    CGFloat g = ((aHex >> 8)  & 0xFF) / 255.0;
    CGFloat b = ( aHex        & 0xFF) / 255.0;
    return [UIColor colorWithRed:r green:g blue:b alpha:aAlpha];
}

///取出 email / password
+ (NSString *)safeText:(UITextField *)aTextField
{
    NSString *t = [aTextField text];
    return t ? [t stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] : @"";
}

@end
