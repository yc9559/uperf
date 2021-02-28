#!/system/bin/sh
# Uperf Library
# https://github.com/yc9559/
# Author: Matt Yang
# Version: 20210225

BASEDIR="$(dirname "$0")"
. $BASEDIR/pathinfo.sh
. $BASEDIR/libcommon.sh
. $BASEDIR/libcgroup.sh

###############################
# PATHs
###############################

UPERF_REL="$BIN_DIR"
UPERF_NAME="uperf"

###############################
# Uperf tool functions
###############################

uperf_config_path="$MODULE_PATH/config/cfg_uperf.json"
uperf_log_path="/sdcard/Android/log_uperf.txt"
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
    # raise inotify limit
    lock_val "131072" /proc/sys/fs/inotify/max_queued_events
    lock_val "131072" /proc/sys/fs/inotify/max_user_watches
    lock_val "1024" /proc/sys/fs/inotify/max_user_instances

    # start uperf
    "$MODULE_PATH/$UPERF_REL/$UPERF_NAME" -o "$uperf_log_path" "$uperf_config_path"
    # waiting for uperf initialization
    sleep 2
    # uperf shouldn't preempt foreground tasks, pin on cpu0-1
    change_task_affinity "$UPERF_NAME" "3"
}
