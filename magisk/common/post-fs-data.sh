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

if [ -f "$MODDIR/flags/.need_recuser" ]; then
    rm -f $MODDIR/flags/.need_recuser
    true > $MODDIR/disable
else
    true > $MODDIR/flags/.need_recuser
fi

remove_unnecessary_overlay
