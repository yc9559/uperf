#!/vendor/bin/sh
# Uperf Service Script
# https://github.com/yc9559/
# Author: Matt Yang
# Version: 20200401

BASEDIR="$(dirname $(readlink -f "$0"))"

wait_until_login()
{
    # we doesn't have the permission to rw "/sdcard" before the user unlocks the screen
    local test_file
    test_file="/sdcard/Android/$(mktemp -u XXXXXXXX)"
    while [ ! -f "$test_file" ]; do
        touch "$test_file"
        sleep 1
    done
    rm "$test_file"
}

wait_until_login
# do not sleep 60, may causing MIUI 12 launcher freezed by sfanalysis
sh $BASEDIR/run_uperf.sh
