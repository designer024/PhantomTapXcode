//
//  BluetoothPacketBuilder.h
//  PhantomTap
//
//  Created by ethanlin on 2025/10/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BluetoothPacketBuilder : NSObject

/// 建立「設定巨集觸發鍵」的指令,  ((4).  寫入指定巨集之按鍵 (command :4, to 鍵盤))
+ (NSData *)buildSetMacroTriggerKeyPacket:(NSInteger)aKeyIndex;

/// (6).通知寫入巨集完成 (command :6, to 鍵盤)
+ (NSData *)buildNotifyMacroWriteCompletePacketWithKeyIndex:(NSInteger)aKeyIndex totalActions:(NSInteger)aTotalActions;

/// VI.按鍵設定相關 (ID :0x03),
/// 寫入指定按鍵之內容 (command :1, to 鍵盤)
/// aKeyIndex: 鍵位索引
/// aKeyCode : HID key code
/// aX/aY   : 絕對座標（Short, 小端）
+ (NSData *)buildKeyMappingPacketWithKeyIndex:(NSInteger)aKeyIndex keyCode:(NSInteger)aKeyCode x:(NSInteger)aX y:(NSInteger)aY;

/// VI. 按鍵設定相關(ID:0x03):
/// 讀取指定按鍵之內容(command: 2, to 鍵盤)
+ (NSData *)readKeyMappingPacket:(NSInteger)aKeyIndex;


/// 螢幕校正（to 鍵盤）
/// isIOS = YES 時 Data4 = 0x01，否則 0x00（你的 Kotlin 目前固定 0x00，我這裡提供參數）
+ (NSData *)buildScreenCalibrationPacketWithWidth:(NSInteger)aScreenWidth height:(NSInteger)aScreenHeight;


/// 讀取手機螢幕設定 (to 鍵盤)
+ (NSData *)readScreenSetting;

/// 建立「要求讀取指定按鍵之巨集內容」的指令, (1). 要求讀取指定按鍵之巨集內容(command :1, to 鍵盤)
+ (NSData *)buildReadMacroRequestPacket:(NSInteger)aKeyIndex;


@end

NS_ASSUME_NONNULL_END
