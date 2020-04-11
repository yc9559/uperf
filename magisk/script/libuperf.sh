#!/system/bin/sh
# Uperf Library
# https://github.com/yc9559/
# Author: Matt Yang
# Version: 20200411

BASEDIR="$(dirname "$0")"
. $BASEDIR/pathinfo.sh
. $BASEDIR/libcommon.sh

###############################
# PATHs
###############################

UPERF_REL="$BIN_DIR"
UPERF_NAME="uperf"

###############################
# Uperf tool functions
###############################

uperf_config_path="$MODULE_PATH/config/cfg_uperf.json"
uperf_log_path="/sdcard/Android/log_uperf.log"
uperf_powermode_node="/data/uperf_powermode"

# $1:mode_name
uperf_set_powermode()
{
    mutate "$1" $uperf_powermode_node
}

uperf_status()
{
    # (uperfd & uperf) or (uperfd & new_uperf & old_uperf)
    # if [ "$(ps -A | grep "$UPERF_NAME" | wc -l)" -ge 2 ]; then
    #     echo "Running. Details see $uperf_log_path."
    # else
    #     echo "Not running. Reasons see $uperf_log_path."
    # fi
    echo "Details see $uperf_log_path."
}

uperf_stop()
{
    killall "$UPERF_NAME"
}

uperf_start()
{
    # CANNOT LINK EXECUTABLE ".../bin/uperf": "/apex/com.android.runtime/lib64/libc++.so" is 64-bit instead of 32-bit
    # ...because LD_LIBRARY_PATH=":/apex/com.android.runtime/lib64"
    LD_LIBRARY_PATH=""

    # pretend to be system binary
    local uperf_bin_path
    uperf_bin_path="$MODULE_PATH/$UPERF_REL/$UPERF_NAME"
    [ -f "/system/bin/$UPERF_NAME" ] && uperf_bin_path="/system/bin/$UPERF_NAME"
    "$uperf_bin_path" -o "$uperf_log_path" "$uperf_config_path" 2>> "$uperf_log_path"
}
