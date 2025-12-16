// JsonFilePickerView.h

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^JsonFilePickerSelectHandler)(NSURL *fileURL);
typedef void(^JsonFilePickerDeleteHandler)(NSURL *fileURL);
typedef void(^JsonFilePickerCancelHandler)(void);

@interface JsonFilePickerView : UIView

/// 建立並顯示在 parentView 之上
+ (instancetype)showInView:(UIView *)parentView
                     title:(NSString *)title
                      urls:(NSArray<NSURL *> *)fileURLs
                  onSelect:(nullable JsonFilePickerSelectHandler)onSelect
                  onDelete:(nullable JsonFilePickerDeleteHandler)onDelete
                  onCancel:(nullable JsonFilePickerCancelHandler)onCancel;

/// 關閉
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
