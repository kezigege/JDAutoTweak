# JDAutoTweak — 京东注册自动化插件

iOS 16 越狱插件（Sileo），实现步骤 27~31 的自动化操作。

---

## 功能概述

| 步骤 | 操作 |
|------|------|
| Step 27 | 自动打开 Focus 浏览器 → 导航到京东注册页 → 填入手机号 → 点击「获取验证码」→ 检测安全验证弹窗（等待人工处理） |
| Step 28 | 轮询接码 API → 将验证码填入 Focus 浏览器验证码输入框 → 返回 Home |
| Step 29 | 打开京东 App → 处理同意弹窗 → 轮询接码 API（去重）→ 保存新验证码 |
| Step 30 | 打开 Focus 浏览器 → 点击「同意协议并登录」→ 处理「未注册」弹窗 → 返回 Home |
| Step 31 | 打开京东 App → 填入步骤 29 保存的验证码 |

**悬浮窗功能**：手机号 + 接码 API 输入框、开始/暂停/继续/停止按钮、实时运行日志，可拖动到任意位置。

---

## 环境要求

- iOS 16.x，已越狱（rootless 或 rootful 均可）
- Sileo 已安装
- 手机上已安装：**Focus Browser**、**京东 App**
- 编译环境：macOS + [Theos](https://theos.dev/docs/installation)

---

## 编译安装

### 方式一：Theos 编译（推荐）

```bash
# 1. 克隆/复制本项目到 macOS
# 2. 设置手机 IP
export THEOS_DEVICE_IP=192.168.1.xxx   # 改为你手机的 IP

# 3. 一键编译安装
bash install.sh
make install
```

### 方式二：手动安装 .deb

```bash
# 编译打包
make package

# 将 packages/*.deb 通过 AirDrop 或 SSH 传到手机
# 在手机终端（NewTerm/SSH）执行：
dpkg -i /var/mobile/JDAutoTweak_1.0.0_iphoneos-arm64.deb
uicache -p /Applications/JDAutoTweak.app
killall SpringBoard
```

---

## 使用方法

1. 安装完成后，桌面出现 **「JD自动化」** 图标
2. 点击图标打开，悬浮窗自动显示在屏幕上
3. 在悬浮窗中填入：
   - **手机号**：要注册的手机号码
   - **接码API**：接码平台的 API 链接（格式同 phones.txt：`http://xxx.com/...`）
4. 点击 **▶ 开始** 启动自动化流程
5. 遇到安全验证时，手动完成验证，插件会自动检测并继续
6. 可随时点击 **⏸ 暂停** 暂停，**▶ 继续** 恢复，**⏹ 停止** 终止

> **注意**：手机号和接码 API 会自动保存，下次打开无需重新填写。

---

## 目录结构

```
JDAutoTweak/
├── Sources/JDAutoTweak/
│   ├── main.m                  # App 入口
│   ├── JDAppDelegate.h/.m      # AppDelegate
│   ├── JDFloatingWindow.h/.m   # 悬浮窗 UI
│   └── JDAutoEngine.h/.m       # 核心自动化引擎（步骤27~31）
├── layout/
│   └── Applications/
│       └── JDAutoTweak.app/
│           └── Info.plist      # App 配置
├── Makefile                    # Theos 编译配置
├── control                     # Sileo 包信息
├── entitlements.plist          # 越狱权限
├── install.sh                  # 一键编译脚本
└── README.md
```

---

## 常见问题

**Q: 安装后桌面没有图标？**
执行 `uicache -p /Applications/JDAutoTweak.app` 后重启 SpringBoard。

**Q: 点击按钮没反应？**
确认 Focus Browser 和京东 App 已安装，且 Bundle ID 正确：
- Focus Browser: `com.focus-app.focus`
- 京东: `com.jingdong.app.mall`

**Q: 验证码填不进去？**
部分 App 的输入框使用了自定义组件，可能需要根据实际 UI 调整 `findTextFieldWithPlaceholderContaining:` 的查找逻辑。

**Q: 安全验证弹窗检测不到？**
插件通过查找包含「安全驗證」「滑動驗證」文字的 UILabel 来检测弹窗。如果 App 更新后文字变化，需要相应修改 `detectSecurityVerifyPopupInBundleID:` 方法中的关键词。
