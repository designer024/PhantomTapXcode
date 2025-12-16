//
//  BluetoothPacketParser.m
//  PhantomTap
//
//  Created by ethanlin on 2025/10/20.
//

#import "BluetoothPacketParser.h"
#import "DeviceResponse.h"
// #import "GlobalConfig.h"

// 常數與 Android 版本一致
static const uint8_t HEADER_RESPONSE_FROM_DEVICE_A = 0x06;
static const uint8_t HEADER_RESPONSE_FROM_DEVICE_B = 0x00;
static const uint8_t ID_KEY_SETTING = 0x03;
static const uint8_t ID_MACRO = 0x02;

static const uint8_t CMD_READ_KEYMAPPING_RESPONSE = 0x02;      // 讀取按鍵內容的回覆
static const uint8_t CMD_MACRO_RESULT_RESPONSE = 0x03;         // 結果回報

static inline uint16_t le16(const uint8_t *p)
{
    return (uint16_t)p[0] | ((uint16_t)p[1] << 8);
}

// 允許 0x00/0x06 兩種 header
static inline BOOL _isValidHead(uint8_t aHeader)
{
    return (aHeader == 0x00 || aHeader == 0x06);
}


@implementation BluetoothPacketParser

+ (nullable DeviceResponse *)parse:(NSData *)aPayload
{
    const uint8_t *b = [aPayload bytes];
    NSUInteger n = [aPayload length];
    if (n < 4)
    {
        return [DeviceResponse errorWithMessage:@"packet too short."];
    }
    
    uint8_t dataHeader = b[0];
    uint8_t dataID = b[1];
    uint8_t dataCMD = b[2];
    uint8_t dataLEN = b[3];
    
    // 接受 0x06 或 0x00
    if (!(dataHeader == HEADER_RESPONSE_FROM_DEVICE_A || dataHeader == HEADER_RESPONSE_FROM_DEVICE_B))
    {
        return [DeviceResponse errorWithMessage:[NSString stringWithFormat:@"unexpected header 0x%02X", dataHeader]];
    }
    
    // --- 解析「讀螢幕設定」回覆 ---
    if (dataID == 0x05 && dataCMD == 0x02)
    {
        if (n < 4 + 5 + 2)
        {
            return [DeviceResponse errorWithMessage:@"screen-setting resp too short"];
        }
        uint16_t x = (uint16_t)(b[4] | (b[5] << 8));
        uint16_t y = (uint16_t)(b[6] | (b[7] << 8));
        uint8_t  flag = b[8];
        
        NSLog(@"[PARSE] screen setting: X=%u Y=%u iOS=%u", x, y, flag);
        return [DeviceResponse macroResultWithKeyIndex:0 success:YES];
    }
    
    // --- 解析「讀 KeyMapping」回覆 ---
    if (dataID == 0x03 && dataCMD == 0x02)
    {
        if (n < 41) return [DeviceResponse errorWithMessage:@"keymapping resp too short"];
        
        return [DeviceResponse macroResultWithKeyIndex:0 success:YES];
    }
    
    return [DeviceResponse errorWithMessage:@"unknown packet"];
}


+ (nullable NSDictionary *)parseKeyMappingRead:(NSData *)aData
{
    const uint8_t *b = [aData bytes];
    NSUInteger n = [aData length];
    if (n < 41) return nil;
    
    uint8_t dataHeader = b[0];
    uint8_t dataID = b[1];
    uint8_t dataCMD = b[2];
    uint8_t dataLEN = b[3];
    
    if (!_isValidHead(dataHeader)) return nil;
    if (dataID != 0x03) return nil;
    if (dataCMD != 0x02) return nil;
    // if (dataLEN != 0x23) return nil;
    
    uint8_t keyIndex = b[4];
    uint8_t hidCode = b[5];
    uint8_t isMod = b[6];
    
    // little-endian shorts
    uint16_t x = (uint16_t)b[35] | ((uint16_t)b[36] << 8);
    uint16_t y = (uint16_t)b[37] | ((uint16_t)b[38] << 8);
    
    return @{
        @"keyIndex": @(keyIndex),
        @"hidCode": @(hidCode),
        @"isMod": @(isMod),
        @"x": @(x),
        @"y": @(y),
    };
}


@end
