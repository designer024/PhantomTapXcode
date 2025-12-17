// JsonFilePickerView.m

#import "JsonFilePickerView.h"
#import <objc/runtime.h>

@interface JsonFilePickerView () <UIGestureRecognizerDelegate>
{
    UIView *_dimmingView;
    UIView *_cardView;
    UILabel *_titleLabel;
    UIScrollView *_scrollView;
    UIStackView *_stackView;
    UIButton *_cancelButton;
    
    NSMutableArray<NSURL *> *_mutableFileURLs;
}

@property (nonatomic, copy) JsonFilePickerSelectHandler onSelect;
@property (nonatomic, copy) JsonFilePickerDeleteHandler onDelete;
@property (nonatomic, copy) JsonFilePickerCancelHandler onCancel;

@end

@implementation JsonFilePickerView

#pragma mark - Public

+ (instancetype)showInView:(UIView *)aParentView
                     title:(NSString *)aTitle
                      urls:(NSArray<NSURL *> *)aFileURLs
                  onSelect:(JsonFilePickerSelectHandler)aOnSelect
                  onDelete:(JsonFilePickerDeleteHandler)aOnDelete
                  onCancel:(JsonFilePickerCancelHandler)aOnCancel
{
    JsonFilePickerView *jsonFilePickerView = [[JsonFilePickerView alloc] initWithFrame:aParentView.bounds];
    [jsonFilePickerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [jsonFilePickerView setOnSelect:[aOnSelect copy]];
    [jsonFilePickerView setOnDelete:[aOnDelete copy]];
    [jsonFilePickerView setOnCancel:[aOnCancel copy]];    
    
    [jsonFilePickerView configureWithTitle:aTitle urls:aFileURLs];
    
    [aParentView addSubview:jsonFilePickerView];
    [NSLayoutConstraint activateConstraints:@[
        [[jsonFilePickerView topAnchor] constraintEqualToAnchor:[aParentView topAnchor]],
        [[jsonFilePickerView bottomAnchor] constraintEqualToAnchor:[aParentView bottomAnchor]],
        [[jsonFilePickerView leadingAnchor] constraintEqualToAnchor:[aParentView leadingAnchor]],
        [[jsonFilePickerView trailingAnchor] constraintEqualToAnchor:[aParentView trailingAnchor]],
    ]];
    
    [jsonFilePickerView setAlpha:0.0];
    [UIView animateWithDuration:0.2 animations:^{
        [jsonFilePickerView setAlpha:1.0];
    }];
    
    return jsonFilePickerView;
}

- (void)dismiss
{
    [UIView animateWithDuration:0.2 animations:^{
        [self setAlpha:0.0];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

#pragma mark - Init / UI

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self buildUI];
    }
    return self;
}

- (void)buildUI
{
    [self setBackgroundColor:[UIColor clearColor]];
    
    // 半透明背景
    _dimmingView = [[UIView alloc] initWithFrame:CGRectZero];
    [_dimmingView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_dimmingView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.45]];
    [self addSubview:_dimmingView];
    
    UITapGestureRecognizer *tapDismiss = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapOutside:)];
    [_dimmingView addGestureRecognizer:tapDismiss];
    
    // card
    _cardView = [[UIView alloc] initWithFrame:CGRectZero];
    [_cardView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_cardView setBackgroundColor:[UIColor whiteColor]];
    [[_cardView layer] setCornerRadius:18.0];
    [[_cardView layer] setMasksToBounds:YES];
    [self addSubview:_cardView];
    
    // title
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [_titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_titleLabel setFont:[UIFont boldSystemFontOfSize:17.0]];
    [_titleLabel setTextColor:[UIColor blackColor]];
    [_titleLabel setTextAlignment:NSTextAlignmentLeft];
    [_titleLabel setNumberOfLines:0];
    [_cardView addSubview:_titleLabel];
    
    // scroll + stack for rows
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    [_scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_scrollView setAlwaysBounceVertical:YES];
    [_cardView addSubview:_scrollView];
    
    _stackView = [[UIStackView alloc] initWithFrame:CGRectZero];
    [_stackView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_stackView setAxis:UILayoutConstraintAxisVertical];
    [_stackView setAlignment:UIStackViewAlignmentFill];
    [_stackView setDistribution:UIStackViewDistributionFill];
    [_stackView setSpacing:0.0];
    [_scrollView addSubview:_stackView];
    
    // Cancel button
    _cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_cancelButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_cancelButton setTitle:NSLocalizedString(@"cancel", nil) forState:UIControlStateNormal];
    [_cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_cancelButton setBackgroundColor:[UIColor colorWithRed:0.0/255.0 green:195.0/255.0 blue:208.0/255.0 alpha:1.0]];
    [[_cancelButton titleLabel] setFont:[UIFont fontWithName:@"NotoSansTC-Black" size:16.0] ?: [UIFont boldSystemFontOfSize:16.0]];
    [[_cancelButton layer] setCornerRadius:22.0];
    [[_cancelButton layer] setMasksToBounds:YES];
    [_cancelButton addTarget:self action:@selector(onTapCancel:) forControlEvents:UIControlEventTouchUpInside];
    [_cardView addSubview:_cancelButton];
    
    // Layout
    [NSLayoutConstraint activateConstraints:@[
        // dimming fullscreen
        [[_dimmingView topAnchor] constraintEqualToAnchor:[self topAnchor]],
        [[_dimmingView bottomAnchor] constraintEqualToAnchor:[self bottomAnchor]],
        [[_dimmingView leadingAnchor] constraintEqualToAnchor:[self leadingAnchor]],
        [[_dimmingView trailingAnchor] constraintEqualToAnchor:[self trailingAnchor]],
        
        // card center
        [[_cardView centerXAnchor] constraintEqualToAnchor:[self centerXAnchor]],
        [[_cardView centerYAnchor] constraintEqualToAnchor:[self centerYAnchor]],
        [[_cardView widthAnchor] constraintLessThanOrEqualToAnchor:[self widthAnchor] constant:-40.0],
        [[_cardView widthAnchor] constraintGreaterThanOrEqualToConstant:260.0],
        [[_cardView heightAnchor] constraintLessThanOrEqualToAnchor:[self heightAnchor] constant:-160.0],
        
        // title
        [[_titleLabel topAnchor] constraintEqualToAnchor:[_cardView topAnchor] constant:18.0],
        [[_titleLabel leadingAnchor] constraintEqualToAnchor:[_cardView leadingAnchor] constant:20.0],
        [[_titleLabel trailingAnchor] constraintEqualToAnchor:[_cardView trailingAnchor] constant:-20.0],
        
        // cancel
        [[_cancelButton leadingAnchor] constraintEqualToAnchor:[_cardView leadingAnchor] constant:24.0],
        [[_cancelButton trailingAnchor] constraintEqualToAnchor:[_cardView trailingAnchor] constant:-24.0],
        [[_cancelButton bottomAnchor] constraintEqualToAnchor:[_cardView bottomAnchor] constant:-18.0],
        [[_cancelButton heightAnchor] constraintEqualToConstant:44.0],
        
        // scroll between title & cancel
        [[_scrollView topAnchor] constraintEqualToAnchor:[_titleLabel bottomAnchor] constant:12.0],
        [[_scrollView leadingAnchor] constraintEqualToAnchor:[_cardView leadingAnchor] constant:16.0],
        [[_scrollView trailingAnchor] constraintEqualToAnchor:[_cardView trailingAnchor] constant:-16.0],
        [[_scrollView bottomAnchor] constraintEqualToAnchor:[_cancelButton topAnchor] constant:-16.0],
        
        // stack in scroll
        [[_stackView topAnchor] constraintEqualToAnchor:[_scrollView topAnchor]],
        [[_stackView bottomAnchor] constraintEqualToAnchor:[_scrollView bottomAnchor]],
        [[_stackView leadingAnchor] constraintEqualToAnchor:[_scrollView leadingAnchor]],
        [[_stackView trailingAnchor] constraintEqualToAnchor:[_scrollView trailingAnchor]],
        [[_stackView widthAnchor] constraintEqualToAnchor:[_scrollView widthAnchor]],
    ]];
    
    NSLayoutConstraint *scrollH = [[_scrollView heightAnchor] constraintEqualToAnchor:[_stackView heightAnchor]];
    [scrollH setPriority:UILayoutPriorityDefaultHigh];
    [scrollH setActive:YES];
}

- (void)configureWithTitle:(NSString *)title urls:(NSArray<NSURL *> *)fileURLs
{
    [_titleLabel setText:title];
    _mutableFileURLs = [fileURLs mutableCopy] ?: [NSMutableArray array];
    
    // 先清空 stack
    for (UIView *v in _stackView.arrangedSubviews) {
        [_stackView removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    
    if (_mutableFileURLs.count == 0) {
        UILabel *empty = [[UILabel alloc] initWithFrame:CGRectZero];
        [empty setTranslatesAutoresizingMaskIntoConstraints:NO];
        [empty setText:NSLocalizedString(@"no_items_can_be_loaded", nil)];
        [empty setFont:[UIFont systemFontOfSize:14.0]];
        [empty setTextColor:[UIColor darkGrayColor]];
        [empty setTextAlignment:NSTextAlignmentCenter];
        [empty setNumberOfLines:0];
        [_stackView addArrangedSubview:empty];
        return;
    }
    
    [_mutableFileURLs enumerateObjectsUsingBlock:^(NSURL * _Nonnull url, NSUInteger idx, BOOL * _Nonnull stop) {
        UIView *row = [self buildRowForURL:url index:idx];
        [_stackView addArrangedSubview:row];
    }];
}

#pragma mark - Row

- (UIView *)buildRowForURL:(NSURL *)url index:(NSUInteger)index
{
    UIView *row = [[UIView alloc] initWithFrame:CGRectZero];
    [row setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    [label setTranslatesAutoresizingMaskIntoConstraints:NO];
    [label setFont:[UIFont systemFontOfSize:14.0]];
    [label setTextColor:[UIColor blackColor]];
    NSString *pathString = [url lastPathComponent] ?: [url absoluteString];
    [label setText:pathString];
    [label setNumberOfLines:1];
    
    UIButton *deleteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [deleteBtn setTranslatesAutoresizingMaskIntoConstraints:NO];
    [deleteBtn setTitle:@"delete" forState:UIControlStateNormal];
    [deleteBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [[deleteBtn titleLabel] setFont:[UIFont boldSystemFontOfSize:13.0]];
    [deleteBtn setBackgroundColor:[UIColor colorWithRed:0.86 green:0.29 blue:0.29 alpha:1.0]];
    [[deleteBtn layer] setCornerRadius:14.0];
    [[deleteBtn layer] setMasksToBounds:YES];
    [deleteBtn setTag:(NSInteger)index];
    [deleteBtn addTarget:self action:@selector(onTapDeleteButton:) forControlEvents:UIControlEventTouchUpInside];
    
    UIView *separator = [[UIView alloc] initWithFrame:CGRectZero];
    [separator setTranslatesAutoresizingMaskIntoConstraints:NO];
    separator.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    
    [row addSubview:label];
    [row addSubview:deleteBtn];
    [row addSubview:separator];
    
    [NSLayoutConstraint activateConstraints:@[
        [[label leadingAnchor] constraintEqualToAnchor:[row leadingAnchor]],
        [[label centerYAnchor] constraintEqualToAnchor:[row centerYAnchor]],
        [[label trailingAnchor] constraintLessThanOrEqualToAnchor:[deleteBtn leadingAnchor] constant:-8.0],
        
        [[deleteBtn trailingAnchor] constraintEqualToAnchor:[row trailingAnchor]],
        [[deleteBtn centerYAnchor] constraintEqualToAnchor:[row centerYAnchor]],
        [[deleteBtn heightAnchor] constraintEqualToConstant:28.0],
        [[deleteBtn widthAnchor] constraintGreaterThanOrEqualToConstant:72.0],
        
        [[separator leadingAnchor] constraintEqualToAnchor:[row leadingAnchor]],
        [[separator trailingAnchor] constraintEqualToAnchor:[row trailingAnchor]],
        [[separator bottomAnchor] constraintEqualToAnchor:[row bottomAnchor]],
        [[separator heightAnchor] constraintEqualToConstant:0.7],
        
        [[row heightAnchor] constraintGreaterThanOrEqualToConstant:40.0],
    ]];
    
    UITapGestureRecognizer *tapRow = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapRow:)];
    [tapRow setDelegate:self];
    [row addGestureRecognizer:tapRow];
    [row setUserInteractionEnabled:YES];
    
    objc_setAssociatedObject(row, @"json_url", url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return row;
}

#pragma mark - Actions

- (void)onTapOutside:(UITapGestureRecognizer *)gr
{
    if (gr.state == UIGestureRecognizerStateEnded)
    {
        if (self.onCancel) self.onCancel();
        [self dismiss];
    }
}

- (void)onTapCancel:(UIButton *)sender
{
    if (self.onCancel) self.onCancel();
    [self dismiss];
}

- (void)onTapRow:(UITapGestureRecognizer *)gr
{
    if (gr.state != UIGestureRecognizerStateEnded) return;
    UIView *row = gr.view;
    NSURL *url = objc_getAssociatedObject(row, @"json_url");
    NSLog(@"[JsonFilePicker] row tapped: %@", url);
    
    if (self.onSelect && url)
    {
        self.onSelect(url);
    }
    [self dismiss];
}

- (void)onTapDeleteButton:(UIButton *)sender
{
    NSInteger idx = sender.tag;
    if (idx < 0 || idx >= (NSInteger)_mutableFileURLs.count) return;
    NSURL *url = _mutableFileURLs[(NSUInteger)idx];
    
    NSLog(@"[JsonFilePicker] delete tapped: %@", url);
    
    if (self.onDelete)
    {
        self.onDelete(url);
    }
    
    [_mutableFileURLs removeObjectAtIndex:(NSUInteger)idx];
    
    [self configureWithTitle:_titleLabel.text ?: @"" urls:_mutableFileURLs];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[UIButton class]])
    {
        return NO;
    }
    return YES;
}

@end
