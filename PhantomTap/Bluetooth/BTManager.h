//
//  BTManager.h
//  PhantomTap
//
//  Created by ethanlin on 2025/10/13.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "GlobalConfig.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^BTStateHandler) (CBManagerState state);
typedef void(^BTScanResultHandler) (CBPeripheral *aPeripheral, NSDictionary *aAdv, NSNumber *aRSSI);
typedef void(^BTConnectHandler) (CBPeripheral *aPeripheral, NSError *_Nullable aError);
typedef void(^BTReadyHandler) (void);
typedef void(^BTDataHandler) (NSData *aData);


@interface BTManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, copy, nullable) BTStateHandler onState;
@property (nonatomic, copy, nullable) BTScanResultHandler onScan;
@property (nonatomic, copy, nullable) BTConnectHandler onConnect;
@property (nonatomic, copy, nullable) BTReadyHandler onReady;
@property (nonatomic, copy, nullable) BTDataHandler onData;

@property (nonatomic, strong, nullable) CBUUID *pendingReadUUID;

+ (CBUUID *)CCCD;
+ (CBUUID *)Custom_Service_UUID;
+ (CBUUID *)Read_Characteristic_UUID;
+ (CBUUID *)Write_Characteristic_UUID;
+ (CBUUID *)Notify_Characteristic_UUID;
+ (CBUUID *)Indicate_Characteristic_UUID;

+ (CBUUID *)Battery_Service_UUID;
+ (CBUUID *)Batter_Level_Characteristic_UUID;


+ (instancetype)shared;

- (CBCentralManager *)getCentral;
- (CBPeripheral *)getConnected;

- (void)startScanWithNameSubstring:(NSString *)aSubstring timeout:(NSTimeInterval)aTimeout;
- (void)stopScan;
- (void)connectTo:(CBPeripheral *)aPeripheral;
- (void)disconnect;

- (void)enableNotifyForService:(CBUUID *)aService characteristic:(CBUUID *)aCharacteristic notify:(BOOL)aEnable;
- (void)write:(NSData *)aData toService:(CBUUID *)aService characteristic:(CBUUID *)aCharacteristic withResponse:(BOOL)aWithRsp;

- (void)readB201;
- (void)readFromService:(CBUUID *)aService characteristic:(CBUUID *)aCharacteristic;


- (void)logCachedCharacteristics;

+ (NSString *)byteArrayToHexString:(NSData *)aData;

@end

NS_ASSUME_NONNULL_END
