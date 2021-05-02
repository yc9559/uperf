MODDIR=${0%/*}

remove_unnecessary_overlay()
{
    # do not place empty json if it doesn't exist in system
    # vendor/etc/powerhint.json: android perf hal
    # vendor/etc/powerscntbl.cfg: mediatek perf hal (android 9)
    # vendor/etc/powerscntbl.xml: mediatek perf hal (android 10+)
    # vendor/etc/perf/commonresourceconfigs.json: qualcomm perf hal resource
    # vendor/etc/perf/targetresourceconfigs.json: qualcomm perf hal resource overrides
    perfcfgs="
    vendor/etc/powerhint.json
    vendor/etc/powerscntbl.cfg
    vendor/etc/powerscntbl.xml
    vendor/etc/perf/commonresourceconfigs.xml
    vendor/etc/perf/targetresourceconfigs.xml
    "
    for f in $perfcfgs; do
        [ ! -f "/$f" ] && rm "$MODDIR/system/$f"
    done

    rm -f $MODDIR/flags/enable_perfhal_stub
    for f in $perfcfgs; do
        [ -f "$MODDIR/system/$f" ] && true > $MODDIR/flags/enable_perfhal_stub
    done
}

remove_all_overlay()
{
    rm -rf "$MODDIR/system/vendor/etc"
}

crash_recuser()
{
    true > $MODDIR/flags/crash_on_postfs
    sleep 30
    rm -f $MODDIR/flags/crash_on_postfs
}

remove_unnecessary_overlay
[ -f "$MODDIR/flags/crash_on_postfs" ] && remove_all_overlay
(crash_recuser &)
