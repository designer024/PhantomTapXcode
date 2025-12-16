//
//  DeviceResponse.m
//  PhantomTap
//
//  Created by ethanlin on 2025/10/15.
//

#import "DeviceResponse.h"

@interface DeviceResponse()

@property (nonatomic, readwrite) DeviceResponseKind kind;

@property (nonatomic, readwrite) NSInteger keyIndex;
@property (nonatomic, readwrite) NSInteger hidCode;
@property (nonatomic, readwrite) NSInteger x;
@property (nonatomic, readwrite) NSInteger y;
@property (nonatomic, readwrite) BOOL success;

@property (nonatomic, copy, readwrite, nullable) NSArray<TapAction *> *actions;
@property (nonatomic, copy, readwrite, nullable) NSString *message;

@end


@implementation DeviceResponse

+ (instancetype)keyMappingWithKeyIndex:(NSInteger)aKeyIndex hid:(NSInteger)aHID x:(NSInteger)aX y:(NSInteger)aY
{
    DeviceResponse *r = [DeviceResponse new];
    r.kind = DeviceResponseKindMacroKeyMapping;
    r.keyIndex = aKeyIndex;
    r.hidCode = aHID;
    r.x = aX;
    r.y = aY;
    return r;
}

+ (instancetype)macroResultWithKeyIndex:(NSInteger)aKeyIndex success:(BOOL)aOK
{
    DeviceResponse *r = [DeviceResponse new];
    r.kind = DeviceResponseKindMacroResult;
    r.keyIndex = aKeyIndex;
    r.success = aOK;
    return r;
}

+ (instancetype)macroContentWithKeyIndex:(NSInteger)aKeyIndex actions:(NSArray<TapAction *> *)aActions
{
    DeviceResponse *r = [DeviceResponse new];
    r.kind = DeviceResponseKindMacroContent;
    r.keyIndex = aKeyIndex;
    r.actions = [aActions copy];
    return r;
}

+ (instancetype)errorWithMessage:(NSString *)aMessage
{
    DeviceResponse *r = [DeviceResponse new];
    r.kind = DeviceResponseKindError;
    r.message = aMessage;
    return r;
}


- (NSString *)description
{
    switch (self.kind) {
        case DeviceResponseKindMacroKeyMapping:
            return [NSString stringWithFormat:@"<KeyMapping idx=%ld hid0x%02lX x=%ld y=%ld>", (long)self.keyIndex, (long)self.hidCode, (long)self.x, (long)self.y];
            
        case DeviceResponseKindMacroResult:
            return [NSString stringWithFormat:@"<MacroResult idx=%ld ok=%@>", (long)self.keyIndex, self.success ? @"YES" : @"NO"];
            
        case DeviceResponseKindMacroContent:
            return [NSString stringWithFormat:@"<MacroContent idx=%ld actions=%lu>", (long)self.keyIndex, (unsigned long)self.actions.count];
            
        case DeviceResponseKindError:            
        default:
            return [NSString stringWithFormat:@"<Error message=%@>", self.message ?: @""];
    }
}

@end
