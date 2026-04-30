THEOS_DEVICE_IP    ?= 192.168.1.100
THEOS_DEVICE_PORT  ?= 22
TARGET             := iphone:clang:latest:15.0
ARCHS              := arm64 arm64e
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

# ── 编译为独立 App（桌面图标）────────────────────────────
APPLICATION_NAME = JDAutoTweak

JDAutoTweak_FILES = \
    Sources/JDAutoTweak/main.m \
    Sources/JDAutoTweak/JDAppDelegate.m \
    Sources/JDAutoTweak/JDFloatingWindow.m \
    Sources/JDAutoTweak/JDAutoEngine.m

JDAutoTweak_FRAMEWORKS = UIKit Foundation
JDAutoTweak_PRIVATE_FRAMEWORKS = AppSupport
JDAutoTweak_CODESIGN_FLAGS = -Sentitlements.plist
# Rootless 模式下 Theos 会自动处理安装路径，不需要手动指定为 /Applications
JDAutoTweak_CFLAGS = -fobjc-arc
JDAutoTweak_OBJCFLAGS = -fobjc-arc

include $(THEOS)/makefiles/application.mk
