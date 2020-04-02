#!/system/bin/sh
# Module Path Header
# https://github.com/yc9559/
# Author: Matt Yang

SCRIPT_DIR="/script"
BIN_DIR="/bin"
MODULE_PATH="$(dirname $(readlink -f "$0"))"
MODULE_PATH="${MODULE_PATH%$SCRIPT_DIR}"
PANEL_FILE="/sdcard/Android/panel_uperf.txt"
PATH="/sbin/.magisk/busybox:/sbin:/system/sbin:/product/bin:/apex/com.android.runtime/bin:/system/bin:/system/xbin:/odm/bin:/vendor/bin:/vendor/xbin"
