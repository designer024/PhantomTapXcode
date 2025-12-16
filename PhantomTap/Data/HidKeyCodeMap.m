//
//  HidKeyCodeMap.m
//  PhantomTap
//
//  Created by ethanlin on 2025/10/15.
//

#import "HidKeyCodeMap.h"

@implementation HidKeyCodeMap

/// 對應「實體鍵標籤」→「鍵位索引」(Key Index)
+ (NSDictionary<NSString *, NSNumber *> *)keyIndexMap
{
    static NSDictionary *m;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        m = @{
            @"1":@16, @"2":@17, @"3":@18, @"4":@19, @"5":@20,
            @"6":@21, @"7":@22, @"8":@23, @"9":@24, @"0":@25,
            @"Q":@30, @"W":@31, @"E":@32, @"R":@33, @"T":@34,
            @"Y":@35, @"U":@36, @"I":@37, @"O":@38, @"P":@39,
            @"A":@44, @"S":@45, @"D":@46, @"F":@47, @"G":@48,
            @"H":@49, @"J":@50, @"K":@51, @"L":@52,
            @"Z":@57, @"X":@58, @"C":@59, @"V":@60, @"B":@61,
            @"N":@62, @"M":@63,
            @"RightArrow":@78, @"LeftArrow":@75,
            @"DownArrow":@77, @"UpArrow":@76,
            @"SPACE":@72
        };
    });
    return m;
}

/// 對應「實體鍵標籤」→「HID Key Code」
+ (NSDictionary<NSString *, NSNumber *> *)hidKeyCodeMap
{
    static NSDictionary *m;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        m = @{
            @"A":@0x04, @"B":@0x05, @"C":@0x06, @"D":@0x07,
            @"E":@0x08, @"F":@0x09, @"G":@0x0A, @"H":@0x0B,
            @"I":@0x0C, @"J":@0x0D, @"K":@0x0E, @"L":@0x0F,
            @"M":@0x10, @"N":@0x11, @"O":@0x12, @"P":@0x13,
            @"Q":@0x14, @"R":@0x15, @"S":@0x16, @"T":@0x17,
            @"U":@0x18, @"V":@0x19, @"W":@0x1A, @"X":@0x1B,
            @"Y":@0x1C, @"Z":@0x1D,
            @"1":@0x1E, @"2":@0x1F, @"3":@0x20, @"4":@0x21,
            @"5":@0x22, @"6":@0x23, @"7":@0x24, @"8":@0x25,
            @"9":@0x26, @"0":@0x27,
            @"ENTER":@0x28, @"ESCAPE":@0x29, @"BACKSPACE":@0x2A,
            @"TAB":@0x2B, @"SPACE":@0x2C,
            @"RightArrow":@0x4F, @"LeftArrow":@0x50,
            @"DownArrow":@0x51, @"UpArrow":@0x52
        };
    });
    return m;
}


/// 便捷查詢
+ (nullable NSNumber *)keyIndexForLabel:(NSString *)aLabel
{
    return [[self keyIndexMap] objectForKey:aLabel];
}

+ (nullable NSNumber *)hidCodeForLabel:(NSString *)aLabel
{
    return [[self hidKeyCodeMap] objectForKey:aLabel];
}

@end
