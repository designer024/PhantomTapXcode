//
//  HidKeyCodeMap.h
//  PhantomTap
//
//  Created by ethanlin on 2025/10/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HidKeyCodeMap : NSObject

/// 對應「實體鍵標籤」→「鍵位索引」(Key Index)
+ (NSDictionary<NSString *, NSNumber *> *)keyIndexMap;

/// 對應「實體鍵標籤」→「HID Key Code」
+ (NSDictionary<NSString *, NSNumber *> *)hidKeyCodeMap;


/// 便捷查詢
+ (nullable NSNumber *)keyIndexForLabel:(NSString *)aLabel;
+ (nullable NSNumber *)hidCodeForLabel:(NSString *)aLabel;

@end

NS_ASSUME_NONNULL_END
