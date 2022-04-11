#!/vendor/bin/sh
wait_until_login() {
    # in case of /data encryption is disabled
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        sleep 1
    done

    # we doesn't have the permission to rw "/sdcard" before the user unlocks the screen
    local test_file="/sdcard/Android/.PERMISSION_TEST"
    true >"$test_file"
    while [ ! -f "$test_file" ]; do
        true >"$test_file"
        sleep 1
    done
    rm "$test_file"
}
on_remove() {
    #We could test it future when using newer Magisk
    #wait_until_login
    rm -rf /sdcard/yc/uperf/ /data/adb/modules/uperf /data/adb/modules_update/uperf
    chmod 666 /data/powercfg*
    rm -rf /data/powercfg*
    rm -rf /sdcard/yc/uperf #not remove dfps config
    rm -rf /sdcard/Android/yc/uperf

}
(on_remove &)
