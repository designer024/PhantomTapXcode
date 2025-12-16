//
//  PhantomTapView.m
//  PhantomTap
//
//  Created by ethanlin on 2025/10/20.
//

#import "PhantomTapView.h"

static const CGFloat kPTVDefaultSize = 56.0;
static const CGFloat kPTVDeleteRadius = 18.0;

@interface PhantomTapView()
{
    CGRect _deleteButtonRect;          // 在本地座標系
    CGPoint _prevCenterInSuperview;    // 拖曳時參考點（superview 座標）
}

@property (nonatomic, strong, readwrite) TapAction *action;

@property (nonatomic, copy, nullable) PhantomTapViewSelectedHandler onSelected;
@property (nonatomic, copy, nullable) PhantomTapViewDeleteHandler onDelete;
@property (nonatomic, copy, nullable) PhantomTapViewPositionCommittedHandler onPositionCommitted;

// @property (nonatomic, strong) UIImage *unselectedImage;
// @property (nonatomic, strong) UIImage *selectedImage;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UIImageView *delecteButtonView;
@property (nonatomic, strong) UILabel *keyLabel;

@end


@implementation PhantomTapView

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)aFrame
{
    NSAssert(NO, @"請使用 initWithAction:...");
    return nil;
}


- (instancetype)initWithCoder:(NSCoder *)aCoder
{
    NSAssert(NO, @"請使用 initWithAction:...");
        return nil;
}


- (instancetype)initWithAction:(TapAction *)aAction onSelected:(PhantomTapViewSelectedHandler)aOnSelected onDelete:(PhantomTapViewDeleteHandler)aOnDelete onPositionCommed:(PhantomTapViewPositionCommittedHandler)aOnPositionCommitted
{
    CGRect f = (CGRect){ CGPointMake(aAction.posX, aAction.posY),
                        CGSizeMake(kPTVDefaultSize, kPTVDefaultSize) };
    self = [super initWithFrame:f];
    if (!self) return nil;
    
    _action = aAction;
    _onSelected = [aOnSelected copy];
    _onDelete = [aOnDelete copy];
    _onPositionCommitted = [aOnPositionCommitted copy];
    
    // 我們用 frame 放置與拖曳，不讓 Auto Layout 介入
    [self setUserInteractionEnabled:YES];
    [self setBackgroundColor:[UIColor clearColor]];

    self -> _iconView = [[UIImageView alloc] initWithFrame:[self bounds]];
    [self -> _iconView setContentMode:UIViewContentModeScaleAspectFit];
    [self -> _iconView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    [self -> _iconView setImage:[UIImage imageNamed:@"phantom_view_unselected"]];
    [self addSubview:self -> _iconView];
    
    self -> _keyLabel = [[UILabel alloc] initWithFrame:[self bounds]];
    [self -> _keyLabel setTextAlignment:NSTextAlignmentCenter];
    [self -> _keyLabel setFont:[UIFont systemFontOfSize:18 weight:UIFontWeightSemibold]];
    [self -> _keyLabel setTextColor:[UIColor whiteColor]];
    [self -> _keyLabel setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    [self addSubview:self -> _keyLabel];
     
    self -> _delecteButtonView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"delecte_view"]];
    [self -> _delecteButtonView setFrame:CGRectMake([self bounds].size.width - 24, 0, 24, 24)];
    [self -> _delecteButtonView setHidden:YES];
    [self addSubview:self -> _delecteButtonView];
    
    [self updateKeyCode:[aAction keyCode]];
    
    return self;
}


#pragma mark - Public API

- (void)setViewSelected:(BOOL)aViewSelected
{
    self -> _viewSelected = aViewSelected;
    
    if (aViewSelected)
    {
        [self -> _iconView setImage:[UIImage imageNamed:@"phantom_view_selected"]];
        [self -> _delecteButtonView setHidden:NO];
    }
    else
    {
        [self -> _iconView setImage:[UIImage imageNamed:@"phantom_view_unselected"]];
        [self -> _delecteButtonView setHidden:YES];
    }
}

- (void)updateKeyCode:(NSString *)aKey
{
    if ([aKey length] == 0) aKey = @"null";
    self -> _action.keyCode = aKey;
    
    NSLog(@"[PTV] updateKeyCode -> %@", aKey);
    if ([aKey isEqualToString:@"null"])
    {
        [self -> _keyLabel setText:@""];
    }
    else
    {
        [self -> _keyLabel setText:aKey];
    }
    //[self setNeedsDisplay];
}



#pragma mark - Touch / Drag

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    // 容易點到（外擴 8px）
    return CGRectContainsPoint(CGRectInset(self.bounds, -8, -8), point);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *t = touches.anyObject; if (!t) return;

    // 點到刪除鈕？
    CGPoint p = [t locationInView:self];
    if (self -> _viewSelected && CGRectContainsPoint([self -> _delecteButtonView frame], p))
    {
        if (self.onDelete) self.onDelete(self);
        return;
    }

    // 用「superview 中心」做拖曳基準，避免 transform 造成的誤差
    _prevCenterInSuperview = self.center;

    if (self.onSelected) self.onSelected(self);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *t = [touches anyObject];
    if (!t) return;

    CGPoint cur = [t locationInView:[self superview]];
    CGPoint prev = _prevCenterInSuperview;
    CGFloat dx = cur.x - prev.x;
    CGFloat dy = cur.y - prev.y;
    
    CGPoint newCenter = [self center];
    newCenter.x += dx;
    newCenter.y += dy;
    
    [self setCenter:newCenter];
    [self clampIntoSuperviewBounds];

    _prevCenterInSuperview = [self center];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self p_commitBack];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self p_commitBack];
}




#pragma mark - Helper

- (CGPoint)centerOnScreen
{
    // 以「像素」回傳中心點（搭配你用 nativeBounds 校正）
    UIWindow *win = nil;
    if (@available(iOS 13.0, *))
    {
        // 尋找目前使用中的前景 scene 的 key window
        for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes)
        {
            if (scene.activationState == UISceneActivationStateForegroundActive)
            {
                win = scene.windows.firstObject;
                break;
            }
        }
    }
    else
    {
        win = UIApplication.sharedApplication.keyWindow;
    }
    CGPoint centerInSelf = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    if (!win) {
        // 沒有 window 時，先回傳以 superview 為座標系的點，再做像素換算
        CGPoint inSuperview = [self convertPoint:centerInSelf toView:self.superview];
        CGFloat scale = UIScreen.mainScreen.nativeScale;
        return CGPointMake(lround(inSuperview.x * scale), lround(inSuperview.y * scale));
    }
    CGPoint inWindow = [self convertPoint:centerInSelf toView:win];
    CGFloat scale = UIScreen.mainScreen.nativeScale;
    return CGPointMake(lround(inWindow.x * scale), lround(inWindow.y * scale));
}

- (void)clampIntoSuperviewBounds
{
    if (![self superview]) return;

    CGRect boundary = [[self superview] bounds];
    if (@available(iOS 11.0, *))
    {
        // 盡量避免跑進安全區外
        UIEdgeInsets insets = [[self superview] safeAreaInsets];
        boundary = UIEdgeInsetsInsetRect(boundary, insets);
    }
    
    CGPoint c = [self center];
    
    CGFloat newCenterX = MAX(CGRectGetMinX(boundary), MIN(c.x, CGRectGetMaxX(boundary)));
    CGFloat newCenterY = MAX(CGRectGetMinY(boundary), MIN(c.y, CGRectGetMaxY(boundary)));
    
    [self setCenter:CGPointMake(newCenterX, newCenterY)];

    // 回寫模型
    [[self action] setPosX:CGRectGetMinX([self frame])];
    [[self action] setPosY:CGRectGetMinY([self frame])];
}

- (CGRect)p_clampRect:(CGRect)aRect inside:(CGRect)aBounds
{
    CGFloat maxX = CGRectGetMaxX(aBounds) - CGRectGetWidth(aRect);
    CGFloat maxY = CGRectGetMaxY(aBounds) - CGRectGetHeight(aRect);
    aRect.origin.x = MAX(CGRectGetMinX(aBounds), MIN(aRect.origin.x, maxX));
    aRect.origin.y = MAX(CGRectGetMinY(aBounds), MIN(aRect.origin.y, maxY));
    return aRect;
}

- (void)p_commitBack
{
    self.action.posX = CGRectGetMinX(self.frame);
    self.action.posY = CGRectGetMinY(self.frame);
    if (self.onPositionCommitted) self.onPositionCommitted(self);
}

@end
