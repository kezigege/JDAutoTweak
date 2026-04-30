#import "JDAppDelegate.h"
#import "JDFloatingWindow.h"
#import "JDAutoEngine.h"

@implementation JDAppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // 主窗口（透明背景，仅作为 App 容器）
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor clearColor];

    // 根 VC（空白背景，显示提示文字）
    UIViewController *rootVC = [UIViewController new];
    rootVC.view.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:1.0];

    UILabel *hint = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, rootVC.view.bounds.size.width - 40, rootVC.view.bounds.size.height)];
    hint.text = @"JD 自动化插件已启动\n\n悬浮窗已显示在屏幕上\n可拖动到任意位置\n\n切换到其他 App 后\n悬浮窗仍保持显示";
    hint.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    hint.font = [UIFont systemFontOfSize:15];
    hint.numberOfLines = 0;
    hint.textAlignment = NSTextAlignmentCenter;
    [rootVC.view addSubview:hint];

    self.window.rootViewController = rootVC;
    [self.window makeKeyAndVisible];

    // 显示悬浮窗
    [[JDFloatingWindow shared] show];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // App 进入后台时悬浮窗继续显示
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[JDFloatingWindow shared] show];
}

@end
