#import <UIKit/UIKit.h>

@interface JDFloatingWindow : UIWindow

+ (instancetype)shared;
- (void)show;
- (void)hide;
- (void)appendLog:(NSString *)msg;

@end
