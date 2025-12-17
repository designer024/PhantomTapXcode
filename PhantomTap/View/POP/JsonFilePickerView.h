// JsonFilePickerView.h

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^JsonFilePickerSelectHandler)(NSURL *fileURL);
typedef void(^JsonFilePickerDeleteHandler)(NSURL *fileURL);
typedef void(^JsonFilePickerCancelHandler)(void);

@interface JsonFilePickerView : UIView

+ (instancetype)showInView:(UIView *)aParentView
                     title:(NSString *)aTitle
                      urls:(NSArray<NSURL *> *)aFileURLs
                  onSelect:(JsonFilePickerSelectHandler)aOnSelect
                  onDelete:(JsonFilePickerDeleteHandler)aOnDelete
                  onCancel:(JsonFilePickerCancelHandler)aOnCancel;

/// 關閉
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
