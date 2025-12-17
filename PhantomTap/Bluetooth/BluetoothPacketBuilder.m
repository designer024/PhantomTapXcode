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
static const uint8_t CMD_RETURN_TO_APP = 0x02;  // Calibration response / Accesssories req

/** 0x02 */
static const uint8_t CMD_READ_MACRO_RESPONSE = 0x02;
/** 0x02 */
static const uint8_t CMD_READ_KEY_MAPPING = 0x02;
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

+ (NSData *)emptyMacroSlot13Bytes
{
    // type(1) + content(8) + delay(4) = 13 bytes all zero
    NSMutableData *d = [NSMutableData dataWithLength:13];
    return d;
}


#pragma mark - Macro Content Helpers (Private)

/**
 * (5). 寫入巨集內容 helper: 轉換單個 Action 為 8 bytes Content
 * aType: 0: res, 1: 滑鼠, 2: 鍵盤, 3, 多媒體, 4: 點擊指定座標
 */
+ (NSData *)p_convertActionTo8Bytes:(TapAction *)aAction type:(uint8_t)aType
{
    NSMutableData *content = [NSMutableData dataWithCapacity:8];
    
    if (![aAction isKindOfClass:[TapAction class]])
    {
        [content setLength:8];
        return content;
    }
    
    switch (aType) {
        case 0x01:  // 滑鼠(button + deltaX + deltaY + wheel + reserved 4 bytes)
        {
            // Byte 0: 按鍵狀態 (isPressEvent=true -> 1, false -> 0)
            uint8_t btnState = [aAction isPressEvent] ? 0x01 : 0x00;
            [content appendBytes:&btnState length:1];
            
            // Byte 1-3: dx, dy, wheel (全部填 0)
            uint8_t zeros[3] = { 0, 0, 0 };
            [content appendBytes:zeros length:3];
            
            // Byte 4-7: reserved (4 bytes)
            uint8_t resv[4] = { 0, 0, 0, 0 };
            [content appendBytes:resv length:4];
            break;
        }
            
        case 0x02:  // 鍵盤
        {
            break;
        }
            
        case 0x03:  // 多媒體
        {
            break;
        }
            
        case 0x04:  // 點擊指定座標
        {
            // Byte 0: click type (0:不點擊, 1:單次, 2:長按) -> 這裡用 pressEvent 判斷
            uint8_t clickType = [aAction isPressEvent] ? 0x01 : 0x00;
            [content appendBytes:&clickType length:1];
            
            // Clamp X/Y
            NSInteger screenW = [aAction screenW] > 0 ? [aAction screenW] : 1080;
            NSInteger screenH = [aAction screenH] > 0 ? [aAction screenH] : 1920;
            
            NSInteger absX = MAX(0, MIN((NSInteger)[aAction posX], screenW - 1));
            NSInteger absY = MAX(0, MIN((NSInteger)[aAction posY], screenH - 1));
            
            // Byte 1-2: X (LE Short)
            [self appendLittleEndianInt16:(uint16_t)absX into:content];
            // Byte 3-4: Y (LE Short)
            [self appendLittleEndianInt16:(uint16_t)absY into:content];
            
            // Byte 5-7: reserved
            uint8_t resv[3] = { 0, 0, 0 };
            [content appendBytes:resv length:3];
            break;
        }
            
        default:
        {
            // 其他類型填 0
            [content setLength:8];
            break;
        }
    }
    
    
    if ([content length] < 8)
    {
        [content increaseLengthBy:(8 - [content length])];
    }
    
    return content;
}

/**
 * (5). 寫入巨集內容 helper: 轉換單個 Action 為 13 bytes Slot
 * 結構: Type(1) + Content(8) + Delay(4)
 */
+ (NSData *)p_convertActionTo13Bytes:(TapAction *)aAction
{
    if (![aAction isKindOfClass:[TapAction class]])
    {
        return [self emptyMacroSlot13Bytes];
    }
    
    NSMutableData *slot = [NSMutableData dataWithCapacity:13];
    
    // 現階段：用「滑鼠類型」來做 left down / up 測試
    uint8_t actionTpye = 0x01;   // 0x01: 滑鼠, 0x02: 鍵盤, 0x03, 多媒體, 0x04: 點擊指定座標
    // ---- 1 byte: type ----
    [slot appendBytes:&actionTpye length:1];
    
    // ---- 8 bytes: content ----
    NSData *content = [self p_convertActionTo8Bytes:aAction type:actionTpye];
    [slot appendData:content];
    
    // ---- 4 bytes: 下一步時間差 (ms, Little-endian) ----
    // 暫時規則：press → 短，release → 長
    uint32_t delay = [aAction isPressEvent] ? 50 : 450;
    [self appendLittleEndianInt32:delay into:slot];
    
    return slot;
}



#pragma mark - Public builders

/// (4). 寫入指定巨集之按鍵 (command :4, to 鍵盤)
/// @param aKeyIndex 指定的 key index
/// @param aIsContinuous YES=連續執行, NO=單次執行
/// @param aMacroName 巨集名稱，最多 32 bytes (ASCII)
+ (NSData *)buildSetMacroTriggerKeyPacket:(NSInteger)aKeyIndex isContinuous:(BOOL)aIsContinuous macroName:(NSString *)aMacroName
{
    NSMutableData *m = [NSMutableData dataWithCapacity:40];
    
    uint8_t hdr = HEADER_WRITE_TO_DEVICE;      // Header 0x05
    uint8_t ids = ID_MACRO;                    // ID 0x02
    uint8_t cmd = CMD_SET_MACRO_TRIGGER_KEY;   // Command 0x04
    uint8_t len = 0x22;                        // Length = 34 bytes
    
    [m appendBytes:&hdr length:1];
    [m appendBytes:&ids length:1];
    [m appendBytes:&cmd length:1];
    [m appendBytes:&len length:1];
    
    // Data Payload (34 bytes)
    // Data0: KeyIndex
    uint8_t key = (uint8_t)aKeyIndex;
    [m appendBytes:&key length:1];
    
    // Data1: 巨集執行模式 (0:單次, 1:連續)
    uint8_t mode = aIsContinuous ? 0x01 : 0x00;
    [m appendBytes:&mode length:1];
    
    // Data2-33: 巨集名稱 32 bytes（ASCII）
    // uint8_t nameData[32] = {0};  // 全部都是 0
    // [m appendBytes:nameData length:32];
    NSMutableData *nameData = [NSMutableData dataWithLength:32];
    if ([aMacroName length] > 0)
    {
        NSData *rawName = [aMacroName dataUsingEncoding:NSASCIIStringEncoding];
        if (rawName)
        {
            NSInteger copyLen = MIN([rawName length], 32);
            [nameData replaceBytesInRange:NSMakeRange(0, copyLen) withBytes:[rawName bytes]];
        }
    }
    [m appendData:nameData];
    
    [self appendChecksumInto:m];
    
    return m;
}

/// (5). 寫入巨集內容 (command :5, to 鍵盤)
/// 一個封包最多 10 筆步驟
/// @param aPacketIndex 封包索引 (1~65535)
/// @param aActions 動作列表 (TapAction)，最多 10 筆
+ (NSData *)buildWriteMacroContentPacketWithPacketIndex:(NSInteger)aPacketIndex actions:(NSArray<TapAction *> *)aActions
{
    // 檢查範圍
    if (aPacketIndex < 1 || aPacketIndex > 0xFFFF)
    {
        NSLog(@"Error: Packet index out of range.");
        return nil;
    }
    
    // Length = 0x85 (133 bytes Data)，總長度 = 4 + 133 + 2 = 139
    NSMutableData *m = [NSMutableData dataWithCapacity:139];
    
    uint8_t hdr = HEADER_WRITE_TO_DEVICE;      // Header 0x05
    uint8_t ids = ID_MACRO;                    // ID 0x02
    uint8_t cmd = CMD_WRITE_MACRO_CONTENT;     // Command 0x05
    uint8_t len = 0x85;                        // Length = 0x85 (133 bytes Data)
    
    [m appendBytes:&hdr length:1];
    [m appendBytes:&ids length:1];
    [m appendBytes:&cmd length:1];
    [m appendBytes:&len length:1];
    
    // Data 0-1: 封包索引 (Little-endian)
    [self appendLittleEndianInt16:(uint16_t)aPacketIndex into:m];
    
    // Data 2: 該封包巨集步驟數量 (最多10)
    NSInteger count = MIN([aActions count], 10);
    uint8_t countByte = (uint8_t)count;
    [m appendBytes:&countByte length:1];
    
    // 接下來是 10 個 slot，每個 13 bytes
    for (int i = 0; i < 10; i++)
    {
        if (i < count)
        {
            TapAction *action = aActions[i];
            NSData *slotData = [self p_convertActionTo13Bytes:action];
            [m appendData:slotData];
        }
        else
        {
            [m appendData:[self emptyMacroSlot13Bytes]];
        }
    }
    
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

/// (1). 要求讀取指定按鍵之巨集內容(command :1, to 鍵盤)
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


#pragma mark - Key Mapping (ID: 0x03)

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
    [m appendData:[NSMutableData dataWithLength:9]];
    
    // Data12-20: Windows (reserved 9 bytes)
    [m appendData:[NSMutableData dataWithLength:9]];
    
    // Data21-29: iOS (reserved 9 bytes)
    [m appendData:[NSMutableData dataWithLength:9]];
    
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
    uint8_t cmd = CMD_READ_KEY_MAPPING;
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

/// 啟用「可觸發巨集」的 key mapping (測試用/特殊用途)
+ (NSData *)buildEnableMacroTriggerKeyPacket:(NSInteger)aKeyIndex
{
    // header + ID + cmd + len + data(31) + checksum
    NSMutableData *m = [NSMutableData dataWithCapacity:37];
    
    uint8_t hdr = HEADER_WRITE_TO_DEVICE;
    uint8_t ids = ID_KEY_SETTING;
    uint8_t cmd = CMD_WRITE_KEY_MAPPING;
    uint8_t len = 0x1F; // 31 bytes
    
    [m appendBytes:&hdr length:1];
    [m appendBytes:&ids length:1];
    [m appendBytes:&cmd length:1];
    [m appendBytes:&len length:1];
    
    // Data 0: Key Index
    uint8_t key = (uint8_t)aKeyIndex;
    [m appendBytes:&key length:1];
    
    // Data 1, 2: KeyCode=0(未指定特定 key), Mod=0
    uint8_t zeros[2] = { 0, 0 };
    [m appendBytes:zeros length:2];
    
    // Data 3-29 : 27 bytes (Android/Win/iOS reserved)
    [m appendData:[NSMutableData dataWithLength:27]];
    
    // Data 30: 可觸發巨集 = 1
    uint8_t macroFlag = 0x01;
    [m appendBytes:&macroFlag length:1];
    
    [self appendChecksumInto:m];

    return m;
}


#pragma mark - Calibration (ID: 0x05)

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
    
    // Data 4: iOS -> 0x01
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


#pragma mark - Accessories (ID: 0x01)


/// 請求周邊列表 (Command: 0x01)
+ (NSData *)buildRequestAccessoriesList
{
    NSMutableData *m = [NSMutableData dataWithCapacity:6];
    
    uint8_t hdr = HEADER_READ_TO_DEVICE;
    uint8_t ids = ID_ACCESSORIES;
    uint8_t cmd = CMD_WRITE_KEY_MAPPING;
    uint8_t len = 0x00;    // Length = 0 bytes
    
    [m appendBytes:&hdr length:1];
    [m appendBytes:&ids length:1];
    [m appendBytes:&cmd length:1];
    [m appendBytes:&len length:1];
    
    [self appendChecksumInto:m];
    return m;
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

@end
