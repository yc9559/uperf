#!/system/bin/sh
# Module Path Header
# https://github.com/yc9559/
# Author: Matt Yang

SCRIPT_DIR="script"
BIN_DIR="bin"
MODULE_PATH="$(dirname $(readlink -f "$0"))"
MODULE_PATH="${MODULE_PATH%\/$SCRIPT_DIR}"
PANEL_FILE="/sdcard/Android/panel_uperf.txt"
LOG_FILE="/sdcard/Android/log_uperf_initsvc.log"

# prefer to use magisk's busybox and busybox for android ndk
PATH="/sbin:/system/sbin:/system/xbin:/system/bin:/vendor/xbin:/vendor/bin"
PATH="/sbin/.magisk/busybox:/sbin/.core/busybox:/magisk/.core/busybox:$PATH"
