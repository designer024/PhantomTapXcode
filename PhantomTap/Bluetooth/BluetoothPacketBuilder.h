//
//  BluetoothPacketBuilder.h
//  PhantomTap
//
//  Created by ethanlin on 2025/10/14.
//

#import <Foundation/Foundation.h>
#import "KeymapModels.h"

NS_ASSUME_NONNULL_BEGIN

@interface BluetoothPacketBuilder : NSObject

#pragma mark - Macro Related (ID: 0x02)

/// (4). 寫入指定巨集之按鍵 (command :4, to 鍵盤)
/// @param aKeyIndex 指定的 key index
/// @param aIsContinuous YES=連續執行, NO=單次執行
/// @param aMacroName 巨集名稱，最多 32 bytes (ASCII)
+ (NSData *)buildSetMacroTriggerKeyPacket:(NSInteger)aKeyIndex isContinuous:(BOOL)aIsContinuous macroName:(NSString *)aMacroName;

/// (5). 寫入巨集內容 (command :5, to 鍵盤)
/// 一個封包最多 10 筆步驟
/// @param aPacketIndex 封包索引 (1~65535)
/// @param aActions 動作列表 (TapAction)，最多 10 筆
+ (NSData *)buildWriteMacroContentPacketWithPacketIndex:(NSInteger)aPacketIndex actions:(NSArray<TapAction *> *)aActions;

/// (6).通知寫入巨集完成 (command :6, to 鍵盤)
+ (NSData *)buildNotifyMacroWriteCompletePacketWithKeyIndex:(NSInteger)aKeyIndex totalActions:(NSInteger)aTotalActions;

/// (1). 要求讀取指定按鍵之巨集內容(command :1, to 鍵盤)
+ (NSData *)buildReadMacroRequestPacket:(NSInteger)aKeyIndex;


#pragma mark - Key Mapping Related (ID: 0x03)

/// VI.按鍵設定相關 (ID :0x03),
/// 寫入指定按鍵之內容 (command :1, to 鍵盤)
/// aKeyIndex: 鍵位索引
/// aKeyCode : HID key code
/// aX/aY   : 絕對座標（Short, 小端）
+ (NSData *)buildKeyMappingPacketWithKeyIndex:(NSInteger)aKeyIndex keyCode:(NSInteger)aKeyCode x:(NSInteger)aX y:(NSInteger)aY;

/// VI. 按鍵設定相關(ID:0x03):
/// 讀取指定按鍵之內容(command: 2, to 鍵盤)
+ (NSData *)readKeyMappingPacket:(NSInteger)aKeyIndex;


/// 啟用「可觸發巨集」的 key mapping (測試用/特殊用途)
+ (NSData *)buildEnableMacroTriggerKeyPacket:(NSInteger)aKeyIndex;


#pragma mark - Screen Calibration (ID: 0x05)

/// 螢幕校正（to 鍵盤）
/// isIOS = YES 時 Data4 = 0x01，否則 0x00（你的 Kotlin 目前固定 0x00，我這裡提供參數）
+ (NSData *)buildScreenCalibrationPacketWithWidth:(NSInteger)aScreenWidth height:(NSInteger)aScreenHeight;

/// 讀取手機螢幕設定 (to 鍵盤)
+ (NSData *)readScreenSetting;


#pragma mark - Accessories (ID: 0x01)

/// 請求周邊列表 (Command: 0x01)
+ (NSData *)buildRequestAccessoriesList;



@end

NS_ASSUME_NONNULL_END
