//
//  BluetoothPacketBuilder.m
//  PhantomTap
//
//  Created by ethanlin on 2025/10/14.
//

#import "BluetoothPacketBuilder.h"

@implementation BluetoothPacketBuilder


#pragma mark - Constants


/** 讀取(to鍵盤) 0x04 */
static const uint8_t HEADER_READ_TO_DEVICE = 0x04;
/** 寫入(to鍵盤) 0x05 */
static const uint8_t HEADER_WRITE_TO_DEVICE = 0x05;
/** 通知(to app) 0x06 */
static const uint8_t HEADER_RESPONSE_FROM_DEVICE = 0x06;
/** 指示(to app)  0x07*/
static const uint8_t HEADER_INDICATE_TO_APP = 0x07;

/** 滑鼠配對相關 0x01*/
static const uint8_t ID_ACCESSORIES = 0x01;
/** 鍵鼠巨集相關 0x02 */
static const uint8_t ID_MACRO = 0x02;
/** 按鍵設定的 ID 0x03 */
static const uint8_t ID_KEY_SETTING = 0x03;
/** 螢幕校正的 ID 0x05 */
static const uint8_t ID_CALIBRATION = 0x05;


/** 寫入按鍵映射的 Command 0x01 */
static const uint8_t CMD_WRITE_KEY_MAPPING = 0x01;
/** 回傳周邊 to app 0x02 */
static const uint8_t CMD_RETURN_TO_APP = 0x02;

/** 0x02 */
static const uint8_t CMD_READ_MACRO_RESPONSE = 0x02;
/** 0x03 */
static const uint8_t CMD_MACRO_RESULT_RESPONSE = 0x03;
/** 0x05 */
static const uint8_t CMD_WRITE_MACRO_CONTENT = 0x05;
/** 設定巨集觸發鍵的((4).    寫入指定巨集之按鍵 (command :4, to 鍵盤))  0x04  */
static const uint8_t CMD_SET_MACRO_TRIGGER_KEY = 0x04;
/** 0x01 */
static const uint8_t CMD_READ_MACRO_REQUEST = 0x01;
/** 寫入校正的 Command  0x01 */
static const uint8_t CMD_WRITE_CALIBRATION = 0x01;
/** (6).通知寫入巨集完成 (command :6, to 鍵盤)  0x06  */
static const uint8_t CMD_NOTIFY_MACRO_WRITE_COMPLETE = 0x06;


static const uint8_t CHECKSUM_1 = 0x01;
static const uint8_t CHECKSUM_2 = 0x0F;





#pragma mark - Helpers

/// 小端 short
+ (void)appendLittleEndianInt16:(uint16_t)aValue into:(NSMutableData *)aData
{
    uint8_t le[2];
    le[0] = (uint8_t)(aValue & 0xFF);
    le[1] = (uint8_t)((aValue >> 8) & 0xFF);
    [aData appendBytes:le length:2];
}

/// 小端 int32
+ (void)appendLittleEndianInt32:(uint32_t)aValue into:(NSMutableData *)aData
{
    uint8_t le[4];
    le[0] = (uint8_t)(aValue & 0xFF);
    le[1] = (uint8_t)((aValue >> 8) & 0xFF);
    le[2] = (uint8_t)((aValue >> 16) & 0xFF);
    le[3] = (uint8_t)((aValue >> 24) & 0xFF);
    [aData appendBytes:le length:4];
}

+ (void)appendChecksumInto:(NSMutableData *)aData
{
    uint8_t cs[2] = { CHECKSUM_1, CHECKSUM_2 };
    [aData appendBytes:cs length:2];
}





#pragma mark - Private payload builders


/**
 * VI. 按鍵設定相關(ID:0x03):
 * 1. 寫入指定按鍵之內容(command :1, to 鍵盤)
 * i. 滑鼠指令
 */
+ (NSData *)p_buildMouseMoveCommandWithDeltaX:(NSInteger)aDX deltaY:(NSInteger)aDY leftClick:(BOOL)aIsLeftClick
{
    NSMutableData *m = [NSMutableData dataWithCapacity:9];
    
    // Byte 0: 0x01 滑鼠
    uint8_t type = 0x01;
    [m appendBytes:&type length:1];
    
    // Byte 1: button state
    uint8_t button = aIsLeftClick ? 0b00000001 : 0b00000000;
    [m appendBytes:&button length:1];
    
    // Byte 2: X 移動 (signed byte -127..127)
    NSInteger clampedX = MAX(-127, MIN(127, aDX));
    int8_t sx = (int8_t)clampedX;
    [m appendBytes:&sx length:1];
    
    // Byte 3: Y 移動 (signed byte -127..127)
    NSInteger clampedY = MAX(-127, MIN(127, aDY));
    int8_t sy = (int8_t)clampedY;
    [m appendBytes:&sy length:1];
    
    // Byte 4: 滾輪 (未用)
    uint8_t wheel = 0x00;
    [m appendBytes:&wheel length:1];
    
    // Byte 5-8: 保留
    uint8_t resv[4] = {0, 0, 0, 0};
    [m appendBytes:resv length:4];
    
    return m;
}


/**
 * VI. 按鍵設定相關(ID:0x03):
 * 1. 寫入指定按鍵之內容(command :1, to 鍵盤)
 * iv. 點擊指定座標
 */
+ (NSData *)p_buildKeyMappingTapPayloadWithX:(NSInteger)aX y:(NSInteger)aY
{
    NSMutableData *m = [NSMutableData dataWithCapacity:9];
    
    uint8_t type = 0x04;   // 點擊指定座標
    [m appendBytes:&type length:1];
    
    uint8_t clickOnce = 0x01;   // 單次點擊
    [m appendBytes:&clickOnce length:1];
    
    [self appendLittleEndianInt16:(uint16_t)aX into:m];   // X
    [self appendLittleEndianInt16:(uint16_t)aY into:m];   // Y
    
    uint8_t resv[3] = {0, 0, 0};
    [m appendBytes:resv length:3];
    
    return m;
}




#pragma mark - Public builders

/// 建立「設定巨集觸發鍵」的指令,  ((4).  寫入指定巨集之按鍵 (command :4, to 鍵盤))
+ (NSData *)buildSetMacroTriggerKeyPacket:(NSInteger)aKeyIndex
{
    NSMutableData *m = [NSMutableData dataWithCapacity:40];
    
    uint8_t hdr = HEADER_WRITE_TO_DEVICE;
    uint8_t ids = ID_MACRO;
    uint8_t cmd = CMD_SET_MACRO_TRIGGER_KEY;
    uint8_t len = 0x22;    // Length = 34 bytes
    
    [m appendBytes:&hdr length:1];
    [m appendBytes:&ids length:1];
    [m appendBytes:&cmd length:1];
    [m appendBytes:&len length:1];
    
    // Data Payload (34 bytes)
    // Data0: KeyIndex
    uint8_t key = (uint8_t)aKeyIndex;
    [m appendBytes:&key length:1];
    
    // Data1: 巨集執行模式 (0:單次, 1:連續)
    uint8_t mode = 0x00;
    [m appendBytes:&mode length:1];
    
    // Data2-33: 巨集名稱 32 bytes（暫填0）
    uint8_t name[32] = {0};
    [m appendBytes:name length:32];
    
    [self appendChecksumInto:m];
    
    return m;
}


/// (6).通知寫入巨集完成 (command :6, to 鍵盤)
+ (NSData *)buildNotifyMacroWriteCompletePacketWithKeyIndex:(NSInteger)aKeyIndex totalActions:(NSInteger)aTotalActions
{
    // H(1)+ID(1)+CMD(1)+LEN(1)+DATA(5)+CS(2) = 11
    NSMutableData *m = [NSMutableData dataWithCapacity:11];
    
    uint8_t hdr = HEADER_WRITE_TO_DEVICE;
    uint8_t ids = ID_MACRO;
    uint8_t cmd = CMD_NOTIFY_MACRO_WRITE_COMPLETE;
    uint8_t len = 0x05;    // Length = 5 bytes
    
    [m appendBytes:&hdr length:1];
    [m appendBytes:&ids length:1];
    [m appendBytes:&cmd length:1];
    [m appendBytes:&len length:1];
    
    // Data: KeyIndex(1) + TotalActions(4)
    uint8_t key = (uint8_t)aKeyIndex;
    [m appendBytes:&key length:1];
    [self appendLittleEndianInt32:(uint32_t)aTotalActions into:m];
    [self appendChecksumInto:m];
    
    return m;
}


/// VI.按鍵設定相關 (ID :0x03),
/// 寫入指定按鍵之內容 (command :1, to 鍵盤)
/// aKeyIndex: 鍵位索引
/// aKeyCode : HID key code
/// aX/aY   : 絕對座標（Short, 小端）
+ (NSData *)buildKeyMappingPacketWithKeyIndex:(NSInteger)aKeyIndex keyCode:(NSInteger)aKeyCode x:(NSInteger)aX y:(NSInteger)aY
{
    // 總長 41: H(1)+ID(1)+CMD(1)+LEN(1)+DATA(35)+CS(2)
    NSMutableData *m = [NSMutableData dataWithCapacity:41];
    
    uint8_t hdr = HEADER_WRITE_TO_DEVICE;
    uint8_t ids = ID_KEY_SETTING;
    uint8_t cmd = CMD_WRITE_KEY_MAPPING;
    uint8_t len = 0x23;    // Length = 35 bytes
    
    [m appendBytes:&hdr length:1];
    [m appendBytes:&ids length:1];
    [m appendBytes:&cmd length:1];
    [m appendBytes:&len length:1];
    
    // Data(35)
    // Data0: KeyIndex
    uint8_t keyIndex = (uint8_t)aKeyIndex;
    [m appendBytes:&keyIndex length:1];
    
    // Data1: KeyCode (HID)
    uint8_t keyCode = (uint8_t)aKeyCode;
    [m appendBytes:&keyCode length:1];
    
    // Data2: is mod key (0:否)
    uint8_t isMode = 0x00;
    [m appendBytes:&isMode length:1];
    
    // Data3-11: Android (reserved 9 bytes)
    // NSData *mouse = [self p_buildMouseMoveCommandWithDeltaX:aX deltaY:aY leftClick:YES];
    // [m appendData:mouse];
    uint8_t android[9] = {0};
    [m appendBytes:android length:9];
    
    // Data12-20: Windows (reserved 9 bytes)
    uint8_t win[9] = {0};
    [m appendBytes:win length:9];
    
    // Data21-29: iOS (reserved 9 bytes)
    uint8_t ios[9] = {0};
    [m appendBytes:ios length:9];
    
    // Data30: 是否可觸發巨集 (0:不可)
    uint8_t macroFlag = 0x00;
    [m appendBytes:&macroFlag length:1];
    
    // Data31-32: X (LE short)
    [self appendLittleEndianInt16:(uint16_t)aX into:m];
    // Data33-34: Y (LE short)
    [self appendLittleEndianInt16:(uint16_t)aY into:m];
    
    [self appendChecksumInto:m];    
    
    return m;
}



/// VI. 按鍵設定相關(ID:0x03):
/// 讀取指定按鍵之內容(command: 2, to 鍵盤)
+ (NSData *)readKeyMappingPacket:(NSInteger)aKeyIndex
{
    // H(1)+ID(1)+Cmd(1)+Len(1)+Data(1)+CS(2) = 7
    NSMutableData *m = [NSMutableData dataWithCapacity:7];
    
    uint8_t hdr = HEADER_READ_TO_DEVICE;
    uint8_t ids = ID_KEY_SETTING;
    uint8_t cmd = ID_MACRO;
    uint8_t len = 0x01;    // Length = 1 bytes
    
    [m appendBytes:&hdr length:1];
    [m appendBytes:&ids length:1];
    [m appendBytes:&cmd length:1];
    [m appendBytes:&len length:1];
    
    uint8_t keyIndex = (uint8_t)aKeyIndex;
    [m appendBytes:&keyIndex length:1];
    
    [self appendChecksumInto:m];
    
    return m;
}


/// 螢幕校正（to 鍵盤）
/// isIOS = YES 時 Data4 = 0x01，否則 0x00（你的 Kotlin 目前固定 0x00，我這裡提供參數）
+ (NSData *)buildScreenCalibrationPacketWithWidth:(NSInteger)aScreenWidth height:(NSInteger)aScreenHeight
{
    // H(1)+ID(1)+Cmd(1)+Len(1)+Data(5)+CS(2) = 11
    NSMutableData *m = [NSMutableData dataWithCapacity:11];
    
    uint8_t hdr = HEADER_WRITE_TO_DEVICE;
    uint8_t ids = ID_CALIBRATION;
    uint8_t cmd = CMD_WRITE_CALIBRATION;
    uint8_t len = 0x05;    // Length = 5 bytes
    
    [m appendBytes:&hdr length:1];
    [m appendBytes:&ids length:1];
    [m appendBytes:&cmd length:1];
    [m appendBytes:&len length:1];
    
    [self appendLittleEndianInt16:(uint16_t)aScreenWidth into:m];
    [self appendLittleEndianInt16:(uint16_t)aScreenHeight into:m];
    
    // Data 4: 若為iOS -> 0x01
    uint8_t flag = 0x01;
    [m appendBytes:&flag length:1];
    
    [self appendChecksumInto:m];
    
    return m;
}

/// 讀取手機螢幕設定 (to 鍵盤)
+ (NSData *)readScreenSetting
{
    // H(1)+ID(1)+Cmd(1)+Len(1)+CS(2) = 6
    NSMutableData *m = [NSMutableData dataWithCapacity:6];
    
    uint8_t hdr = HEADER_READ_TO_DEVICE;
    uint8_t ids = ID_CALIBRATION;
    uint8_t cmd = CMD_RETURN_TO_APP;
    uint8_t len = 0x00;    // Length = 0 bytes
    
    [m appendBytes:&hdr length:1];
    [m appendBytes:&ids length:1];
    [m appendBytes:&cmd length:1];
    [m appendBytes:&len length:1];
    
    [self appendChecksumInto:m];
    
    return m;
}


/// 建立「要求讀取指定按鍵之巨集內容」的指令, (1). 要求讀取指定按鍵之巨集內容(command :1, to 鍵盤)
+ (NSData *)buildReadMacroRequestPacket:(NSInteger)aKeyIndex
{
    // H(1)+ID(1)+Cmd(1)+Len(1)+Data(1)+CS(2) = 7
    NSMutableData *m = [NSMutableData dataWithCapacity:7];
    
    uint8_t hdr = HEADER_WRITE_TO_DEVICE;
    uint8_t ids = ID_MACRO;
    uint8_t cmd = CMD_READ_MACRO_REQUEST;
    uint8_t len = 0x01;    // Length = 1 bytes
    
    [m appendBytes:&hdr length:1];
    [m appendBytes:&ids length:1];
    [m appendBytes:&cmd length:1];
    [m appendBytes:&len length:1];
    
    uint8_t keyIndex = (uint8_t)aKeyIndex;
    [m appendBytes:&keyIndex length:1];
    
    [self appendChecksumInto:m];
    
    return m;
}


@end
