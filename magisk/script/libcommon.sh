#!/system/bin/sh
# Basic Tool Library
# https://github.com/yc9559/
# Author: Matt Yang
# Version: 20200227

BASEDIR="$(dirname "$0")"
. $BASEDIR/pathinfo.sh

###############################
# Basic tool functions
###############################

# $1:value $2:file path
lock_val() 
{
    if [ -f "$2" ]; then
        chmod 0666 "$2" 2> /dev/null
        echo "$1" > "$2"
        chmod 0444 "$2" 2> /dev/null
    fi
}

# $1:value $2:file path
mutate() 
{
    if [ -f "$2" ]; then
        chmod 0666 "$2" 2> /dev/null
        echo "$1" > "$2"
    fi
}

# $1:value $2:list
has_val_in_list()
{
    for item in $2; do
        if [ "$1" == "$item" ]; then
            echo "true"
            return
        fi
    done
    echo "false"
}

###############################
# Config File Operator
###############################

# $1:key $return:value(string)
read_cfg_value()
{
    local value=""
    if [ -f "$PANEL_FILE" ]; then
        value="$(grep "^$1=" "$PANEL_FILE" | head -n 1 | tr -d ' ' | cut -d= -f2)"
    fi
    echo "$value"
}

# $1:content
write_panel()
{
    echo "$1" >> "$PANEL_FILE"
}

clear_panel()
{
    true > "$PANEL_FILE"
}

wait_until_login()
{
    # whether in lock screen, tested on Android 7.1 & 10.0
    # in case of other magisk module remounting /data as RW
    while [ "$(dumpsys window policy | grep mInputRestricted=true)" != "" ]; do
        sleep 2
    done
    # we doesn't have the permission to rw "/sdcard" before the user unlocks the screen
    while [ ! -d "/sdcard/Android" ]; do
        sleep 2
    done
}

###############################
# Cgroup functions
###############################

# $1:task_name $2:cgroup_name $3:"cpuset"/"stune"
change_task_cgroup()
{
    # avoid matching grep itself
    # ps -Ao pid,args | grep kswapd
    # 150 [kswapd0]
    # 16490 grep kswapd
    local ps_ret
    ps_ret="$(ps -Ao pid,args)"
    for temp_pid in $(echo "$ps_ret" | grep "$1" | awk '{print $1}'); do
        for temp_tid in $(ls "/proc/$temp_pid/task/"); do
            echo "$temp_tid" > "/dev/$3/$2/tasks"
        done
    done
}

# $1:task_name $2:hex_mask(0x00000003 is CPU0 and CPU1)
change_task_affinity()
{
    # avoid matching grep itself
    # ps -Ao pid,args | grep kswapd
    # 150 [kswapd0]
    # 16490 grep kswapd
    local ps_ret
    ps_ret="$(ps -Ao pid,args)"
    for temp_pid in $(echo "$ps_ret" | grep "$1" | awk '{print $1}'); do
        for temp_tid in $(ls "/proc/$temp_pid/task/"); do
            taskset -p "$2" "$temp_tid"
        done
    done
}

# $1:task_name $2:nice(relative to 120)
change_task_nice()
{
    # avoid matching grep itself
    # ps -Ao pid,args | grep kswapd
    # 150 [kswapd0]
    # 16490 grep kswapd
    local ps_ret
    ps_ret="$(ps -Ao pid,args)"
    for temp_pid in $(echo "$ps_ret" | grep "$1" | awk '{print $1}'); do
        for temp_tid in $(ls "/proc/$temp_pid/task/"); do
            renice "$2" -p "$temp_tid"
        done
    done
}

###############################
# Platform info functions
###############################

# $1:"4.14" return:string_in_version
match_linux_version()
{
    echo "$(cat /proc/version | grep "$1")"
}

# return:platform_name
get_platform_name()
{
    echo "$(getprop ro.board.platform)"
}
