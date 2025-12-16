//
//  BluetoothPacketParser.h
//  PhantomTap
//
//  Created by ethanlin on 2025/10/20.
//

#import <Foundation/Foundation.h>

@class DeviceResponse;

NS_ASSUME_NONNULL_BEGIN

@interface BluetoothPacketParser : NSObject

+ (nullable DeviceResponse *)parse:(NSData *)aPayload;

+ (nullable NSDictionary *)parseKeyMappingRead:(NSData *)aData;


@end

NS_ASSUME_NONNULL_END
