#import "JDFloatingWindow.h"
#import "JDAutoEngine.h"

// ─── 颜色宏 ───────────────────────────────────────────────
#define RGB(r,g,b)   [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
#define RGBA(r,g,b,a)[UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]

static const CGFloat kW = 320.0f;   // 悬浮窗宽度
static const CGFloat kH = 420.0f;   // 悬浮窗高度
static const CGFloat kPad = 10.0f;

@interface JDFloatingWindowVC : UIViewController
@property (nonatomic, strong) UITextField  *phoneField;
@property (nonatomic, strong) UITextField  *apiField;
@property (nonatomic, strong) UITextView   *logView;
@property (nonatomic, strong) UIButton     *startBtn;
@property (nonatomic, strong) UIButton     *pauseBtn;
@property (nonatomic, strong) UIButton     *stopBtn;
@property (nonatomic, strong) UILabel      *statusLabel;
@end

@implementation JDFloatingWindowVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self buildUI];
    [self bindEngine];
}

- (void)buildUI {
    self.view.backgroundColor = RGBA(20, 20, 30, 0.96);
    self.view.layer.cornerRadius = 14;
    self.view.layer.masksToBounds = YES;

    CGFloat y = kPad;
    CGFloat w = kW - kPad * 2;

    // ── 标题栏 ─────────────────────────────────────────────
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(kPad, y, w, 28)];
    title.text = @"JD 自动化  步骤27~31";
    title.textColor = RGB(255, 200, 50);
    title.font = [UIFont boldSystemFontOfSize:15];
    title.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:title];
    y += 32;

    // ── 状态标签 ───────────────────────────────────────────
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(kPad, y, w, 20)];
    self.statusLabel.text = @"● 空闲";
    self.statusLabel.textColor = RGB(100, 200, 100);
    self.statusLabel.font = [UIFont systemFontOfSize:12];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.statusLabel];
    y += 24;

    // ── 手机号输入框 ───────────────────────────────────────
    UILabel *phoneLbl = [self makeLabelText:@"手机号" y:y w:w];
    [self.view addSubview:phoneLbl];
    y += 18;

    self.phoneField = [self makeTextField:@"输入手机号码" y:y w:w];
    self.phoneField.keyboardType = UIKeyboardTypePhonePad;
    [self.view addSubview:self.phoneField];
    y += 36;

    // ── 接码API输入框 ──────────────────────────────────────
    UILabel *apiLbl = [self makeLabelText:@"接码API" y:y w:w];
    [self.view addSubview:apiLbl];
    y += 18;

    self.apiField = [self makeTextField:@"http://..." y:y w:w];
    self.apiField.keyboardType = UIKeyboardTypeURL;
    self.apiField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.apiField.autocorrectionType = UITextAutocorrectionTypeNo;
    [self.view addSubview:self.apiField];
    y += 36;

    // ── 按钮行 ─────────────────────────────────────────────
    CGFloat btnW = (w - kPad * 2) / 3.0;
    self.startBtn = [self makeButton:@"▶ 开始" color:RGB(50, 180, 80)
                               frame:CGRectMake(kPad, y, btnW, 36)
                              action:@selector(onStart)];
    self.pauseBtn = [self makeButton:@"⏸ 暂停" color:RGB(220, 160, 30)
                               frame:CGRectMake(kPad + btnW + kPad, y, btnW, 36)
                              action:@selector(onPause)];
    self.stopBtn  = [self makeButton:@"⏹ 停止" color:RGB(200, 60, 60)
                               frame:CGRectMake(kPad + (btnW + kPad) * 2, y, btnW, 36)
                              action:@selector(onStop)];
    [self.view addSubview:self.startBtn];
    [self.view addSubview:self.pauseBtn];
    [self.view addSubview:self.stopBtn];
    y += 44;

    // ── 日志区域 ───────────────────────────────────────────
    UILabel *logLbl = [self makeLabelText:@"运行日志" y:y w:w];
    [self.view addSubview:logLbl];
    y += 18;

    CGFloat logH = kH - y - kPad;
    self.logView = [[UITextView alloc] initWithFrame:CGRectMake(kPad, y, w, logH)];
    self.logView.backgroundColor = RGBA(0, 0, 0, 0.5);
    self.logView.textColor = RGB(180, 255, 180);
    self.logView.font = [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightRegular];
    self.logView.editable = NO;
    self.logView.layer.cornerRadius = 6;
    self.logView.text = @"等待开始...\n";
    [self.view addSubview:self.logView];

    // 加载已保存的配置
    [self loadSavedConfig];
    [self updateButtonStates:JDAutoStateIdle];
}

// ─── 工厂方法 ─────────────────────────────────────────────
- (UILabel *)makeLabelText:(NSString *)text y:(CGFloat)y w:(CGFloat)w {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(kPad, y, w, 16)];
    lbl.text = text;
    lbl.textColor = RGB(160, 160, 180);
    lbl.font = [UIFont systemFontOfSize:11];
    return lbl;
}

- (UITextField *)makeTextField:(NSString *)placeholder y:(CGFloat)y w:(CGFloat)w {
    UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(kPad, y, w, 32)];
    tf.placeholder = placeholder;
    tf.backgroundColor = RGBA(255, 255, 255, 0.1);
    tf.textColor = [UIColor whiteColor];
    tf.font = [UIFont systemFontOfSize:13];
    tf.layer.cornerRadius = 6;
    tf.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 32)];
    tf.leftViewMode = UITextFieldViewModeAlways;
    // placeholder 颜色
    NSAttributedString *ph = [[NSAttributedString alloc] initWithString:placeholder
        attributes:@{NSForegroundColorAttributeName: RGBA(150, 150, 160, 0.8)}];
    tf.attributedPlaceholder = ph;
    [tf addTarget:self action:@selector(onTextChanged) forControlEvents:UIControlEventEditingChanged];
    return tf;
}

- (UIButton *)makeButton:(NSString *)title color:(UIColor *)color frame:(CGRect)frame action:(SEL)action {
    UIButton *btn = [[UIButton alloc] initWithFrame:frame];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    btn.backgroundColor = color;
    btn.layer.cornerRadius = 8;
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

// ─── 绑定引擎回调 ─────────────────────────────────────────
- (void)bindEngine {
    __weak typeof(self) weak = self;
    [JDAutoEngine shared].logCallback = ^(NSString *msg) {
        [weak appendLog:msg];
    };
    [JDAutoEngine shared].stateCallback = ^(JDAutoState state) {
        [weak updateButtonStates:state];
    };
}

// ─── 按钮动作 ─────────────────────────────────────────────
- (void)onStart {
    [self.phoneField resignFirstResponder];
    [self.apiField resignFirstResponder];
    [self saveConfig];

    JDAutoEngine *eng = [JDAutoEngine shared];
    eng.phone  = self.phoneField.text;
    eng.apiURL = self.apiField.text;

    if (eng.state == JDAutoStatePaused) {
        [eng resume];
    } else {
        self.logView.text = @"";
        [eng start];
    }
}

- (void)onPause {
    [[JDAutoEngine shared] pause];
}

- (void)onStop {
    [[JDAutoEngine shared] stop];
}

- (void)onTextChanged {
    [self saveConfig];
}

// ─── 按钮状态更新 ─────────────────────────────────────────
- (void)updateButtonStates:(JDAutoState)state {
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (state) {
            case JDAutoStateIdle:
                self.statusLabel.text = @"● 空闲";
                self.statusLabel.textColor = RGB(100, 200, 100);
                self.startBtn.enabled = YES;
                self.pauseBtn.enabled = NO;
                self.stopBtn.enabled  = NO;
                self.startBtn.alpha = 1.0;
                self.pauseBtn.alpha = 0.4;
                self.stopBtn.alpha  = 0.4;
                [self.startBtn setTitle:@"▶ 开始" forState:UIControlStateNormal];
                break;
            case JDAutoStateRunning:
                self.statusLabel.text = @"● 运行中";
                self.statusLabel.textColor = RGB(50, 200, 255);
                self.startBtn.enabled = NO;
                self.pauseBtn.enabled = YES;
                self.stopBtn.enabled  = YES;
                self.startBtn.alpha = 0.4;
                self.pauseBtn.alpha = 1.0;
                self.stopBtn.alpha  = 1.0;
                break;
            case JDAutoStatePaused:
                self.statusLabel.text = @"● 已暂停";
                self.statusLabel.textColor = RGB(255, 200, 50);
                self.startBtn.enabled = YES;
                self.pauseBtn.enabled = NO;
                self.stopBtn.enabled  = YES;
                self.startBtn.alpha = 1.0;
                self.pauseBtn.alpha = 0.4;
                self.stopBtn.alpha  = 1.0;
                [self.startBtn setTitle:@"▶ 继续" forState:UIControlStateNormal];
                break;
            case JDAutoStateStopped:
                self.statusLabel.text = @"● 已停止";
                self.statusLabel.textColor = RGB(200, 80, 80);
                self.startBtn.enabled = YES;
                self.pauseBtn.enabled = NO;
                self.stopBtn.enabled  = NO;
                self.startBtn.alpha = 1.0;
                self.pauseBtn.alpha = 0.4;
                self.stopBtn.alpha  = 0.4;
                [self.startBtn setTitle:@"▶ 开始" forState:UIControlStateNormal];
                break;
        }
    });
}

// ─── 日志追加 ─────────────────────────────────────────────
- (void)appendLog:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.logView.text = [self.logView.text stringByAppendingFormat:@"%@\n", msg];
        // 自动滚动到底部
        NSRange range = NSMakeRange(self.logView.text.length - 1, 1);
        [self.logView scrollRangeToVisible:range];
    });
}

// ─── 配置持久化 ───────────────────────────────────────────
- (void)saveConfig {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:self.phoneField.text forKey:@"jdauto_phone"];
    [ud setObject:self.apiField.text   forKey:@"jdauto_api"];
    [ud synchronize];
}

- (void)loadSavedConfig {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *phone = [ud stringForKey:@"jdauto_phone"];
    NSString *api   = [ud stringForKey:@"jdauto_api"];
    if (phone) self.phoneField.text = phone;
    if (api)   self.apiField.text   = api;
}

@end

// ═══════════════════════════════════════════════════════════
// JDFloatingWindow：可拖动的悬浮窗
// ═══════════════════════════════════════════════════════════
@interface JDFloatingWindow ()
@property (nonatomic, strong) JDFloatingWindowVC *contentVC;
@property (nonatomic, assign) CGPoint panOffset;
@end

@implementation JDFloatingWindow

+ (instancetype)shared {
    static JDFloatingWindow *s;
    static dispatch_once_t t;
    dispatch_once(&t, ^{
        CGRect screen = [UIScreen mainScreen].bounds;
        CGRect frame  = CGRectMake(screen.size.width - kW - 10,
                                   screen.size.height / 2 - kH / 2,
                                   kW, kH);
        s = [[JDFloatingWindow alloc] initWithFrame:frame];
        s.windowLevel = UIWindowLevelAlert + 100;
        s.layer.cornerRadius = 14;
        s.layer.shadowColor  = [UIColor blackColor].CGColor;
        s.layer.shadowOpacity = 0.6;
        s.layer.shadowRadius  = 12;
        s.layer.shadowOffset  = CGSizeMake(0, 4);

        JDFloatingWindowVC *vc = [JDFloatingWindowVC new];
        s.contentVC = vc;
        s.rootViewController = vc;

        // 拖动手势
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
            initWithTarget:s action:@selector(onPan:)];
        [s addGestureRecognizer:pan];
    });
    return s;
}

- (void)show {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hidden = NO;
        [self makeKeyAndVisible];
    });
}

- (void)hide {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hidden = YES;
    });
}

- (void)appendLog:(NSString *)msg {
    [self.contentVC appendLog:msg];
}

// ─── 拖动逻辑 ─────────────────────────────────────────────
- (void)onPan:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:nil];
    CGRect  frame = self.frame;
    frame.origin.x += translation.x;
    frame.origin.y += translation.y;

    // 限制不超出屏幕
    CGRect screen = [UIScreen mainScreen].bounds;
    frame.origin.x = MAX(0, MIN(frame.origin.x, screen.size.width  - kW));
    frame.origin.y = MAX(0, MIN(frame.origin.y, screen.size.height - kH));

    self.frame = frame;
    [pan setTranslation:CGPointZero inView:nil];
}

@end
