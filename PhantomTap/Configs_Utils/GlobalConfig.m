//
//  GlobalConfig.m
//  PhantomTap
//
//  Created by ethanlin on 2025/10/13.
//

#import "GlobalConfig.h"

static NSString *EthanDebugTag = @"EthanLinPhantomTapTag";

@implementation GlobalConfig

+ (NSString *)DebugTag
{
    return EthanDebugTag;
}


+ (NSString *)Brook_Keyboard_Name
{
    return @"BLE_KB_W";
}

+ (NSInteger)JSON_VERSION
{
    return 20251017;
}

@end

