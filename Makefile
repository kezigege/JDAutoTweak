THEOS_DEVICE_IP    ?= 192.168.1.100
THEOS_DEVICE_PORT  ?= 22
TARGET             := iphone:clang:16.5:14.0
ARCHS              := arm64

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
JDAutoTweak_INSTALL_PATH = /Applications

include $(THEOS)/makefiles/application.mk
