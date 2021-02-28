#!/system/bin/sh
# Injector Library
# https://github.com/yc9559/
# Author: Matt Yang
# Version: 20210225

BASEDIR="$(dirname "$0")"
. $BASEDIR/pathinfo.sh
. $BASEDIR/libcommon.sh

###############################
# PATHs
###############################

INJ_REL="$BIN_DIR"
INJ_NAME="injector"

###############################
# Injector tool functions
###############################

# $1:process $2:dynamiclib $3:alog_tag
inj_do_inject()
{
    log "[begin] injecting $2 to $1"

    local lib_path
    if [ "$(is_aarch64)" == "true" ]; then
        lib_path="/system/lib64/$2"
    else
        lib_path="/system/lib/$2"
    fi

    # fallback to standlone mode
    [ ! -e "$lib_path" ] && lib_path="${MODULE_PATH}${lib_path}"

    "$MODULE_PATH/$INJ_REL/$INJ_NAME" "$1" "$lib_path" >> "$LOG_FILE"

    # Although injection may fail, remove inplicit SELinux operation
    # if [ "$?" != "0" ]; then
    #     log "Set SELinux to permissive, retry..."
    #     setenforce 0
    #     "$MODULE_PATH/$INJ_REL/$INJ_NAME" "$1" "$lib_path" >> "$LOG_FILE"
    # fi

    sleep 1
    logcat -d | grep -i "$3" >> "$LOG_FILE"

    log "[end] injecting $2 to $1"
}

inj_start()
{
    # raise inotify limit
    lock_val "131072" /proc/sys/fs/inotify/max_queued_events
    lock_val "131072" /proc/sys/fs/inotify/max_user_watches
    lock_val "1024" /proc/sys/fs/inotify/max_user_instances

    log "$(date '+%Y-%m-%d %H:%M:%S')"
    inj_do_inject "/system/bin/surfaceflinger" "libsfanalysis.so" "SfAnalysis"
    inj_do_inject "system_server" "libssanalysis.so" "SsAnalysis"
}

clear_log
[ -f "$MODULE_PATH/enable_injector" ] && inj_start
