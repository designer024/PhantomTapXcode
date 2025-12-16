//
//  KeymapModels.h
//  PhantomTap
//
//  Created by ethanlin on 2025/10/15.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN


/// 對應 Kotlin: enum class KeymapType { DRAGGABLE_TAP, SWIPE }
typedef NS_ENUM(NSInteger, KeymapType)
{
    KeymapTypePhantomTap = 0,
    KeymapTypeSwipe = 1,
    KeymapTypeJoystick = 2,
};


/// 對應 Kotlin: sealed interface KeymapAction { val id: Int }
@protocol KeymapAction <NSObject>

@property (nonatomic, readonly) NSInteger actionId;

@end


/// 對應 Kotlin: data class TapAction(...) : KeymapAction
@interface TapAction : NSObject <KeymapAction>

@property (nonatomic, readonly) NSInteger actionId;
@property (nonatomic, copy) NSString *orientation;  // "PORTRAIT" 或 "LANDSCAPE"
@property (nonatomic) NSInteger screenW;            // 校正時的螢幕寬
@property (nonatomic) NSInteger screenH;            // 校正時的螢幕高
@property (nonatomic) CGFloat posX;                 // 視圖「左上角」x（相對容器）
@property (nonatomic) CGFloat posY;                 // 視圖「左上角」y（相對容器）
@property (nonatomic, copy) NSString *keyCode;      // 預設 @"null"
@property (nonatomic, getter=isPressEvent) BOOL pressEvent;


- (instancetype)initWithId:(NSInteger)aActionId orientation:(NSString *)aOrientation screenW:(NSInteger)aScreenW screenH:(NSInteger)aScreenH posX:(CGFloat)aPosX posY:(CGFloat)aPosY keyCode:(NSString *)aKeyCode pressEvent:(BOOL)aPressEvent NS_DESIGNATED_INITIALIZER;

+ (instancetype)tapWitId:(NSInteger)aActionId orientation:(NSString *)aOrientation screenW:(NSInteger)aScreenW screenH:(NSInteger)aScreenH posX:(CGFloat)aPosX posY:(CGFloat)aPosY keyCode:(NSString *)aKeyCode pressEvent:(BOOL)aPressEvent;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end


/// 對應 Kotlin: data class KeymapFile(...)
@interface KeymapFile : NSObject

@property (nonatomic) NSInteger version;
@property (nonatomic, copy) NSString *createdAt;      // yyyy-MM-dd'T'HH:mm:ssZ
@property (nonatomic, copy) NSString *nickname;

@property (nonatomic) NSInteger rotationWhenSaved;  // 目前先固定 0
@property (nonatomic) NSInteger portraitW;   // 存檔時螢幕寬
@property (nonatomic) NSInteger portraitH;   // 存檔時螢幕高
@property (nonatomic, copy) NSArray<id<KeymapAction>> *actions;

- (instancetype)initWithVersion:(NSInteger)aVersion createdAt:(NSString *)aCreatedAt nickname:(NSString *)aNickname portraitW:(NSInteger)aPortraitW portraitH:(NSInteger)aPortraitH rotationWhenSaved:(NSInteger)aRotation actions:(NSArray<id<KeymapAction>> *)aActions NS_DESIGNATED_INITIALIZER;

+ (instancetype)fileWithVersion:(NSInteger)aVersion createdAt:(NSString *)aCreatedAt nickname:(NSString *)aNickname oportraitW:(NSInteger)aPortraitW portraitH:(NSInteger)aPortraitH rotationWhenSaved:(NSInteger)aRotation actions:(NSArray<id<KeymapAction>> *)aActions;

+ (nullable instancetype)fromJSON:(NSData *)aJSON error:(NSError **)aError;
- (NSData *)toJSONPretty:(BOOL)aPrettyJson error:(NSError **)aError;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
