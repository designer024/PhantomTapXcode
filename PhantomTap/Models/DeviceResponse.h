//
//  DeviceResponse.h
//  PhantomTap
//
//  Created by ethanlin on 2025/10/15.
//

#import <Foundation/Foundation.h>

@class TapAction;

NS_ASSUME_NONNULL_BEGIN


/// 對應 Kotlin: sealed interface DeviceResponse { MacroContent, MacroResult, Error }
typedef NS_ENUM(NSInteger, DeviceResponseKind)
{
    DeviceResponseKindMacroKeyMapping = 0,     // 讀回指定按鍵內容 (ID=0x03, CMD=0x02)
    DeviceResponseKindMacroContent,         // 之後用
    DeviceResponseKindMacroResult,      // (ID=0x02, CMD=0x03)
    DeviceResponseKindError,
};


@interface DeviceResponse : NSObject

// 共用
@property (nonatomic, readonly) DeviceResponseKind kind;

/// MacroContent / MacroResult 會用到的 keyIndex
@property (nonatomic, readonly) NSInteger keyIndex;

// KeyMapping 用
@property (nonatomic, readonly) NSInteger hidCode;   // HID key code
@property (nonatomic, readonly) NSInteger x;
@property (nonatomic, readonly) NSInteger y;

/// MacroContent 專用：動作清單
@property (nonatomic, copy, readonly, nullable) NSArray<TapAction *> *actions;

/// MacroResult 專用：是否成功
@property (nonatomic, readonly) BOOL success;

/// Error 專用：錯誤訊息
@property (nonatomic, copy, readonly, nullable) NSString *message;


+ (instancetype)keyMappingWithKeyIndex:(NSInteger)aKeyIndex hid:(NSInteger)aHID x:(NSInteger)aX y:(NSInteger)aY;

+ (instancetype)macroResultWithKeyIndex:(NSInteger)aKeyIndex success:(BOOL)aOK;

+ (instancetype)macroContentWithKeyIndex:(NSInteger)aKeyIndex actions:(NSArray<TapAction *> *)aActions;

+ (instancetype)errorWithMessage:(NSString *)aMessage;

@end

NS_ASSUME_NONNULL_END
