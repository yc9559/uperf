MODDIR=${0%/*}

# do not place empty json if it doesn't exist in system
# vendor/etc/powerhint.json: android perf hal
# vendor/etc/powerscntbl.cfg: mediatek perf hal (android 9)
# vendor/etc/powerscntbl.xml: mediatek perf hal (android 10+)
# vendor/etc/perf/targetconfig.json: qualcomm perf hal targets
perfcfgs="
vendor/etc/powerhint.json
vendor/etc/powerscntbl.cfg
vendor/etc/powerscntbl.xml
vendor/etc/perf/targetconfig.xml
"
for f in $perfcfgs; do
    [ ! -f "/$f" ] && rm "$MODDIR/system/$f"
done

# drivers/net/wireless/cnss2/main.c in kworker/u16:1 Tainted
# because cnss: fatal: MHI power up returns timeout, which QMI timeout is 10000 ms 
# for f in $(find /sys/devices/virtual/workqueue "cpumask"); do
#     echo 7f > $f
# done
