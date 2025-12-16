//
//  MainViewController.m
//  PhantomTap
//
//  Created by ethanlin on 2025/10/13.
//

#import "MainViewController.h"
#import "FloatingSidebarBuilder.h"
#import "BluetoothPacketParser.h"
#import "BluetoothPacketBuilder.h"
#import "DeviceResponse.h"
#import "BTManager.h"
#import "HidKeyCodeMap.h"
#import "PhantomTapView.h"
#import "ThirdPartySignInManager.h"
#import "GlobalConfig.h"
#import "Utils.h"
#import "CustomButtonStyleHelper.h"
#import "JsonFilePickerView.h"

@interface MainViewController () <UIGestureRecognizerDelegate>
{
    UIView *_sidebarCollapsed;
    UIView *_sidebarExpanded;
    BOOL _isExpanded;
    
    NSLayoutConstraint *_collapsedTopConstraint;
    NSLayoutConstraint *_collapsedLeadingConstraint;
    NSLayoutConstraint *_expandedTopConstraint;
    NSLayoutConstraint *_expandedLeadingConstraint;
    
    // ===== 封包佇列 + 寫入狀態 + Popup =====
    NSMutableArray<NSData *> *_commandQueue;
    BOOL _isWritingBle;
    CustomPopupDialog *_sendingPopup;
}


@property (nonatomic, strong) NSMutableArray<PhantomTapView *> *phantomTapViewsList;
@property (nonatomic, weak) PhantomTapView *selectedView;
@property (nonatomic, assign) NSInteger viewIdCouner;

@property (nonatomic, strong, nullable) CustomPopupDialog *currentPopup;
@property (nonatomic, weak) UIStackView *jsonFilesStackView;

// @property (nonatomic, strong) UIView *sidebarCollapsed;
// @property (nonatomic, strong) UIView *sidebarExpanded;
// @property (nonatomic, assign) BOOL isExpanded;

// @property (nonatomic, strong) NSLayoutConstraint *sidebarTopConstraint;
// @property (nonatomic, strong) NSLayoutConstraint *sidebarLeadingConstraint;

@end


@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // UI
    [self setupSidebar];
    
    // BTManger Callback
    [self setupBTManagerCallback];
    
    self -> _phantomTapViewsList = [NSMutableArray array];
    self -> _viewIdCouner = 0;
    
    self -> _commandQueue = [NSMutableArray array];
    self -> _isWritingBle = NO;
    self -> _sendingPopup = nil;
    
    // Test API
    [self testAPI];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    BOOL ok = [self becomeFirstResponder];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self becomeFirstResponder];
    });
    NSLog(@"[DEBUG] becomeFirstResponder() called, result=%@", ok ? @"YES" : @"NO");
}


#pragma mark - BTManager Callback

- (void)setupBTManagerCallback
{
    // BLE callbacks
    __weak typeof(self) weakSelf = self;
    
    // 連線就緒後，例如送一次螢幕校正
    [BTManager shared].onReady = ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        
        NSLog(@"[BLE] ✅ Peripheral ready, sending calibration...");
        [self sendCalibration];
        
        // 校正到了，給韌體一個喘息時間再讀回確認
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self readScreenSettingOnce];
        });
    };
    
    
    [BTManager shared].onData = ^(NSData * _Nonnull aData) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        
        NSLog(@"[BLE] onData notify len=%lu bytes,\nhex=%@", (unsigned long)[aData length], [BTManager byteArrayToHexString:aData]);
        
        NSDictionary *km = [BluetoothPacketParser parseKeyMappingRead:aData];
        if (km)
        {
            NSLog(@"[PARSE] keyIndex=%@, hid=%@, x=%@, y=%@", km[@"keyIndex"], km[@"hidCode"], km[@"x"], km[@"y"]);
            return;
        }
        
        DeviceResponse *mr = [BluetoothPacketParser parse:aData];
        if (mr)
        {
            NSLog(@"[PARSE] macro result keyIndex=%ld, success=%d", (long)mr.keyIndex, mr.success);
            
            if (mr.success)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self -> _sendingPopup)
                    {
                        [self->_sendingPopup dismiss];
                        self->_sendingPopup = nil;
                    }
                    
                    [CustomPopupDialog showInView:[self view] style:CustomPopupDialogStyleSingleButton title:NSLocalizedString(@"notice", nil) message:NSLocalizedString(@"all_commands_are_completed", nil) positiveButtonLabel:NSLocalizedString(@"ok", nil) negativeButtonLabel:nil onPositive:^{
                        // 按 OK 目前不用做事
                    } onNegative:nil];
                });
            }
            return;
        }
        
        
        NSLog(@"[PARSE] onData unknown packet");
    };
}



#pragma mark - Calibration

- (void)sendCalibration
{
    // 使用原生像素（和你 Android 版邏輯一致）
    CGSize nb = [[UIScreen mainScreen] nativeBounds].size;
    NSData *pkt = [BluetoothPacketBuilder buildScreenCalibrationPacketWithWidth:(NSInteger)nb.width height:(NSInteger)nb.height];
    
    [[BTManager shared] write:pkt toService:[BTManager Custom_Service_UUID] characteristic:[BTManager Write_Characteristic_UUID] withResponse:NO];
    
    NSLog(@"[WRITE] calibration pixels=%gx%g (iOS=1)", nb.width, nb.height);
}


#pragma mark - 測試 Demo: 寫入五顆 + 讀回一顆驗證

- (IBAction)testReadB201:(id)aSender
{
    [[BTManager shared] readB201];
}

- (void)writeFiveKeysDemo
{
    // 這裡示範用畫面五個位置（請自行改成你 UI 上計算的座標）
    // 注意：硬體協定用「螢幕像素」→ iOS 我們用 nativeBounds 像素計
    
    CGSize nb = [[UIScreen mainScreen] nativeBounds].size;
    NSInteger H = (NSInteger)nb.height;
    NSInteger W = (NSInteger)nb.width;
    
    // 底列五顆
    NSInteger y = (H * 0.42);   // 例：橫向時約略接近底部區域；直向時你可自行換算
    NSArray<NSNumber *> *xs = @[
        @(W * 0.25),
        @(W * 0.35),
        @(W * 0.45),
        @(W * 0.60),
        @(W * 0.75),
    ];
    NSArray<NSString *> *labels = @[ @"1", @"2", @"3", @"4", @"5" ];
    
    for (NSInteger i = 0; i < [labels count]; i++)
    {
        NSString *lab = labels[i];
        NSNumber *idxNum = [HidKeyCodeMap keyIndexForLabel:lab];
        if (!idxNum)
        {
            NSLog(@"[DEMO] skip label %@ (no keyIndex)", lab);
            continue;
        }
        
        NSInteger keyIndex = [idxNum integerValue];
        NSInteger x = [xs[i] integerValue];
        
        // HID keycode 目前你是固定 0x00；若要實際按鍵，也可用 [HidKeyCodeMap hidCodeForLabel:lab]
        NSData *pkt = [BluetoothPacketBuilder buildKeyMappingPacketWithKeyIndex:keyIndex keyCode:0x00 x:x y:y];
        
        [[BTManager shared] write:pkt toService:[BTManager Custom_Service_UUID] characteristic:[BTManager Write_Characteristic_UUID] withResponse:NO];
        NSLog(@"[WRITE] key=%@ idx=%ld -> x=%ld y=%ld", lab, (long)keyIndex, (long)x, (long)y);
    }
    
    // ✅ 小延遲後讀回一顆驗證（以 '5' 為例）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(300 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        NSNumber *idx5 = [HidKeyCodeMap keyIndexForLabel:@"5"];
        if (!idx5) return;
        NSData *readPkt = [BluetoothPacketBuilder readKeyMappingPacket:[idx5 integerValue]];
        [[BTManager shared] write:readPkt toService:[BTManager Custom_Service_UUID] characteristic:[BTManager Write_Characteristic_UUID] withResponse:NO];
        NSLog(@"[READ] request keyIndex=%ld", (long)[idx5 integerValue]);
    });
}


- (void)readScreenSettingOnce
{
    NSData *pkt = [BluetoothPacketBuilder readScreenSetting];
    [[BTManager shared] write:pkt toService:[BTManager Custom_Service_UUID] characteristic:[BTManager Write_Characteristic_UUID] withResponse:NO];
    NSLog(@"[READ] request screen setting");
}


#pragma mark - Sidebar UI (build & drag)

- (void)setupSidebar
{
    _sidebarCollapsed = [FloatingSidebarBuilder collapsedBarWithTarget:self];
    _sidebarExpanded = [FloatingSidebarBuilder expandedBarWithTarget:self];
    
    [self.contentView addSubview:_sidebarCollapsed];
    [self.contentView addSubview:_sidebarExpanded];
    
    UILayoutGuide *g = [self.contentView safeAreaLayoutGuide];
    
    // 建立並儲存 collapsed bar 的約束
    _collapsedTopConstraint = [[_sidebarCollapsed topAnchor] constraintEqualToAnchor:[g topAnchor] constant:8];
    _collapsedLeadingConstraint = [[_sidebarCollapsed leadingAnchor] constraintEqualToAnchor:[self.contentView leadingAnchor] constant:8];
    
    // 建立 expanded bar 的約束
    _expandedTopConstraint = [[_sidebarExpanded topAnchor] constraintEqualToAnchor:[g topAnchor] constant:8];
    _expandedLeadingConstraint = [[_sidebarExpanded leadingAnchor] constraintEqualToAnchor:[self.contentView leadingAnchor] constant:8];
    
    NSLayoutConstraint *maxHeightConstraint = [[_sidebarExpanded heightAnchor] constraintLessThanOrEqualToAnchor:[g heightAnchor] constant:-16];
    
    [NSLayoutConstraint activateConstraints:@[
        _collapsedTopConstraint,
        _collapsedLeadingConstraint,
        
        _expandedTopConstraint,
        _expandedLeadingConstraint,
        
        maxHeightConstraint,
    ]];
    
    
    /* 原來的方法
    [NSLayoutConstraint activateConstraints:@[
        [[_sidebarCollapsed leadingAnchor] constraintEqualToAnchor:[self.contentView leadingAnchor] constant:8],
        [[_sidebarCollapsed topAnchor] constraintEqualToAnchor:[g topAnchor] constant:8],
        
        [[_sidebarExpanded leadingAnchor] constraintEqualToAnchor:[self.contentView leadingAnchor] constant:8],
        [[_sidebarExpanded topAnchor] constraintEqualToAnchor:[g topAnchor] constant:8],
    ]];
    */
    
    _isExpanded = NO;
    [_sidebarExpanded setHidden:YES];
    [_sidebarCollapsed setHidden:NO];
    
    // ✅ Drag Button
    UIView *dragButtonCollapsed = [_sidebarCollapsed viewWithTag:[FloatingSidebarBuilder getDragButtonTag]];
    UIView *dragButtonExpanded = [_sidebarExpanded viewWithTag:[FloatingSidebarBuilder getDragButtonTag]];
    
    UIPanGestureRecognizer *panCollapsed = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    [dragButtonCollapsed addGestureRecognizer:panCollapsed];
    // [panCollapsed setCancelsTouchesInView:NO];
    // [panCollapsed setDelegate:(id<UIGestureRecognizerDelegate>)self];
    // [_sidebarCollapsed addGestureRecognizer:panCollapsed];
    
    
    UIPanGestureRecognizer *panExpanded = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    [dragButtonExpanded addGestureRecognizer:panExpanded];
    // [panExpanded setCancelsTouchesInView:NO];
    // [panExpanded setDelegate:(id<UIGestureRecognizerDelegate>)self];
    // [_sidebarExpanded addGestureRecognizer:panExpanded];
}


#pragma mark - Drag whole bar

- (void)onPan:(UIPanGestureRecognizer *)aPan
{
    // UIView *bar = _isExpanded ? _sidebarExpanded : _sidebarCollapsed;
    CGPoint t = [aPan translationInView:self.contentView];
    
    if ([aPan state] == UIGestureRecognizerStateChanged)
    {
        _collapsedLeadingConstraint.constant += t.x;
        _collapsedTopConstraint.constant += t.y;
        
        _expandedLeadingConstraint.constant += t.x;
        _expandedTopConstraint.constant += t.y;
        
        // 原來的方法
        // [bar setCenter:CGPointMake([bar center].x + t.x, [bar center].y + t.y)];
        
        [aPan setTranslation:CGPointZero inView:self.contentView];
    }
    else if ([aPan state] == UIGestureRecognizerStateEnded)
    {
        
    }
}



#pragma mark - FloatingSidebarActions (buttons)
- (void)onTapAddPhantomTap
{
    CGSize nb = UIScreen.mainScreen.nativeBounds.size; // pixels
    
    // 取得目前方向
    BOOL isLandscape = (nb.width > nb.height);
    NSString *orientationStr = isLandscape ? @"LANDSCAPE" : @"PORTRAIT";
    
    const CGFloat defaultSize = 80.0;
    CGPoint center = CGPointMake(CGRectGetMidX(self.contentView.bounds), CGRectGetMidY(self.contentView.bounds));
    CGFloat posX_pts = center.x - defaultSize * 0.5;
    CGFloat posY_pts = center.y - defaultSize * 0.5;
    
    // 建 TapAction
    TapAction *action = [[TapAction alloc] initWithId:self.viewIdCouner++ orientation:orientationStr screenW:(NSInteger)nb.width screenH:(NSInteger)nb.height posX:posX_pts posY:posY_pts keyCode:@"null" pressEvent:YES];
    
    __weak typeof(self) wself = self;
    PhantomTapView *ptv = [[PhantomTapView alloc] initWithAction:action onSelected:^(PhantomTapView * _Nonnull aPhantomTapView) {
        // 單選
        __strong typeof(wself) self = wself;
        for(PhantomTapView *other in self.phantomTapViewsList)
        {
            other.viewSelected = (other == aPhantomTapView);
        }
        self.selectedView = aPhantomTapView;
        [aPhantomTapView.superview bringSubviewToFront:aPhantomTapView];
        if (![self isFirstResponder]) [self becomeFirstResponder];
    } onDelete:^(PhantomTapView * _Nonnull aPhantomTapView) {
        __strong typeof(wself) self = wself;
        [aPhantomTapView removeFromSuperview];
        [self.phantomTapViewsList removeObject:aPhantomTapView];
        if (self.selectedView == aPhantomTapView) self.selectedView = nil;
    } onPositionCommed:^(PhantomTapView * _Nonnull aPhantomTapView) {
        // 位置落定時，如果要保守一點，可再夾一次到容器內
        [aPhantomTapView clampIntoSuperviewBounds];
    }];
    
    // 加到畫面（用 frame 佈局，不走 Auto Layout）
    [self.contentView addSubview:ptv];
    [self -> _phantomTapViewsList addObject:ptv];
    
    // 預設選中剛新增的點
    for (PhantomTapView *other in self.phantomTapViewsList)
    {
        other.viewSelected = (other == ptv);
    }
    self.selectedView = ptv;
    
    [self becomeFirstResponder];
}

- (void)onTapPickPhoto
{
    if (@available(iOS 14, *))
    {
        PHPickerConfiguration *cfg = [[PHPickerConfiguration alloc] init];
        [cfg setFilter:[PHPickerFilter imagesFilter]];
        [cfg setSelectionLimit:1];
        
        PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:cfg];
        [picker setDelegate:self];
        [picker setModalPresentationStyle:UIModalPresentationFullScreen];
        [self presentViewController:picker animated:YES completion:nil];
    }
    else
    {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        [picker setDelegate:self];
        [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (void)onTapSave
{
    [self showSaveNicknameDialog];
}

- (void)onTapUpload
{
    [self showJsonFilePicker];
}

- (void)onTapClear
{
    for (PhantomTapView *v in self -> _phantomTapViewsList)
    {
        [v removeFromSuperview];
    }
    [self -> _phantomTapViewsList removeAllObjects];
    self.selectedView = nil;
    self.viewIdCouner = 0;
}

- (void)onWriteToKeyboard
{
    // 檢查是否有連線中的裝置
    if (![[BTManager shared] getConnected])
    {
        NSLog(@"[WRITE] abort: no connected peripheral.");
        [self showInfoPopupWithTitle:NSLocalizedString(@"notice", nil) message:NSLocalizedString(@"keyboard_is_not_connected_check_your_ble_connection", nil)];
        
        return;
    }
    
    if ([self -> _phantomTapViewsList count] == 0)
    {
        NSLog(@"[WRITE] no points to send");
        [self showInfoPopupWithTitle:NSLocalizedString(@"notice", nil) message:NSLocalizedString(@"no_points_available_to_write", nil)];
        
        return;
    }
    
    // 檢查是否有 "null" key，或重複 key
    NSMutableSet<NSString *> *keys = [NSMutableSet set];
    for (PhantomTapView *v in self -> _phantomTapViewsList)
    {
        NSString *k = v.action.keyCode ?: @"null";
        if ([k isEqualToString:@"null"])
        {
            NSLog(@"[WRITE] found null key, abort");
            [self showInfoPopupWithTitle:NSLocalizedString(@"notice", nil) message:NSLocalizedString(@"all_items_must_have_a_keycode_assigned", nil)];
            return;
        }
        if ([keys containsObject:k])
        {
            NSLog(@"[WRITE] duplicated key=%@", k);
            [self showInfoPopupWithTitle:NSLocalizedString(@"notice", nil) message:NSLocalizedString(@"duplicate_keys_detected_fix_them_before_submitting", nil)];
            return;
        }
        [keys addObject:k];
    }
 
    // 依照 id 排序，固定順序
    NSArray<PhantomTapView *> *ordered = [self.phantomTapViewsList sortedArrayUsingComparator:^NSComparisonResult(PhantomTapView *a, PhantomTapView *b) {
            return (a.action.actionId < b.action.actionId) ? NSOrderedAscending :
                   (a.action.actionId > b.action.actionId) ? NSOrderedDescending : NSOrderedSame;
        }];
    
    // [self showLoadingPopupWithTitle:NSLocalizedString(@"sending", nil) message:NSLocalizedString(@"sending_commands_to_keyboard", nil)];
    [_commandQueue removeAllObjects];
    
    // 逐一打包並寫入
    for (PhantomTapView *v in ordered)
    {
        NSString *label = v.action.keyCode;
        NSNumber *keyIndexNum = [HidKeyCodeMap keyIndexForLabel:label];
        NSNumber *hidCodeNum  = [HidKeyCodeMap hidCodeForLabel:label]; // 目前你的韌體忽略 HID，可先填 0
        if (!keyIndexNum)
        {
            NSLog(@"[WRITE] keyIndex not found for label=%@", label);
            NSString *msg = [NSString stringWithFormat:@"無法取得按鍵 %@ 的索引，請確認對應表。", label];
            [self showInfoPopupWithTitle:NSLocalizedString(@"notice", nil) message:msg];
            
            return;
        }
        
        CGPoint px = [self screenCenterInPixelsForView:v];
        px = [self clampPixelPointToScreen:px];

        NSData *pkt = [BluetoothPacketBuilder buildKeyMappingPacketWithKeyIndex:keyIndexNum.integerValue
                                                                        keyCode:(hidCodeNum ? hidCodeNum.integerValue : 0)
                                                                              x:(NSInteger)lrint(px.x)
                                                                              y:(NSInteger)lrint(px.y)];
        
        [_commandQueue addObject:pkt];
        
//        [BTManager.shared write:pkt
//                              toService:[BTManager Custom_Service_UUID]
//                         characteristic:[BTManager Write_Characteristic_UUID]
//                          withResponse:NO];

        NSLog(@"[WRITE] key=%@ idx=%@ -> x=%ld y=%ld", label, keyIndexNum, (long)lrint(px.x), (long)lrint(px.y));
    }
    
    // 真正開始送
    [self startSendingCommandQueue];
    
    // [self showInfoPopupWithTitle:NSLocalizedString(@"notice", nil) message:NSLocalizedString(@"all_commands_are_completed", nil)];
    // for testing
    // [self readScreenSettingOnce];
    // [self writeFiveKeysDemo];
}

- (void)toggleSidebar
{
    _isExpanded = !_isExpanded;
    UIView *toShow = _isExpanded ? _sidebarExpanded : _sidebarCollapsed;
    UIView *toHide = _isExpanded ? _sidebarCollapsed : _sidebarExpanded;
    
    [toShow setUserInteractionEnabled:YES];
    [toHide setUserInteractionEnabled:NO];
    
    // 切換只改 hidden/alpha，不動 AutoLayout，畫面穩定
    [toShow setAlpha:0.0];
    [toShow setHidden:NO];
    [UIView animateWithDuration:0.18 animations:^{
        [toShow setAlpha:1.0];
        [toHide setAlpha:0.0];
    } completion:^(BOOL finished) {
        [toHide setHidden:YES];
        [toHide setAlpha:1.0];
    }];
    
    NSLog(@"%@, toggleSidebar %d", [GlobalConfig DebugTag], _isExpanded);
}

#pragma mark - BLE write queue

- (void)startSendingCommandQueue
{
    if ([_commandQueue count] == 0)
    {
        NSLog(@"[QUEUE] no packets to send.");
        return;
    }
    
    if (_isWritingBle)
    {
        NSLog(@"[QUEUE] already sending, skip start.");
        return;
    }
    
    _isWritingBle = YES;
    
    if (!_sendingPopup)
    {
        _sendingPopup = [CustomPopupDialog showLoadingInView:[self view] title:NSLocalizedString(@"sending", nil) message:NSLocalizedString(@"sending_commands_to_keyboard", nil)];
    }
    
    [self processCommandQueue];
}

- (void)processCommandQueue
{
    if ([_commandQueue count] == 0)
    {
        NSLog(@"[QUEUE] no packets to send.");
        _isWritingBle = NO;
        return;
    }
    
    NSData *pkt = [_commandQueue firstObject];
    [_commandQueue removeObjectAtIndex:0];
    
    NSLog(@"[QUEUE] send packet, remain=%lu, len=%lu", (unsigned long)[_commandQueue count], (unsigned long)[pkt length]);
    
    [[BTManager shared] write:pkt toService:[BTManager Custom_Service_UUID] characteristic:[BTManager Write_Characteristic_UUID] withResponse:NO];
    
    __weak typeof(self) wself = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        __strong typeof(wself) self = wself;
        if (!self) return;
        [self processCommandQueue];
    });
}



#pragma mark - UIImagePickerControllerDelegate

// iOS 14+
- (void)picker:(PHPickerViewController *)picker didFinishPicking:(nonnull NSArray<PHPickerResult *> *)results API_AVAILABLE(ios(14.0))
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    PHPickerResult *first = [results firstObject];
    if (!first) return;
    
    NSItemProvider *prov = [first itemProvider];
    if ([prov canLoadObjectOfClass:[UIImage class]])
    {
        __weak typeof(self) wself = self;
        [prov loadObjectOfClass:[UIImage class] completionHandler:^(__kindof id<NSItemProviderReading>  _Nullable object, NSError * _Nullable error) {
            if (!object || ![object isKindOfClass:[UIImage class]])
            {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(wself) self = wself;
                [self -> _imageView setImage:(UIImage *)object];
            });
        }];
    }
}

// iOS 13- fallback
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info
{
    UIImage *img = info[UIImagePickerControllerOriginalImage] ?: info[UIImagePickerControllerEditedImage];
    [self -> _imageView setImage:img];
    [picker dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([[touch view] isKindOfClass:[UIControl class]] || [[touch view] isKindOfClass:[UIButton class]])
    {
        return NO;
    }
    
    return YES;
}



#pragma mark - Utils

- (void)readKeyIndex:(NSInteger)aKeyIndex
{
    NSData *pkt = [BluetoothPacketBuilder readKeyMappingPacket:aKeyIndex];
    [[BTManager shared] write:pkt toService:[BTManager Custom_Service_UUID] characteristic:[BTManager Read_Characteristic_UUID] withResponse:NO];
    
    NSLog(@"[WRITE] ReadKeyMapping index=%ld", (long)aKeyIndex);
}


/// 取得某個 view 的「螢幕座標系中心點（像素）」
- (CGPoint)screenCenterInPixelsForView:(UIView *)aView
{
    // 1) 轉到 window（points）
    UIWindow *win = [[self view] window];
    if (!win)
    {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes)
        {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]])
            {
                UIWindowScene *ws = (UIWindowScene *)scene;
                win = ws.keyWindow ?: ws.windows.firstObject;
                if (win) break;
            }
        }
    }
    CGPoint centerInSelf = CGPointMake(CGRectGetMidX(aView.bounds), CGRectGetMidY(aView.bounds));
    CGPoint centerInWindowPts = [aView convertPoint:centerInSelf toView:win];

    // 2) 轉 pixels
    CGFloat scale = UIScreen.mainScreen.nativeScale; // matches nativeBounds
    return CGPointMake(centerInWindowPts.x * scale, centerInWindowPts.y * scale);
}

/// 把像素座標夾在螢幕像素尺寸內（避免 970 之類上限問題）
- (CGPoint)clampPixelPointToScreen:(CGPoint)aP
{
    CGSize nb = UIScreen.mainScreen.nativeBounds.size; // pixels
    CGFloat x = MAX(0, MIN(aP.x, nb.width  - 1));
    CGFloat y = MAX(0, MIN(aP.y, nb.height - 1));
    return CGPointMake(x, y);
}


#pragma mark - Popup helpers

- (void)showInfoPopupWithTitle:(NSString *)aTitle message:(NSString *)aMessage
{
    // 先把舊的收掉，避免堆疊
    [self dismissCurrentPopup];
    
    CustomPopupDialog *popup = [CustomPopupDialog showInView:[self view] style:CustomPopupDialogStyleSingleButton title:aTitle message:aMessage positiveButtonLabel:NSLocalizedString(@"ok", nil) negativeButtonLabel:nil onPositive:^{
        [self -> _currentPopup dismiss];
        self -> _currentPopup = nil;
    } onNegative:nil];
    
    self -> _currentPopup = popup;
}


- (void)showLoadingPopupWithTitle:(NSString *)aTitle message:(NSString *)aMessage
{
    [self dismissCurrentPopup];
    
    CustomPopupDialog *popup = [CustomPopupDialog showLoadingInView:[self view] title:aTitle message:aMessage];
    
    self -> _currentPopup = popup;
}

- (void)dismissCurrentPopup
{
    [self -> _currentPopup dismiss];
    self -> _currentPopup = nil;
}


#pragma mark - First Responder for HW Keyboard

- (BOOL)canBecomeFirstResponder
{
    NSLog(@"[DEBUG] canBecomeFirstResponder called -> YES");
    return YES;
}



#pragma mark - Key Commands

- (NSArray<UIKeyCommand *> *)keyCommands
{
    static NSArray<UIKeyCommand *> *cmds;
    if (cmds) return cmds;
    
    NSMutableArray *arr = [NSMutableArray array];
    
    // A - Z
    for (unichar c = 'A'; c <= 'Z'; c++)
    {
        NSString *s = [NSString stringWithCharacters:&c length:1];
        [arr addObject:[UIKeyCommand keyCommandWithInput:s modifierFlags:0 action:@selector(onKeyCommand:)]];
    }
    
    // 0 - 9
    for (unichar c = '0'; c <= '9'; c++)
    {
        NSString *s = [NSString stringWithCharacters:&c length:1];
        [arr addObject:[UIKeyCommand keyCommandWithInput:s modifierFlags:0 action:@selector(onKeyCommand:)]];
    }
    
    // Space
    [arr addObject:[UIKeyCommand keyCommandWithInput:@" " modifierFlags:0 action:@selector(onKeyCommand:)]];

    // Arrows
    [arr addObject:[UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:0 action:@selector(onKeyCommand:)]];
    [arr addObject:[UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow modifierFlags:0 action:@selector(onKeyCommand:)]];
    [arr addObject:[UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow modifierFlags:0 action:@selector(onKeyCommand:)]];
    [arr addObject:[UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow modifierFlags:0 action:@selector(onKeyCommand:)]];

    cmds = arr.copy;
    return cmds;
}


- (void)onKeyCommand:(UIKeyCommand *)aCommand
{
    NSLog(@"[KEYCOMMAND] detected key input: %@", [aCommand input]);
    if (!self -> _selectedView) return;
    
    NSString *label = [aCommand input];
    if (label == UIKeyInputUpArrow) label = @"UpArrow";
    else if (label == UIKeyInputDownArrow) label = @"DownArrow";
    else if (label == UIKeyInputLeftArrow) label = @"LeftArrow";
    else if (label == UIKeyInputRightArrow) label = @"RightArrow";
    else if ([label isEqualToString:@" "]) label = @"SPACE";
    else label = label.uppercaseString;
    
    if ([self isKeyLabel:label usedByOtherThan:self -> _selectedView])
    {
        // [self showInfoPopupWithTitle:NSLocalizedString(@"notice", nil) message:NSLocalizedString(@"duplicate_keys_detected_fix_them_before_submitting", nil)];
        NSLog(@"duplicate_keys_detected_fix_them_before_submitting");
        return;
    }
    
    [self -> _selectedView updateKeyCode:label];
}

- (BOOL)isKeyLabel:(NSString *)aLabel usedByOtherThan:(PhantomTapView *)aCurrent
{
    if ([aLabel length] == 0 || [aLabel isEqualToString:@"null"])
    {
        return NO;
    }
    
    for (PhantomTapView *v in self -> _phantomTapViewsList)
    {
        if (v == aCurrent) continue;
        NSString *key = v.action.keyCode ?: @"null";
        if ([key isEqualToString:aLabel])
        {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - Save keymap (to JSON)

- (void)showSaveNicknameDialog
{
    // 如果沒有任何 PhantomTapView → popup 提醒
    if ([self -> _phantomTapViewsList count] == 0)
    {
        CustomPopupDialog *popup = [CustomPopupDialog showInView:[self view] style:CustomPopupDialogStyleSingleButton title:NSLocalizedString(@"notice", nil) message:NSLocalizedString(@"no_items_can_be_saved", nil) positiveButtonLabel:NSLocalizedString(@"ok", nil) negativeButtonLabel:nil onPositive:nil onNegative:nil];
        
        __weak CustomPopupDialog *weakPopup = popup;
        popup.onPositive = ^{
            NSLog(@"[DEBUG] no_items_can_be_saved OK tapped");
            [weakPopup dismiss];
        };
        return;
    }
    
    //檢查是否都有 keyCode，並且不能重複
    NSMutableSet *seen = [NSMutableSet set];
    for (PhantomTapView *ptv in self -> _phantomTapViewsList)
    {
        NSString *key = ptv.action.keyCode ?: @"null";
        
        if ([key isEqualToString:@"null"])
        {
            CustomPopupDialog *popup = [CustomPopupDialog showInView:[self view] style:CustomPopupDialogStyleSingleButton title:NSLocalizedString(@"notice", nil) message:NSLocalizedString(@"all_items_must_have_a_keycode_assigned", nil) positiveButtonLabel:NSLocalizedString(@"ok", nil) negativeButtonLabel:nil onPositive:nil onNegative:nil];
            __weak CustomPopupDialog *weakPopup = popup;
            popup.onPositive = ^{
                NSLog(@"[DEBUG] no_items_can_be_saved OK tapped");
                [weakPopup dismiss];
            };
            return;
        }
        
        if ([seen containsObject:key])
        {
            CustomPopupDialog *popup = [CustomPopupDialog showInView:[self view] style:CustomPopupDialogStyleSingleButton title:NSLocalizedString(@"notice", nil) message:NSLocalizedString(@"duplicate_keys_detected_fix_them_before_submitting", nil) positiveButtonLabel:NSLocalizedString(@"ok", nil) negativeButtonLabel:nil onPositive:nil onNegative:nil];
            __weak CustomPopupDialog *weakPopup = popup;
            popup.onPositive = ^{
                NSLog(@"[DEBUG] no_items_can_be_saved OK tapped");
                [weakPopup dismiss];
            };
            return;
        }
        
        [seen addObject:key];
    }
    
    //建立輸入暱稱的自訂 UIView（像 Android 的 EditText popup）
    UIView *dialogView = [[UIView alloc] initWithFrame:CGRectZero];
    [dialogView setBackgroundColor:[UIColor whiteColor]];
    [[dialogView layer] setCornerRadius:12.0];
    [dialogView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [titleLabel setText:NSLocalizedString(@"save_file", nil)];
    [titleLabel setTextColor:[UIColor blackColor]];
    [titleLabel setFont:[UIFont boldSystemFontOfSize:17]];
    [titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    UITextField *nicknameField = [[UITextField alloc] initWithFrame:CGRectZero];
    [nicknameField setBorderStyle:UITextBorderStyleNone];
    [nicknameField setBackgroundColor:[UIColor clearColor]];
    [nicknameField setTextColor:[UIColor colorWithWhite:0.1 alpha:1.0]]; // 超深灰
    [nicknameField setTranslatesAutoresizingMaskIntoConstraints:NO];
    [nicknameField setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"please_input_file_name", nil) attributes:@{ NSForegroundColorAttributeName : [UIColor lightGrayColor] }]];
    
    // 底線
    UIView *underline = [[UIView alloc] initWithFrame:CGRectZero];
    [underline setTranslatesAutoresizingMaskIntoConstraints:NO];
    [underline setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.2]];
    
    [dialogView addSubview:titleLabel];
    [dialogView addSubview:nicknameField];
    [dialogView addSubview:underline];
    
    [NSLayoutConstraint activateConstraints:@[
        [[titleLabel topAnchor] constraintEqualToAnchor:[dialogView topAnchor] constant:8],
        [[titleLabel leadingAnchor] constraintEqualToAnchor:[dialogView leadingAnchor] constant:0],
        [[titleLabel trailingAnchor] constraintEqualToAnchor:[dialogView trailingAnchor] constant:0],
        
        [[nicknameField topAnchor] constraintEqualToAnchor:[titleLabel bottomAnchor] constant:16],
        [[nicknameField leadingAnchor] constraintEqualToAnchor:[dialogView leadingAnchor]],
        [[nicknameField trailingAnchor] constraintEqualToAnchor:[dialogView trailingAnchor]],
        [[nicknameField heightAnchor] constraintEqualToConstant:40],
        
        [[underline topAnchor] constraintEqualToAnchor:[nicknameField bottomAnchor] constant:4],
        [[underline leadingAnchor] constraintEqualToAnchor:[dialogView leadingAnchor]],
        [[underline trailingAnchor] constraintEqualToAnchor:[dialogView trailingAnchor]],
        [[underline heightAnchor] constraintEqualToConstant:1],
        
        [[underline bottomAnchor] constraintEqualToAnchor:[dialogView bottomAnchor]],
    ]];
    
    // 外層 CustomPopup → 兩個按鈕：Save / Cancel
    __weak typeof(self) weakSelf = self;
    
    CustomPopupDialog *popup = [CustomPopupDialog showInView:[self view] style:CustomPopupDialogStyleDoubleButton title:NSLocalizedString(@"notice", nil) message:nil positiveButtonLabel:NSLocalizedString(@"ok", nil) negativeButtonLabel:NSLocalizedString(@"cancel", nil) onPositive:nil onNegative:nil];
    
    __weak CustomPopupDialog *weakPopup = popup;
    popup.onPositive = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        NSString *nicknaame = [[nicknameField text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ([nicknaame length] == 0)
        {
            [[nicknameField layer] setBorderColor:[[UIColor redColor] CGColor]];
            [[nicknameField layer] setBorderWidth:1.0];
            return;
        }
        
        [weakPopup dismiss];
        [strongSelf saveDataToJson:nicknaame];
    };
    popup.onNegative = ^{
        [weakPopup dismiss];
    };
    
    [[popup cardView] addSubview:dialogView];
    
    [NSLayoutConstraint activateConstraints:@[
        [[dialogView topAnchor] constraintEqualToAnchor:[[popup cardView] topAnchor] constant:20],
        [[dialogView leadingAnchor] constraintEqualToAnchor:[[popup cardView] leadingAnchor] constant:20],
        [[dialogView trailingAnchor] constraintEqualToAnchor:[[popup cardView] trailingAnchor] constant:-20],
        [[dialogView bottomAnchor] constraintLessThanOrEqualToAnchor:[[popup cardView] bottomAnchor] constant:-70.0],
    ]];
}

- (void)saveDataToJson:(NSString *)aNickname
{
    CGSize nb = [[UIScreen mainScreen] nativeBounds].size;
    NSInteger pW = (NSInteger)nb.width;
    NSInteger pH = (NSInteger)nb.height;
    
    NSMutableArray<id<KeymapAction>> *actions = [NSMutableArray array];
    for (PhantomTapView *v in self -> _phantomTapViewsList)
    {
        CGPoint px = [v centerOnScreen];  // 這裡已經是 pixels
        
        v.action.posX = px.x;
        v.action.posY = px.y;
        
        [actions addObject:v.action];
    }
    NSString *createAt = [Utils currentISO8601String];
    KeymapFile *file = [[KeymapFile alloc] initWithVersion:[GlobalConfig JSON_VERSION] createdAt:createAt nickname:aNickname portraitW:pW portraitH:pH rotationWhenSaved:0 actions:actions];
    
    NSError *err = nil;
    NSData *jsonData = [file toJSONPretty:YES error:&err];
    if (err || !jsonData)
    {
        CustomPopupDialog *popup = [CustomPopupDialog showInView:[self view] style:CustomPopupDialogStyleSingleButton title:NSLocalizedString(@"notice", nil) message:NSLocalizedString(@"try_again_later", nil) positiveButtonLabel:NSLocalizedString(@"ok", nil) negativeButtonLabel:nil onPositive:nil onNegative:nil];
        __weak CustomPopupDialog *weakPopup = popup;
        popup.onPositive = ^{
            NSLog(@"[DEBUG] try_again_later OK tapped (encode json failed)");
            [weakPopup dismiss];
        };
        return;
    }
    
    // 存到 Documents
    NSString *timestamp = [Utils currentTimestampString];
    NSString *filename = [NSString stringWithFormat:@"%@_%@.json", aNickname, timestamp];
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:filename];
    
    BOOL ok = [jsonData writeToFile:path atomically:YES];
    if (!ok)
    {
        CustomPopupDialog *popup = [CustomPopupDialog showInView:[self view] style:CustomPopupDialogStyleSingleButton title:NSLocalizedString(@"notice", nil) message:NSLocalizedString(@"try_again_later", nil) positiveButtonLabel:NSLocalizedString(@"ok", nil) negativeButtonLabel:nil onPositive:nil onNegative:nil];
        __weak CustomPopupDialog *weakPopup = popup;
        popup.onPositive = ^{
            NSLog(@"[DEBUG] try_again_later OK tapped (write file failed)");
            [weakPopup dismiss];
        };
        return;
    }
    
    // 儲存成功
    NSString *msg = [NSString stringWithFormat:@"%@\n%@", NSLocalizedString(@"saved", nil), filename];
    
    CustomPopupDialog *popup = [CustomPopupDialog showInView:[self view] style:CustomPopupDialogStyleSingleButton title:NSLocalizedString(@"notice", nil) message:msg positiveButtonLabel:NSLocalizedString(@"ok", nil) negativeButtonLabel:nil onPositive:nil onNegative:nil];
    __weak CustomPopupDialog *weakPopup = popup;
    popup.onPositive = ^{
        NSLog(@"[DEBUG] file saved");
        [weakPopup dismiss];
    };
}


#pragma mark - JSON 檔案清單 Popup

- (void)showJsonFilePicker
{
    // 1. 找出 Documents 裡所有 .json
    NSString *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSArray<NSString *> *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docs error:nil];
    
    NSMutableArray<NSURL *> *urls = [NSMutableArray array];
    for (NSString *name in files)
    {
        if ([[name.pathExtension lowercaseString] isEqualToString:@"json"])
        {
            NSString *full = [docs stringByAppendingPathComponent:name];
            NSURL *u = [NSURL fileURLWithPath:full];
            [urls addObject:u];
        }
    }
    
    NSLog(@"urls has %ld", [urls count]);
    
    if (urls.count == 0)
    {
        // 沒檔案 → 用你原本 CustomPopupDialog 提示就好
        CustomPopupDialog *popup =
        [CustomPopupDialog showInView:self.view
                                style:CustomPopupDialogStyleSingleButton
                                title:NSLocalizedString(@"notice", nil)
                              message:NSLocalizedString(@"no_items_can_be_loaded", nil)
                   positiveButtonLabel:NSLocalizedString(@"ok", nil)
                   negativeButtonLabel:nil
                             onPositive:nil
                             onNegative:nil];
        __weak CustomPopupDialog *weakPopup = popup;
        popup.onPositive = ^{
            [weakPopup dismiss];
        };
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    
    [JsonFilePickerView showInView:self.view
                             title:NSLocalizedString(@"select_file", nil)
                              urls:urls
                          onSelect:^(NSURL *fileURL) {
                              __strong typeof(weakSelf) self = weakSelf;
                              if (!self) return;
                              NSLog(@"[MainVC] select json: %@", fileURL);
                              [self loadDataFromJsonAtURL:fileURL];
                          }
                          onDelete:^(NSURL *fileURL) {
                              NSLog(@"[MainVC] delete json: %@", fileURL);
                              NSError *err = nil;
                              [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&err];
                              if (err) {
                                  NSLog(@"[MainVC] delete error: %@", err);
                              }
                          }
                          onCancel:^{
                              NSLog(@"[MainVC] json picker canceled");
                          }];
}
/*
- (void)showJsonFileMenuForURL:(NSURL *)aURL
{
    if (!aURL) return;

    NSString *filename = aURL.lastPathComponent;

    UIAlertController *sheet =
    [UIAlertController alertControllerWithTitle:filename
                                        message:NSLocalizedString(@"choose_action_for_keymap", nil) // ex: "要對這個設定檔做什麼？"
                                 preferredStyle:UIAlertControllerStyleActionSheet];

    __weak typeof(self) weakSelf = self;

    // 載入
    UIAlertAction *loadAction =
    [UIAlertAction actionWithTitle:NSLocalizedString(@"load_keymap", nil)  // ex: "載入這個設定"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"[Keymap] load %@", filename);
        [weakSelf loadDataFromJsonAtURL:aURL];
    }];
    [sheet addAction:loadAction];

    // 刪除
    UIAlertAction *deleteAction =
    [UIAlertAction actionWithTitle:NSLocalizedString(@"delete", nil)
                             style:UIAlertActionStyleDestructive
                           handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"[Keymap] delete %@", filename);
        NSError *err = nil;
        BOOL ok = [[NSFileManager defaultManager] removeItemAtURL:aURL error:&err];
        if (!ok || err) {
            NSLog(@"[Keymap] delete error = %@", err);
            UIAlertController *errAlert =
            [UIAlertController alertControllerWithTitle:NSLocalizedString(@"notice", nil)
                                                message:NSLocalizedString(@"try_again_later", nil)
                                         preferredStyle:UIAlertControllerStyleAlert];
            [errAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil]];
            [weakSelf presentViewController:errAlert animated:YES completion:nil];
            return;
        }

        // 刪掉之後，重新打開列表給使用者看剩下的
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showJsonFilePicker];
        });
    }];
    [sheet addAction:deleteAction];

    UIAlertAction *cancel =
    [UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", nil)
                             style:UIAlertActionStyleCancel
                           handler:nil];
    [sheet addAction:cancel];

    UIPopoverPresentationController *pop = sheet.popoverPresentationController;
    if (pop) {
        pop.sourceView = self.view;
        pop.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds),
                                    CGRectGetMidY(self.view.bounds),
                                    1, 1);
        pop.permittedArrowDirections = 0;
    }

    [self presentViewController:sheet animated:YES completion:nil];
}
*/

- (void)buildJsonFileRowsInStack:(UIStackView *)aStack inPopup:(CustomPopupDialog *)aPopup
{
    if (!aStack || !aPopup) return;
    
    // 先清空舊的 row（避免刪除重建時殘留）
    for (UIView *sub in aStack.arrangedSubviews) {
        [aStack removeArrangedSubview:sub];
        [sub removeFromSuperview];
    }
    
    __weak typeof(self) weakSelf = self;
    __weak typeof(aPopup) weakPopup = aPopup;
    
    [self.jsonFileURLs enumerateObjectsUsingBlock:^(NSURL * _Nonnull url, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *displayName = url.lastPathComponent ?: @"(unknown)";
        
        // ---- 一列：檔名 + DELETE ----
        UIView *row = [[UIView alloc] init];
        row.translatesAutoresizingMaskIntoConstraints = NO;
        row.userInteractionEnabled = YES;
        row.tag = idx;   // 用來辨識是哪一個檔案
        
        UILabel *nameLabel = [[UILabel alloc] init];
        nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        nameLabel.text = displayName;
        nameLabel.font = [UIFont systemFontOfSize:15.0];
        nameLabel.textColor = [UIColor blackColor];
        
        UIButton *deleteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        deleteBtn.translatesAutoresizingMaskIntoConstraints = NO;

        UIButtonConfiguration *config = [UIButtonConfiguration filledButtonConfiguration];
        config.baseBackgroundColor = [UIColor colorWithRed:0.86 green:0.29 blue:0.30 alpha:1.0];
        config.baseForegroundColor = UIColor.whiteColor;   // 字體顏色
        config.cornerStyle = UIButtonConfigurationCornerStyleFixed;
        config.background.cornerRadius = 8;
        config.contentInsets = NSDirectionalEdgeInsetsMake(6, 14, 6, 14);
        config.title = @"delete";

        deleteBtn.configuration = config;
        deleteBtn.tag = idx;
        
        [row addSubview:nameLabel];
        [row addSubview:deleteBtn];
        
        [NSLayoutConstraint activateConstraints:@[
            [nameLabel.leadingAnchor constraintEqualToAnchor:row.leadingAnchor],
            [nameLabel.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
            
            [deleteBtn.trailingAnchor constraintEqualToAnchor:row.trailingAnchor],
            [deleteBtn.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
            
            [nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:deleteBtn.leadingAnchor constant:-12.0],
            
            [row.heightAnchor constraintGreaterThanOrEqualToConstant:40.0],
        ]];
        
        // 點整列 → 載入該 json
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:weakSelf action:@selector(onJsonRowTapped:)];
        [row addGestureRecognizer:tap];
        
        // DELETE 按鈕
        [deleteBtn addAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf deleteJsonAtIndex:idx fromPopup:weakPopup];
        }] forControlEvents:UIControlEventTouchUpInside];
        
        [aStack addArrangedSubview:row];
        
        // 底線（最後一個就不用）
        if (idx != self.jsonFileURLs.count - 1) {
            UIView *sep = [[UIView alloc] init];
            sep.translatesAutoresizingMaskIntoConstraints = NO;
            sep.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
            [sep.heightAnchor constraintEqualToConstant:1.0].active = YES;
            [aStack addArrangedSubview:sep];
        }
    }];
}

- (void)onJsonRowTapped:(UITapGestureRecognizer *)aGR
{
    UIView *row = aGR.view;
    if (!row) return;
    
    NSUInteger idx = (NSUInteger)row.tag;
    if (idx >= self.jsonFileURLs.count) return;
    
    NSURL *url = self.jsonFileURLs[idx];
    NSLog(@"[JSON] row tapped index=%lu url=%@", (unsigned long)idx, url);
    
    // 找到最外層的 CustomPopupDialog，順便關掉
    UIView *v = row;
    while (v && ![v isKindOfClass:[CustomPopupDialog class]]) {
        v = v.superview;
    }
    CustomPopupDialog *popup = (CustomPopupDialog *)v;
    
    [self loadDataFromJsonAtURL:url];
    [popup dismiss];
}

- (void)deleteJsonAtIndex:(NSUInteger)aIndex fromPopup:(CustomPopupDialog *)aPopup
{
    if (aIndex >= self.jsonFileURLs.count) return;
        
        NSURL *url = self.jsonFileURLs[aIndex];
        NSError *err = nil;
        [[NSFileManager defaultManager] removeItemAtURL:url error:&err];
        
        if (err) {
            NSLog(@"[JSON] delete error = %@", err);
            CustomPopupDialog *popup = [CustomPopupDialog showInView:self.view
                                                               style:CustomPopupDialogStyleSingleButton
                                                               title:NSLocalizedString(@"notice", nil)
                                                             message:NSLocalizedString(@"try_again_later", nil)
                                                 positiveButtonLabel:NSLocalizedString(@"ok", nil)
                                                 negativeButtonLabel:nil
                                                           onPositive:nil
                                                           onNegative:nil];
            __weak typeof(popup) weakPopup = popup;
            popup.onPositive = ^{ [weakPopup dismiss]; };
            return;
        }
        
        // 從陣列移除，重畫列表
        [self.jsonFileURLs removeObjectAtIndex:aIndex];
        NSLog(@"[JSON] deleted, remaining=%lu", (unsigned long)self.jsonFileURLs.count);
        
        if (self.jsonFileURLs.count == 0) {
            [aPopup dismiss];
            return;
        }
        
        // 重新 build row
        for (UIView *sub in aPopup.cardView.subviews) {
            if ([sub isKindOfClass:[UIStackView class]]) {
                UIStackView *stack = (UIStackView *)sub;
                [self buildJsonFileRowsInStack:stack inPopup:aPopup];
                break;
            }
        }
}

#pragma mark - Load keymap from JSON

- (void)loadDataFromJsonAtURL:(NSURL *)aURL
{
    if (!aURL)
    {
        NSLog(@"[ERROR] loadDataFromJsonAtURL: url is nil");
        return;
    }
    
    NSLog(@"[DEBUG] loadDataFromJsonAtURL: %@", [aURL path]);
    
    NSData *data = [NSData dataWithContentsOfURL:aURL];
    if (!data) return;
    
    NSError *error = nil;
    KeymapFile *file = [KeymapFile fromJSON:data error:&error];
    
    if (!file || error)
    {
        NSLog(@"[ERROR] load json failed: %@", error);
        return;
    }

    NSLog(@"[DEBUG] loaded keymap: %@, actions=%lu", [file nickname], (unsigned long)[[file actions] count]);

    [self applyLoadedKeymapFile:file];
}

- (void)applyLoadedKeymapFile:(KeymapFile *)aFile
{
    if (!aFile) return;

    NSLog(@"[DEBUG] apply keymap: %@", [aFile nickname]);

    for (UIView *v in self -> _phantomTapViewsList)
    {
        [v removeFromSuperview];
    }
    [self -> _phantomTapViewsList removeAllObjects];
    
    CGSize viewSize = [[self view] bounds].size;
    CGFloat originW = (CGFloat)[aFile portraitW];
    CGFloat originH = (CGFloat)[aFile portraitH];
    
    __weak typeof(self) weakSelf = self;
    
    for (id<KeymapAction> act in [aFile actions])
    {
        if (![act isKindOfClass:[TapAction class]]) continue;
        TapAction *ta = (TapAction *)act;
        
        CGFloat scaleX = (originW > 0) ? viewSize.width / originW : 1.0;
        CGFloat scaleY = (originH > 0) ? viewSize.height / originH : 1.0;
        
        CGPoint center = CGPointMake([ta posX] * scaleX, [ta posY] * scaleY);
        
        PhantomTapView *tapView = [[PhantomTapView alloc] initWithAction:ta onSelected:^(PhantomTapView * _Nonnull aPhantomTapView) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            [strongSelf handleTapViewSeleted:aPhantomTapView];
        } onDelete:^(PhantomTapView * _Nonnull aPhantomTapView) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            [strongSelf handleTapViewDelete:aPhantomTapView];
        } onPositionCommed:^(PhantomTapView * _Nonnull aPhantomTapView) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            [strongSelf onPhantomTapViewPositionCommitted:aPhantomTapView];
        }];
    }
}

#pragma mark - PhantomTapView Handlers

- (void)handleTapViewSeleted:(PhantomTapView *)aSelectedView
{
    for (PhantomTapView *v in self -> _phantomTapViewsList)
    {
        [v setViewSelected:(v == aSelectedView)];
    }
    
    NSLog(@"[Editor] Selected Key: %@", [[aSelectedView action] keyCode]);
}

- (void)handleTapViewDelete:(PhantomTapView *)aDeletedView
{
    [aDeletedView removeFromSuperview];
    
    [self -> _phantomTapViewsList removeObject:aDeletedView];
}

- (void)onPhantomTapViewPositionCommitted:(PhantomTapView *)aPhantomTapView
{
    CGPoint p = [aPhantomTapView centerOnScreen];
    // [aPhantomTapView action].posX = p.x;
    // [aPhantomTapView action].posY = p.y;
    [[aPhantomTapView action] setPosX:p.x];
    [[aPhantomTapView action] setPosY:p.y];
    
    NSLog(@"[DEBUG] position committed id=%ld (%.1f, %.1f)", (long)[[aPhantomTapView action] actionId], p.x, p.y);
}


#pragma mark - API Test
- (void)testAPI
{
    APIClient *client = [APIClient sharedClient];
    NSLog(@"[MainVC] current accessToken = %@", [client getAccessToken]);
    
    if (![client getAccessToken] || [[client getAccessToken] length] == 0)
    {
        NSLog(@"[MainVC] 尚未登入，accessToken 為空");
        return;
    }
    
    [client getMeWithCompletion:^(NSDictionary * _Nullable aJSON, NSError * _Nullable aError) {
        if (aError)
        {
            NSLog(@"[MainVC] /auth/me error = %@", aError);
            dispatch_async(dispatch_get_main_queue(), ^{});
            return;
        }
        
        NSLog(@"[MainVC] /auth/me = %@", aJSON);
        
        NSString *email = aJSON[@"email"];
        NSString *nickname = aJSON[@"nickname"];
        NSString *provider = aJSON[@"login_provider"];
        NSLog(@"[MainVC] email:%@,\nnickname:%@,\nprovider:%@", email, nickname, provider);
        
        dispatch_async(dispatch_get_main_queue(), ^{});
    }];
}

@end
