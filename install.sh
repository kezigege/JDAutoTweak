#!/bin/bash
# ─────────────────────────────────────────────────────────
# JDAutoTweak 一键编译安装脚本
# 在 macOS + Theos 环境下运行
# ─────────────────────────────────────────────────────────

set -e

echo "========================================"
echo "  JDAutoTweak 编译安装"
echo "========================================"

# 检查 Theos 是否安装
if [ -z "$THEOS" ]; then
    echo "[错误] 未设置 \$THEOS 环境变量"
    echo "请先安装 Theos: https://theos.dev/docs/installation"
    exit 1
fi

# 设置目标设备 IP（修改为你的手机 IP）
export THEOS_DEVICE_IP="${THEOS_DEVICE_IP:-192.168.1.100}"
export THEOS_DEVICE_PORT="${THEOS_DEVICE_PORT:-22}"

echo "[1/3] 清理旧构建..."
make clean

echo "[2/3] 编译..."
make -j4

echo "[3/3] 打包为 .deb..."
make package

echo ""
echo "========================================"
echo "  编译完成！"
echo "  .deb 文件在 packages/ 目录下"
echo ""
echo "  安装方式1（SSH 直接安装）："
echo "    make install"
echo ""
echo "  安装方式2（手动传到手机）："
echo "    将 packages/*.deb 传到手机"
echo "    在手机终端执行: dpkg -i *.deb"
echo "    然后执行: uicache -p /Applications/JDAutoTweak.app"
echo "    重启 SpringBoard: killall SpringBoard"
echo "========================================"
