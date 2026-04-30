#import "JDAutoEngine.h"
#import <UIKit/UIKit.h>

// Bundle ID 常量
static NSString *const kFocusBundleID = @"com.focus-app.focus";
static NSString *const kJDBundleID    = @"com.jingdong.app.mall";

// 京东注册页 URL（Focus 浏览器打开）
static NSString *const kJDRegURL = @"https://www.jdl.com/hk/e/regPage?source=gangao_pc_b&language=zh_HK";

@interface JDAutoEngine ()
@property (nonatomic, strong) dispatch_queue_t workQueue;
@property (nonatomic, assign) BOOL             shouldStop;
@property (nonatomic, assign) BOOL             isPaused;
@property (nonatomic, copy)   NSString        *step28Code;  // 步骤28取到的验证码（去重用）
@property (nonatomic, copy)   NSString        *savedCode;   // 步骤29保存的验证码
@end

@implementation JDAutoEngine

+ (instancetype)shared {
    static JDAutoEngine *s;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ s = [JDAutoEngine new]; });
    return s;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _workQueue = dispatch_queue_create("com.jdauto.engine", DISPATCH_QUEUE_SERIAL);
        _state     = JDAutoStateIdle;
    }
    return self;
}

// ─── 日志输出 ─────────────────────────────────────────────
- (void)log:(NSString *)fmt, ... {
    va_list args;
    va_start(args, fmt);
    NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);

    NSDateFormatter *df = [NSDateFormatter new];
    df.dateFormat = @"HH:mm:ss";
    NSString *ts = [df stringFromDate:[NSDate date]];
    NSString *full = [NSString stringWithFormat:@"[%@] %@", ts, msg];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.logCallback) self.logCallback(full);
    });
    NSLog(@"[JDAutoEngine] %@", full);
}

// ─── 状态变更 ─────────────────────────────────────────────
- (void)setState:(JDAutoState)state {
    _state = state;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.stateCallback) self.stateCallback(state);
    });
}

// ─── 暂停检查点（在每个步骤间调用）─────────────────────────
- (void)checkPause {
    while (self.isPaused && !self.shouldStop) {
        [NSThread sleepForTimeInterval:0.3];
    }
}

// ─── 公开控制接口 ─────────────────────────────────────────
- (void)start {
    if (self.state == JDAutoStateRunning) return;
    if (!self.phone.length || !self.apiURL.length) {
        [self log:@"❌ 请先填写手机号和接码API"];
        return;
    }
    self.shouldStop = NO;
    self.isPaused   = NO;
    self.step28Code = nil;
    self.savedCode  = nil;
    self.state = JDAutoStateRunning;
    [self log:@"▶ 开始运行  手机号: %@", self.phone];

    dispatch_async(self.workQueue, ^{
        [self runAllSteps];
    });
}

- (void)pause {
    if (self.state != JDAutoStateRunning) return;
    self.isPaused = YES;
    self.state = JDAutoStatePaused;
    [self log:@"⏸ 已暂停"];
}

- (void)resume {
    if (self.state != JDAutoStatePaused) return;
    self.isPaused = NO;
    self.state = JDAutoStateRunning;
    [self log:@"▶ 继续运行"];
}

- (void)stop {
    self.shouldStop = YES;
    self.isPaused   = NO;
    self.state = JDAutoStateStopped;
    [self log:@"⏹ 已停止"];
}

// ═══════════════════════════════════════════════════════════
// 主流程
// ═══════════════════════════════════════════════════════════
- (void)runAllSteps {
    [self log:@"=== 开始执行步骤 27~31 ==="];

    // Step 27：打开 Focus 浏览器注册页 → 点击「获取验证码」→ 等待安全验证
    if (self.shouldStop) return;
    [self checkPause];
    [self step27_openFocusAndGetCode];

    // Step 28：轮询接码API → 填入 Focus 验证码框
    if (self.shouldStop) return;
    [self checkPause];
    [self step28_fillCodeInFocus];

    // Step 29：回 Home → 打开京东 → 轮询新验证码（去重）→ 保存
    if (self.shouldStop) return;
    [self checkPause];
    [self step29_jdGetAndSaveCode];

    // Step 30：回 Home → 打开 Focus → 点「同意协议并登录」→ 处理弹窗
    if (self.shouldStop) return;
    [self checkPause];
    [self step30_focusTriggerLogin];

    // Step 31：打开京东 → 填入步骤29保存的验证码
    if (self.shouldStop) return;
    [self checkPause];
    [self step31_jdFillSavedCode];

    if (!self.shouldStop) {
        [self log:@"🎉 步骤27~31 全部完成！"];
        self.state = JDAutoStateIdle;
    }
}

// ═══════════════════════════════════════════════════════════
// Step 27：打开 Focus 浏览器 → 打开京东注册页 → 点「获取验证码」
//          → 检测安全验证弹窗（等待消失）
// ═══════════════════════════════════════════════════════════
- (void)step27_openFocusAndGetCode {
    [self log:@">> Step 27: 打开 Focus 浏览器注册页"];

    // 1. 打开 Focus 浏览器并导航到京东注册页
    [self openURL:[NSString stringWithFormat:@"focusbrowser://%@", kJDRegURL]
      fallbackApp:kFocusBundleID];
    [NSThread sleepForTimeInterval:3.5];

    // 2. 找到手机号输入框并填入手机号
    [self log:@"  填入手机号: %@", self.phone];
    UITextField *phoneField = [self findTextFieldWithPlaceholderContaining:@"手機號" inBundleID:kFocusBundleID];
    if (!phoneField) {
        phoneField = [self findTextFieldWithPlaceholderContaining:@"手机号" inBundleID:kFocusBundleID];
    }
    if (phoneField) {
        [self fillTextField:phoneField withText:self.phone];
        [NSThread sleepForTimeInterval:0.8];
        [self log:@"  ✅ 手机号已填入"];
    } else {
        [self log:@"  ⚠️ 未找到手机号输入框，请手动填入"];
        [NSThread sleepForTimeInterval:2.0];
    }

    // 3. 点击「获取验证码」按钮
    [self log:@"  点击「获取验证码」"];
    BOOL tapped = [self tapButtonWithTitleContaining:@"獲取驗證碼" inBundleID:kFocusBundleID];
    if (!tapped) {
        tapped = [self tapButtonWithTitleContaining:@"获取验证码" inBundleID:kFocusBundleID];
    }
    if (!tapped) {
        [self log:@"  ⚠️ 未找到「获取验证码」按钮，尝试通过 Accessibility 查找"];
        [self tapAccessibilityElementWithLabel:@"獲取驗證碼"];
    }
    [NSThread sleepForTimeInterval:2.0];

    // 4. 检测安全验证弹窗（等待最多 99 秒）
    [self log:@"  检测安全验证弹窗..."];
    NSTimeInterval deadline = [NSDate timeIntervalSinceReferenceDate] + 99;
    BOOL hadPopup = NO;
    while ([NSDate timeIntervalSinceReferenceDate] < deadline && !self.shouldStop) {
        BOOL hasPopup = [self detectSecurityVerifyPopupInBundleID:kFocusBundleID];
        if (hasPopup) {
            if (!hadPopup) {
                [self log:@"  ⚠️ 检测到安全验证弹窗，等待人工处理..."];
                hadPopup = YES;
            }
            [NSThread sleepForTimeInterval:1.5];
        } else {
            if (hadPopup) {
                [self log:@"  ✅ 安全验证已通过，继续执行"];
            } else {
                [self log:@"  ✅ 无安全验证弹窗"];
            }
            break;
        }
    }
    [self log:@"  ✅ Step 27 完成"];
}

// ═══════════════════════════════════════════════════════════
// Step 28：轮询接码API → 填入 Focus 浏览器验证码输入框
// ═══════════════════════════════════════════════════════════
- (void)step28_fillCodeInFocus {
    [self log:@">> Step 28: 等待验证码（最多99秒）"];
    NSString *code = [self pollAPIForCode:nil maxSeconds:99 stepLabel:@"28"];
    if (!code) {
        [self log:@"  ❌ 99秒内未收到验证码，跳过"];
        return;
    }
    self.step28Code = code;

    // 填入 Focus 浏览器验证码输入框
    [self log:@"  填入验证码 %@ 到 Focus 浏览器", code];
    UITextField *codeField = [self findTextFieldWithPlaceholderContaining:@"驗證碼" inBundleID:kFocusBundleID];
    if (!codeField) {
        codeField = [self findTextFieldWithPlaceholderContaining:@"验证码" inBundleID:kFocusBundleID];
    }
    if (codeField) {
        [self fillTextField:codeField withText:code];
        [NSThread sleepForTimeInterval:0.5];
        [self log:@"  ✅ 验证码 %@ 已填入 Focus", code];
    } else {
        [self log:@"  ⚠️ 未找到验证码输入框"];
    }

    // 回到 Home
    [self goHome];
    [NSThread sleepForTimeInterval:1.0];
    [self log:@"  ✅ Step 28 完成，已返回 Home"];
}

// ═══════════════════════════════════════════════════════════
// Step 29：回 Home → 打开京东 App → 处理同意弹窗
//          → 等待验证码输入页 → 检测安全验证 → 轮询新验证码（去重）→ 保存
// ═══════════════════════════════════════════════════════════
- (void)step29_jdGetAndSaveCode {
    [self log:@">> Step 29: 打开京东 App，获取新验证码"];

    // 1. 打开京东 App
    [self openAppByBundleID:kJDBundleID];
    [NSThread sleepForTimeInterval:3.0];

    // 2. 检测「同意」隐私弹窗（有红色按钮）
    BOOL hasAgree = [self detectAndTapButtonWithTitleContaining:@"同意" inBundleID:kJDBundleID];
    if (hasAgree) {
        [self log:@"  ✅ 已点击「同意」隐私弹窗"];
        [NSThread sleepForTimeInterval:1.5];
    }

    // 3. 等待验证码输入页加载（最多15秒）
    [self log:@"  等待验证码输入页加载..."];
    [NSThread sleepForTimeInterval:2.0];

    // 4. 检测安全验证弹窗
    NSTimeInterval deadline = [NSDate timeIntervalSinceReferenceDate] + 99;
    BOOL hadPopup = NO;
    while ([NSDate timeIntervalSinceReferenceDate] < deadline && !self.shouldStop) {
        BOOL hasPopup = [self detectSecurityVerifyPopupInBundleID:kJDBundleID];
        if (hasPopup) {
            if (!hadPopup) {
                [self log:@"  ⚠️ 检测到安全验证弹窗，等待人工处理..."];
                hadPopup = YES;
            }
            [NSThread sleepForTimeInterval:1.5];
        } else {
            if (hadPopup) [self log:@"  ✅ 安全验证已通过"];
            break;
        }
    }

    // 5. 轮询接码API（去重：跳过与step28相同的验证码）
    [self log:@"  轮询接码API（去重，最多99秒）..."];
    NSString *code = [self pollAPIForCode:self.step28Code maxSeconds:99 stepLabel:@"29"];
    if (!code) {
        [self log:@"  ❌ 99秒内未收到新验证码，跳过"];
        return;
    }
    self.savedCode = code;
    [self log:@"  ✅ Step 29 完成：验证码 %@ 已保存", code];
}

// ═══════════════════════════════════════════════════════════
// Step 30：回 Home → 打开 Focus 浏览器 → 点「同意协议并登录」
//          → 处理「该手机号未注册」弹窗 → 等待3秒 → 回 Home
// ═══════════════════════════════════════════════════════════
- (void)step30_focusTriggerLogin {
    [self log:@">> Step 30: 打开 Focus 浏览器，触发登录"];

    // 1. 回 Home
    [self goHome];
    [NSThread sleepForTimeInterval:1.0];

    // 2. 打开 Focus 浏览器
    [self openAppByBundleID:kFocusBundleID];
    [NSThread sleepForTimeInterval:2.5];

    // 3. 点击「同意協議并登錄」
    BOOL tapped = [self tapButtonWithTitleContaining:@"同意協議并登錄" inBundleID:kFocusBundleID];
    if (!tapped) {
        tapped = [self tapButtonWithTitleContaining:@"同意协议并登录" inBundleID:kFocusBundleID];
    }
    if (!tapped) {
        [self tapAccessibilityElementWithLabel:@"同意協議并登錄"];
    }
    [self log:@"  已点击「同意协议并登录」"];
    [NSThread sleepForTimeInterval:1.5];

    // 4. 检测「该手机号未注册」弹窗（有红色「確定」按钮）
    BOOL hasConfirm = [self detectAndTapButtonWithTitleContaining:@"確定" inBundleID:kFocusBundleID];
    if (!hasConfirm) {
        hasConfirm = [self detectAndTapButtonWithTitleContaining:@"确定" inBundleID:kFocusBundleID];
    }
    if (hasConfirm) {
        [self log:@"  ✅ 已处理「未注册」弹窗，点击「確定」"];
        [NSThread sleepForTimeInterval:1.0];
    }

    // 5. 等待浏览器加载
    [self log:@"  等待浏览器加载3秒..."];
    [NSThread sleepForTimeInterval:3.0];

    // 6. 回 Home
    [self goHome];
    [NSThread sleepForTimeInterval:1.0];
    [self log:@"  ✅ Step 30 完成"];
}

// ═══════════════════════════════════════════════════════════
// Step 31：打开京东 App → 填入步骤29保存的验证码
// ═══════════════════════════════════════════════════════════
- (void)step31_jdFillSavedCode {
    [self log:@">> Step 31: 打开京东，填入验证码"];
    NSString *code = self.savedCode;
    if (!code) {
        [self log:@"  ❌ 无已保存的验证码（步骤29未成功），跳过"];
        return;
    }
    [self log:@"  使用验证码: %@", code];

    // 打开京东 App
    [self openAppByBundleID:kJDBundleID];
    [NSThread sleepForTimeInterval:2.5];

    // 找验证码输入框并填入
    UITextField *codeField = [self findTextFieldWithPlaceholderContaining:@"验证码" inBundleID:kJDBundleID];
    if (!codeField) {
        codeField = [self findTextFieldWithPlaceholderContaining:@"驗證碼" inBundleID:kJDBundleID];
    }
    if (codeField) {
        [self fillTextField:codeField withText:code];
        [self log:@"  ✅ Step 31 完成：验证码 %@ 已填入京东", code];
    } else {
        [self log:@"  ⚠️ 未找到验证码输入框，请手动填入: %@", code];
    }
}

// ═══════════════════════════════════════════════════════════
// 工具方法
// ═══════════════════════════════════════════════════════════

// 轮询接码API，skipCode 不为 nil 时跳过相同验证码（去重）
- (NSString *)pollAPIForCode:(NSString *)skipCode maxSeconds:(NSInteger)maxSec stepLabel:(NSString *)label {
    for (NSInteger i = 0; i < maxSec; i++) {
        if (self.shouldStop) return nil;
        [self checkPause];

        NSString *result = [self fetchAPIOnce];
        if (result) {
            [self log:@"  [Step%@][%02ld/%ld] API返回: %@", label, (long)(i+1), (long)maxSec, [result substringToIndex:MIN(80, result.length)]];
            NSString *code = [self extractCode:result];
            if (code) {
                if (skipCode && [code isEqualToString:skipCode]) {
                    [self log:@"  [Step%@][%02ld/%ld] 验证码未更新(%@)，继续等待...", label, (long)(i+1), (long)maxSec, code];
                } else {
                    [self log:@"  ✅ 出码: %@", code];
                    return code;
                }
            }
        } else {
            [self log:@"  [Step%@][%02ld/%ld] API请求失败", label, (long)(i+1), (long)maxSec];
        }
        [NSThread sleepForTimeInterval:1.0];
    }
    return nil;
}

// 请求接码API一次，返回原始字符串（使用 NSURLSession 同步方式）
- (NSString *)fetchAPIOnce {
    if (!self.apiURL.length) return nil;
    NSURL *url = [NSURL URLWithString:self.apiURL];
    if (!url) return nil;
    NSURLRequest *req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5.0];
    __block NSData *resultData = nil;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *resp, NSError *err) {
        if (!err && data) resultData = data;
        dispatch_semaphore_signal(sem);
    }];
    [task resume];
    dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 6 * NSEC_PER_SEC));
    if (!resultData) return nil;
    return [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
}

// 从字符串中提取4~8位纯数字验证码
- (NSString *)extractCode:(NSString *)text {
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"(?<!\\d)(\\d{4,8})(?!\\d)" options:0 error:nil];
    NSTextCheckingResult *match = [re firstMatchInString:text options:0 range:NSMakeRange(0, text.length)];
    if (match) {
        return [text substringWithRange:[match rangeAtIndex:1]];
    }
    return nil;
}

// 打开 URL（用于 Focus 浏览器 URL Scheme）
- (void)openURL:(NSString *)urlStr fallbackApp:(NSString *)bundleID {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSURL *url = [NSURL URLWithString:[urlStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
        if (url && [[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        } else {
            [self openAppByBundleID:bundleID];
        }
    });
    [NSThread sleepForTimeInterval:0.5];
}

// 通过 Bundle ID 打开 App
- (void)openAppByBundleID:(NSString *)bundleID {
    dispatch_async(dispatch_get_main_queue(), ^{
        // iOS 越狱环境下使用 LSApplicationWorkspace 打开 App
        Class workspace = NSClassFromString(@"LSApplicationWorkspace");
        if (workspace) {
            id ws = [workspace performSelector:@selector(defaultWorkspace)];
            [ws performSelector:@selector(openApplicationWithBundleID:) withObject:bundleID];
        }
    });
    [NSThread sleepForTimeInterval:0.3];
}

// 回到 Home 界面
- (void)goHome {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 模拟 Home 键
        [[UIApplication sharedApplication] performSelector:@selector(suspend)];
    });
    [NSThread sleepForTimeInterval:0.8];
}

// 在指定 App 中查找包含特定 placeholder 的 UITextField
- (UITextField *)findTextFieldWithPlaceholderContaining:(NSString *)text inBundleID:(NSString *)bundleID {
    __block UITextField *found = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            found = [self searchTextField:window placeholder:text];
            if (found) break;
        }
    });
    return found;
}

- (UITextField *)searchTextField:(UIView *)view placeholder:(NSString *)text {
    if ([view isKindOfClass:[UITextField class]]) {
        UITextField *tf = (UITextField *)view;
        if ([tf.placeholder containsString:text] || [tf.accessibilityLabel containsString:text]) {
            return tf;
        }
    }
    for (UIView *sub in view.subviews) {
        UITextField *r = [self searchTextField:sub placeholder:text];
        if (r) return r;
    }
    return nil;
}

// 填充 UITextField
- (void)fillTextField:(UITextField *)tf withText:(NSString *)text {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [tf becomeFirstResponder];
        tf.text = text;
        // 触发 UITextFieldTextDidChangeNotification 让 App 感知到输入
        [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:tf];
        // 触发 delegate
        if ([tf.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
            [tf.delegate textField:tf shouldChangeCharactersInRange:NSMakeRange(0, 0) replacementString:text];
        }
        [tf sendActionsForControlEvents:UIControlEventEditingChanged];
        [tf resignFirstResponder];
    });
}

// 在当前 App 中查找并点击包含特定标题的按钮
- (BOOL)tapButtonWithTitleContaining:(NSString *)title inBundleID:(NSString *)bundleID {
    __block BOOL tapped = NO;
    dispatch_sync(dispatch_get_main_queue(), ^{
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            UIButton *btn = [self searchButton:window title:title];
            if (btn) {
                [btn sendActionsForControlEvents:UIControlEventTouchUpInside];
                tapped = YES;
                break;
            }
        }
    });
    return tapped;
}

- (UIButton *)searchButton:(UIView *)view title:(NSString *)title {
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *btn = (UIButton *)view;
        NSString *t = [btn titleForState:UIControlStateNormal] ?: @"";
        if ([t containsString:title] || [btn.accessibilityLabel containsString:title]) {
            return btn;
        }
    }
    for (UIView *sub in view.subviews) {
        UIButton *r = [self searchButton:sub title:title];
        if (r) return r;
    }
    return nil;
}

// 检测并点击包含特定标题的按钮（用于弹窗）
- (BOOL)detectAndTapButtonWithTitleContaining:(NSString *)title inBundleID:(NSString *)bundleID {
    return [self tapButtonWithTitleContaining:title inBundleID:bundleID];
}

// 通过 Accessibility 点击元素
- (void)tapAccessibilityElementWithLabel:(NSString *)label {
    dispatch_sync(dispatch_get_main_queue(), ^{
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            UIView *v = [self searchAccessibility:window label:label];
            if (v) {
                // 模拟点击中心点
                CGPoint center = CGPointMake(CGRectGetMidX(v.frame), CGRectGetMidY(v.frame));
                UIView *parent = v.superview;
                while (parent) {
                    center = [parent convertPoint:center toView:nil];
                    break;
                }
                if ([v isKindOfClass:[UIControl class]]) {
                    [(UIControl *)v sendActionsForControlEvents:UIControlEventTouchUpInside];
                }
                break;
            }
        }
    });
}

- (UIView *)searchAccessibility:(UIView *)view label:(NSString *)label {
    if ([view.accessibilityLabel containsString:label]) return view;
    for (UIView *sub in view.subviews) {
        UIView *r = [self searchAccessibility:sub label:label];
        if (r) return r;
    }
    return nil;
}

// 检测安全验证弹窗（通过查找包含「安全驗證」或「安全验证」文字的 UILabel）
- (BOOL)detectSecurityVerifyPopupInBundleID:(NSString *)bundleID {
    __block BOOL found = NO;
    dispatch_sync(dispatch_get_main_queue(), ^{
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if ([self searchLabel:window text:@"安全驗證"] ||
                [self searchLabel:window text:@"安全验证"] ||
                [self searchLabel:window text:@"滑動驗證"] ||
                [self searchLabel:window text:@"滑动验证"]) {
                found = YES;
                break;
            }
        }
    });
    return found;
}

- (BOOL)searchLabel:(UIView *)view text:(NSString *)text {
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *lbl = (UILabel *)view;
        if ([lbl.text containsString:text]) return YES;
    }
    for (UIView *sub in view.subviews) {
        if ([self searchLabel:sub text:text]) return YES;
    }
    return NO;
}

@end
