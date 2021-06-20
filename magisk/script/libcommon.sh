#!/system/bin/sh
# Basic Tool Library
# https://github.com/yc9559/
# Author: Matt Yang
# Version: 20210523

BASEDIR="$(dirname "$0")"
. $BASEDIR/pathinfo.sh

###############################
# Basic tool functions
###############################

# $1:value $2:filepaths
lock_val() 
{
    for p in $2; do
        if [ -f "$p" ]; then
            chmod 0666 "$p" 2> /dev/null
            echo "$1" > "$p"
            chmod 0444 "$p" 2> /dev/null
        fi
    done
}

# $1:value $2:filepaths
mutate() 
{
    for p in $2; do
        if [ -f "$p" ]; then
            chmod 0666 "$p" 2> /dev/null
            echo "$1" > "$p"
        fi
    done
}

# $1:file path
lock() 
{
    if [ -f "$1" ]; then
        chmod 0444 "$1" 2> /dev/null
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
        value="$(grep -i "^$1=" "$PANEL_FILE" | head -n 1 | tr -d ' ' | cut -d= -f2)"
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
    # in case of /data encryption is disabled
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        sleep 1
    done

    # we doesn't have the permission to rw "/sdcard" before the user unlocks the screen
    local test_file="/sdcard/Android/.PERMISSION_TEST"
    true > "$test_file"
    while [ ! -f "$test_file" ]; do
        true > "$test_file"
        sleep 1
    done
    rm "$test_file"
}

###############################
# Log
###############################

# $1:content
log()
{
    echo "$1" >> "$LOG_FILE"
}

clear_log()
{
    true > "$LOG_FILE"
}

###############################
# Platform info functions
###############################

# $1:"4.14" return:string_in_version
match_linux_version()
{
    echo "$(cat /proc/version | grep -i "$1")"
}

# return:platform_name
get_platform_name()
{
    echo "$(getprop ro.board.platform)"
}

# return_nr_core
get_nr_core()
{
    echo "$(cat /proc/stat | grep cpu[0-9] | wc -l)"
}

is_aarch64()
{
    if [ "$(getprop ro.product.cpu.abi)" == "arm64-v8a" ]; then
        echo "true"
    else
        echo "false"
    fi
}

is_mtk()
{
    if [ "$(getprop | grep ro.mtk)" != "" ]; then
        echo "true"
    else
        echo "false"
    fi
}

is_magisk()
{
    if [ "$(echo $BASEDIR | grep "^\/data\/adb\/modules")" != "" ]; then
        echo "true"
    else
        echo "false"
    fi
}
