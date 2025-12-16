//
//  KeymapModels.m
//  PhantomTap
//
//  Created by ethanlin on 2025/10/15.
//

#import "KeymapModels.h"

@implementation TapAction

- (instancetype)initWithId:(NSInteger)aActionId orientation:(NSString *)aOrientation screenW:(NSInteger)aScreenW screenH:(NSInteger)aScreenH posX:(CGFloat)aPosX posY:(CGFloat)aPosY keyCode:(NSString *)aKeyCode pressEvent:(BOOL)aPressEvent
{
    self = [super init];
    if (self)
    {
        _actionId = aActionId;
        _orientation = [aOrientation length] ? [aOrientation copy] : @"PORTRAIT";
        _screenW = aScreenW;
        _screenH = aScreenH;
        _posX = aPosX;
        _posY = aPosY;
        _keyCode = [aKeyCode length] ? [aKeyCode copy] : @"null";
        _pressEvent = aPressEvent;
    }
    
    return self;
}


+ (instancetype)tapWitId:(NSInteger)aActionId orientation:(NSString *)aOrientation screenW:(NSInteger)aScreenW screenH:(NSInteger)aScreenH posX:(CGFloat)aPosX posY:(CGFloat)aPosY keyCode:(NSString *)aKeyCode pressEvent:(BOOL)aPressEvent
{
    return [[self alloc] initWithId:aActionId orientation:aOrientation screenW:aScreenW screenH:aScreenH posX:aPosX posY:aPosY keyCode:aKeyCode pressEvent:aPressEvent];
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"<TapAction id=%ld ori=%@ pos=(%.1f,%.1f) screen=%ldx%ld key=%@ press=%@>",
            (long)self.actionId,
            self.orientation,
            self.posX, self.posY,
            (long)self.screenW, (long)self.screenH,
            self.keyCode,
            self.isPressEvent ? @"YES" : @"NO"];
}


@end



@implementation KeymapFile

- (instancetype)initWithVersion:(NSInteger)aVersion createdAt:(NSString *)aCreatedAt nickname:(NSString *)aNickname portraitW:(NSInteger)aPortraitW portraitH:(NSInteger)aPortraitH rotationWhenSaved:(NSInteger)aRotation actions:(NSArray<id<KeymapAction>> *)aActions
{
    self = [super init];
    if (self)
    {
        _version = aVersion;
        _createdAt = [aCreatedAt copy];
        _nickname = [aNickname copy];
        _portraitW = aPortraitW;
        _portraitH = aPortraitH;
        _rotationWhenSaved = aRotation;
        _actions = [aActions copy] ?: @[];
    }
    return self;
}

+ (instancetype)fileWithVersion:(NSInteger)aVersion createdAt:(NSString *)aCreatedAt nickname:(NSString *)aNickname oportraitW:(NSInteger)aPortraitW portraitH:(NSInteger)aPortraitH rotationWhenSaved:(NSInteger)aRotation actions:(NSArray<id<KeymapAction>> *)aActions
{
    return [[self alloc] initWithVersion:aVersion createdAt:aCreatedAt nickname:aNickname portraitW:aPortraitW portraitH:aPortraitH rotationWhenSaved:aRotation actions:aActions];
}


+ (nullable instancetype)fromJSON:(NSData *)aJSON error:(NSError **)aError
{
    id obj = [NSJSONSerialization JSONObjectWithData:aJSON options:0 error:aError];
    if (!obj || ![obj isKindOfClass:[NSDictionary class]]) return nil;
    NSDictionary *root = (NSDictionary *)obj;
    
    NSInteger version      = [root[@"version"] integerValue];
    NSString *createdAt    = root[@"created_at"] ?: @"";
    NSString *nickname     = root[@"nickname"] ?: @"";
    NSInteger portraitW    = [root[@"portraitW"] integerValue];
    NSInteger portraitH    = [root[@"portraitH"] integerValue];
    NSInteger rotation     = [root[@"rotation_when_saved"] integerValue];
    
    NSMutableArray<TapAction *> *list = [NSMutableArray array];
    NSArray *actions = root[@"actions"];
    if ([actions isKindOfClass:[NSArray class]])
    {
        [actions enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSDictionary *it = (NSDictionary *)obj;
            // 只處理 type == TAP
            NSString *typeStr = it[@"type"] ?: @"TAP";
            if (![[typeStr uppercaseString] isEqualToString:@"TAP"]) return;
            
            NSInteger aid = [it[@"id"] integerValue];
            NSString *key = it[@"key"] ?: @"null";
            // 注意：Android 存的是「螢幕左上角絕對座標」(posX/posY)，
            // iOS 畫面要顯示時通常會換算成容器座標；這裡先照存檔讀出。
            CGFloat cx = [it[@"center_portrait_x"] doubleValue];
            CGFloat cy = [it[@"center_portrait_y"] doubleValue];
            
            TapAction *ta = [[TapAction alloc] initWithId:aid orientation:@"PORTRAIT" screenW:portraitW screenH:portraitH posX:cx posY:cy keyCode:key pressEvent:YES];
            [list addObject:ta];
            
        }];
    }
    
    return [[self alloc] initWithVersion:version createdAt:createdAt nickname:nickname portraitW:portraitW portraitH:portraitH rotationWhenSaved:rotation actions:list];
}

- (NSData *)toJSONPretty:(BOOL)aPrettyJson error:(NSError **)aError
{
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:self.actions.count];
    [self.actions enumerateObjectsUsingBlock:^(TapAction * _Nonnull v, NSUInteger idx, BOOL * _Nonnull stop) {
        // 存成 Android 版 schema：posX/posY = 「螢幕左上角絕對座標」
        // 你在組 JSON 前，請先把 view 的 centerOnScreen 算好/或保留原本螢幕座標放進 v.posX / v.posY
        NSDictionary *item = @{
            @"type": @"TAP",
            @"id": @(v.actionId),
            @"key": v.keyCode ?: @"null",
            @"center_portrait_x": @(v.posX),
            @"center_portrait_y": @(v.posY),
        };
        [arr addObject:item];
    }];
    
    NSDictionary *root = @{
        @"version": @(self.version),
        @"created_at": self.createdAt ?: @"",
        @"nickname": self.nickname ?: @"",
        @"portraitW": @(self.portraitW),
        @"portraitH": @(self.portraitH),
        @"rotation_when_saved": @(self.rotationWhenSaved),
        @"actions": arr
    };
    
    NSJSONWritingOptions opt = aPrettyJson ? NSJSONWritingPrettyPrinted : 0;
    return [NSJSONSerialization dataWithJSONObject:root options:opt error:aError];
}

//- (NSString *)description
//{
//    return [NSString stringWithFormat:@"<KeymapFile v=%ld file=%@ nick=%@ actions=%lu>",
//            (long)self.version, self.fileName, self.nickname, (unsigned long)self.actions.count];
//}

@end
