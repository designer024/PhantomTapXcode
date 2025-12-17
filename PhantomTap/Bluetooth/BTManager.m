//
//  BTManager.m
//  PhantomTap
//
//  Created by ethanlin on 2025/10/13.
//

#import "BTManager.h"

@interface BTManager()
{
    CBCentralManager *_central;
    CBPeripheral *_connectedPeripheral;
    
    // 原本的 NSMutableDictionary<NSString *, CBCharacteristic *> *_charCache;
    NSMutableDictionary<CBUUID *, CBCharacteristic *> *_charCache;
    NSString *_targetNameSubstring;
}

@end


@implementation BTManager

+ (instancetype)shared
{
    static BTManager *instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [BTManager new];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _central = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
        _charCache = [NSMutableDictionary dictionary];
    }
    
    return self;
}

+ (CBUUID *)CCCD
{
    return [CBUUID UUIDWithString:@"00002902-0000-1000-8000-00805F9B34FB"];
}
+ (CBUUID *)Custom_Service_UUID
{
    return [CBUUID UUIDWithString:@"0000A00C-0000-1000-8000-00805F9B34FB"];
}
+ (CBUUID *)Read_Characteristic_UUID
{
    return [CBUUID UUIDWithString:@"0000B201-0000-1000-8000-00805F9B34FB"];
}
+ (CBUUID *)Write_Characteristic_UUID
{
    return [CBUUID UUIDWithString:@"0000B202-0000-1000-8000-00805F9B34FB"];
}
+ (CBUUID *)Notify_Characteristic_UUID
{
    return [CBUUID UUIDWithString:@"0000B203-0000-1000-8000-00805F9B34FB"];
}
+ (CBUUID *)Indicate_Characteristic_UUID
{
    return [CBUUID UUIDWithString:@"0000B204-0000-1000-8000-00805F9B34FB"];
}

/// 180F
+ (CBUUID *)Battery_Service_UUID
{
    return [CBUUID UUIDWithString:@"0000180F-0000-1000-8000-00805F9B34FB"];
}
/// 2A19
+ (CBUUID *)Batter_Level_Characteristic_UUID
{
    return [CBUUID UUIDWithString:@"00002A19-0000-1000-8000-00805F9B34FB"];
}



#pragma mark - Public

- (CBCentralManager *)getCentral
{
    return _central;
}

- (CBPeripheral *)getConnected
{
    return _connectedPeripheral;
}


- (void)startScanWithNameSubstring:(NSString *)aSubstring timeout:(NSTimeInterval)aTimeout
{
    self -> _targetNameSubstring = aSubstring;
    
    if ([_central state] != CBManagerStatePoweredOn) return;
    
    [_central scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
    if (aTimeout > 0)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(aTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self stopScan];
        });
    }
}

- (void)stopScan
{
    [_central stopScan];
}

- (void)connectTo:(CBPeripheral *)aPeripheral
{
    _connectedPeripheral = aPeripheral;
    [aPeripheral setDelegate:self];
    [_central connectPeripheral:aPeripheral options:nil];
}

- (void)disconnect
{
    if (_connectedPeripheral)
    {
        [_central cancelPeripheralConnection:_connectedPeripheral];
    }
}



- (void)enableNotifyForService:(CBUUID *)aService characteristic:(CBUUID *)aCharacteristic notify:(BOOL)aEnable
{
    CBCharacteristic *ch = _charCache[aCharacteristic];
    if (!ch)
    {
        return;
    }
    
    [_connectedPeripheral setNotifyValue:aEnable forCharacteristic:ch];
}

- (void)write:(NSData *)aData toService:(CBUUID *)aService characteristic:(CBUUID *)aCharacteristic withResponse:(BOOL)aWithRsp
{
    CBCharacteristic *ch = _charCache[aCharacteristic];
    if (!ch || !_connectedPeripheral)
    {
        return;
    }
    
    CBCharacteristicWriteType type = aWithRsp ? CBCharacteristicWriteWithResponse : CBCharacteristicWriteWithoutResponse;
    [_connectedPeripheral writeValue:aData forCharacteristic:ch type:type];
}


- (void)readB201
{
    [self readFromService:[BTManager Custom_Service_UUID] characteristic:[BTManager Read_Characteristic_UUID]];
}


- (CBService *)p_serviceForUUID:(CBUUID *)aUUID
{
    for (CBService *s in [_connectedPeripheral services] ?: @[])
    {
        if ([[s UUID] isEqual:aUUID]) return s;
    }
    return nil;
}

- (void)readFromService:(CBUUID *)aService characteristic:(CBUUID *)aCharacteristic
{
    if (!_connectedPeripheral)
    {
        NSLog(@"[BLE] read fail: no connected peripheral");
        return;
    }
    
    CBCharacteristic *ch = _charCache[aCharacteristic];
    if (!ch)
    {
        // 還沒快取到 → 試著先確保 service/characteristic 存在
        CBService *svc = [self p_serviceForUUID:aService];
        if (!svc)
        {
            // 還沒有 service，先 discover，再等回呼
            NSLog(@"[BLE] read defer: service %@ not discovered yet, discovering…", [aService UUIDString]);
            _pendingReadUUID = aCharacteristic;
            [_connectedPeripheral discoverServices:@[aService]];
            return;
        }
        // 有 service，可能沒那顆 char，discover 一下該顆
        NSLog(@"[BLE] read defer: characteristic %@ not in cache, discovering…", [aCharacteristic UUIDString]);
        _pendingReadUUID = aCharacteristic;
        [_connectedPeripheral discoverCharacteristics:@[aCharacteristic] forService:svc];
        return;
    }
    
    [_connectedPeripheral readValueForCharacteristic:ch];
    NSLog(@"[BLE] read request -> %@", [aCharacteristic UUIDString]);
}


- (void)readBatteryLevelOnce
{
    CBCharacteristic *c = _charCache[[BTManager Batter_Level_Characteristic_UUID]];
    
    if (c && _connectedPeripheral)
    {
        NSLog(@"[BTManager] ⚡️ readBatteryLevelOnce() -> readValue");
        [_connectedPeripheral readValueForCharacteristic:c];
    }
    else
    {
        NSLog(@"[BTManager] ❌ 讀取電量失敗: 找不到特徵值 2A19 (可能未掃描到服務)");
    }
}

- (void)setBatteryNotification:(BOOL)aEnabled
{
    CBCharacteristic *c = _charCache[[BTManager Batter_Level_Characteristic_UUID]];
    
    if (c && _connectedPeripheral)
    {
        NSLog(@"[BTManager] 🔔 enableBatteryLevelNotification(%@) -> setNotify", aEnabled ? @"true" : @"false");
        [_connectedPeripheral setNotifyValue:aEnabled forCharacteristic:c];
    }
    else
    {
        NSLog(@"[BTManager] ❌ 設定通知失敗: 找不到特徵值 2A19");
    }
}


- (void)logCachedCharacteristics
{
    NSLog(@"[BLE] cached %lu chars:", (unsigned long)_charCache.count);
    [_charCache enumerateKeysAndObjectsUsingBlock:^(CBUUID *key, CBCharacteristic *obj, BOOL *stop) {
        NSLog(@"   • %@ props=0x%lx", key, (unsigned long)obj.properties);
    }];
}


+ (NSString *)byteArrayToHexString:(NSData *)aData
{
    if (aData != nil && aData.length > 0)
    {
        NSMutableString *str = [NSMutableString stringWithCapacity:64];
        int length = (int)[aData length];
        char *bytes = (char *)malloc(sizeof(char) * length);

        [aData getBytes:bytes length:length];

        for (int i = 0; i < length; i++)
        {
            [str appendFormat:@"%02.2hhX", bytes[i]];
        }
        free(bytes);

        return str;
    }
    else
    {
        return @"";
    }
}



#pragma mark - CBCentralManager Delegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (self.onState)
    {
        self.onState([central state]);
    }
    
    if ([central state] != CBManagerStatePoweredOn) return;
    
    NSString *targetNameSub = [GlobalConfig Brook_Keyboard_Name];
    
    // 1) 先嘗試撈取「已連線」但具有自訂服務的周邊
    CBUUID *svc = [BTManager Custom_Service_UUID];
    NSArray<CBPeripheral *> *connected = [central retrieveConnectedPeripheralsWithServices:@[svc]];
    
    CBPeripheral *matchedPeripheral = nil;
    
    if ([connected count] > 0 && [targetNameSub length] > 0)
    {
        for (CBPeripheral *p in connected)
        {
            NSString *name = [p name] ?: @"";
            NSRange range = [name rangeOfString:targetNameSub options:NSCaseInsensitiveSearch];
            if (range.location != NSNotFound)
            {
                matchedPeripheral = p;
                break;
            }
        }
    }
    
    if (matchedPeripheral)
    {
        NSLog(@"有了(已連線 + 名稱包含 %@)，不再掃", targetNameSub);
        NSLog(@"peripheral: %@", [matchedPeripheral name]);
        
        if (self.onScan)
        {
            // 模擬掃描到（adv/RSSI 先給 nil）
            self.onScan(matchedPeripheral, @{}, @(0));
        }
        return;
        
    }
    
    // 2) 沒撈到才開始掃描
    if ([_targetNameSubstring length] > 0)
    {
        NSLog(@"沒撈到, 開始掃描");
        [self startScanWithNameSubstring:_targetNameSubstring timeout:8];
    }
    else
    {
        [_central scanForPeripheralsWithServices:@[svc] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
    }
    
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"peripheral: %@", peripheral);
    
    NSString *name = [peripheral name] ?: @"";
    if ([name length] && [name containsString:_targetNameSubstring])
    {
        if (self.onScan)
        {
            self.onScan(peripheral, advertisementData, RSSI);
        }
    }
}

// ✅ 連線成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"[BLE-DEBUG] didConnect: %@", [peripheral name]);
    
    if (self.onConnect)
    {
        self.onConnect(peripheral, nil);
    }
    
    CBUUID *targetUUID = [BTManager Custom_Service_UUID];
    CBUUID *battryUUID = [BTManager Battery_Service_UUID];
    NSLog(@"[BLE-DEBUG] Discovering services with UUID: %@, %@", targetUUID, battryUUID);
    // [peripheral discoverServices:@[targetUUID]];
    [peripheral discoverServices:nil];
}

// ❌ 連線失敗
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"[BLE-DEBUG] didFailToConnect: %@, error: %@", [peripheral name], error);
    if (self.onConnect)
    {
        self.onConnect(peripheral, error);
    }
}

// 🔌 斷線
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"[BLE-DEBUG] didDisconnect: %@, error: %@", [peripheral name], error);
    _connectedPeripheral = nil;
    [_charCache removeAllObjects];
}




#pragma mark - CBPeripheral Delegate

// ✅ 發現 Services
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        NSLog(@"[BLE-DEBUG] didDiscoverServices Error: %@", error);
        return;
    }
    
    if ([[peripheral services] count] == 0)
    {
        NSLog(@"[BLE-DEBUG] No services found! Check your Custom_Service_UUID.");
        return;
    }
    
    for (CBService *svc in [peripheral services])
    { 
        if ([[svc UUID] isEqual:[BTManager Custom_Service_UUID]])
        {
            [peripheral discoverCharacteristics:@[[BTManager Read_Characteristic_UUID], [BTManager Write_Characteristic_UUID], [BTManager Notify_Characteristic_UUID], [BTManager Indicate_Characteristic_UUID]] forService:svc];
        }
        else if ([[svc UUID] isEqual:[BTManager Battery_Service_UUID]])
        {
            NSLog(@"[BTManager] 🔎 發現電池服務 (180F)，掃描特徵值...");
            [peripheral discoverCharacteristics:@[[BTManager Batter_Level_Characteristic_UUID]] forService:svc];
        }
        else
        {
            NSLog(@"[BLE-DEBUG] Service Mismatch. Expected: %@", [BTManager Custom_Service_UUID]);
        }
    }
}

// ✅ 發現 Characteristics
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error)
    {
        NSLog(@"[BLE-DEBUG] didDiscoverCharacteristics Error: %@", error);
        return;
    }
    
    NSLog(@"[BLE-DEBUG] Service %@ has %lu characteristics", [service UUID], (unsigned long)[[service characteristics] count]);
    
    for (CBCharacteristic *ch in [service characteristics])
    {
        _charCache[[ch UUID]] = ch;
        if ([[ch UUID] isEqual:[BTManager Notify_Characteristic_UUID]])
        {
            [peripheral setNotifyValue:YES forCharacteristic:ch];   // 啟用 Notify
        }
    }
    
    if (self.onReady)
    {
        NSLog(@"[BLE-DEBUG] Calling onReady block!");
        self.onReady();  // 服務/特徵就緒（含已啟用 Notify）
    }
    else
    {
        NSLog(@"[BLE-DEBUG] Ready, but onReady block is nil?");
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if ([[characteristic UUID] isEqual:[BTManager Batter_Level_Characteristic_UUID]])
    {
        if ([[characteristic value] length] > 0)
        {
            const uint8_t *val = [[characteristic value] bytes];
            uint8_t level = val[0];
            NSLog(@"[BTManager] 🔋 收到電量: %d%%", level);
        }
    }
    
    if (self.onData)
    {
        self.onData(characteristic.value);
    }
}

@end
