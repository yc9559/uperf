#!/system/bin/sh
# Surfaceflinger Analysis Library
# https://github.com/yc9559/
# Author: Matt Yang
# Version: 20200516

BASEDIR="$(dirname "$0")"
. $BASEDIR/pathinfo.sh
. $BASEDIR/libcommon.sh

###############################
# PATHs
###############################

SFA_REL="$BIN_DIR"
SFA_NAME="injector"
SFA_LIB="libsfanalysis.so"

###############################
# SfAnalysis tool functions
###############################

sfa_start()
{
    # raise inotify limit
    lock_val "131072" /proc/sys/fs/inotify/max_queued_events
    lock_val "131072" /proc/sys/fs/inotify/max_user_watches
    lock_val "1024" /proc/sys/fs/inotify/max_user_instances

    local lib_path
    if [ "$(is_aarch64)" == "true" ]; then
        lib_path="/system/lib64/$SFA_LIB"
    else
        lib_path="/system/lib/$SFA_LIB"
    fi

    # fallback to standlone mode
    [ ! -f "$lib_path" ] && lib_path="$MODULE_PATH/$lib_path"

    echo "$(date '+%Y-%m-%d %H:%M:%S')" > /cache/injector.log
    "$MODULE_PATH/$SFA_REL/$SFA_NAME" "/system/bin/surfaceflinger" "$lib_path" >> /cache/injector.log

    # injection failed. Retry after setting SELinux to permissive
    if [ "$?" != "0" ]; then
        setenforce 0
        echo "Retry after setting SELinux to permissive." >> /cache/injector.log
        "$MODULE_PATH/$SFA_REL/$SFA_NAME" "/system/bin/surfaceflinger" "$lib_path" >> /cache/injector.log
    fi
}

[ -f "$MODULE_PATH/enable_sfanalysis" ] && sfa_start
