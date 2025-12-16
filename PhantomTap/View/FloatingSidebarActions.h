//
//  FloatingSidebarActions.h
//  PhantomTap
//
//  Created by ethanlin on 2025/10/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FloatingSidebarActions <NSObject>

@optional
- (void)onTapAddPhantomTap;
- (void)onTapPickPhoto;
- (void)onTapSave;
- (void)onTapUpload;
- (void)onTapClear;
- (void)onWriteToKeyboard;
- (void)toggleSidebar;

@end

NS_ASSUME_NONNULL_END
