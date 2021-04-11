#!/system/bin/sh
# Uperf https://github.com/yc9559/uperf/
# Author: Matt Yang

# Runonce after boot, to speed up the transition of power modes in powercfg

BASEDIR="$(dirname "$0")"
. $BASEDIR/libcommon.sh
. $BASEDIR/libcgroup.sh
. $BASEDIR/libpowercfg.sh
. $BASEDIR/libuperf.sh

unify_cgroup()
{
    # clear stune & uclamp
    for g in background foreground top-app; do
        lock_val "0" /dev/stune/$g/schedtune.sched_boost_no_override
        lock_val "0" /dev/stune/$g/schedtune.boost
        lock_val "0" /dev/stune/$g/schedtune.prefer_idle
        lock_val "0" /dev/cpuctl/$g/cpu.uclamp.sched_boost_no_override
        lock_val "0" /dev/cpuctl/$g/cpu.uclamp.min
        lock_val "0" /dev/cpuctl/$g/cpu.uclamp.latency_sensitive
    done
    for cg in stune cpuctl; do
        for p in $(cat /dev/$cg/top-app/tasks); do
            echo $p > /dev/$cg/foreground/tasks
        done
    done

    # launcher is usually in foreground group, uperf will take care of them
    lock_val "0-7" /dev/cpuset/foreground/boost/cpus
    lock_val "0-7" /dev/cpuset/foreground/cpus
    # VMOS may set cpuset/background/cpus to "0"
    lock /dev/cpuset/background/cpus

    # Reduce Perf Cluster Wakeup
    # daemons
    pin_proc_on_pwr "crtc_commit"
    pin_proc_on_pwr "crtc_event"
    pin_proc_on_pwr "pp_event"
    pin_proc_on_pwr "netd"
    pin_proc_on_pwr "mdnsd"
    pin_proc_on_pwr "pdnsd"
    pin_proc_on_pwr "analytics"
    pin_proc_on_pwr "daemon"
    change_task_affinity "android\.system\.suspend" "7f"
    # hardware services, eg. android.hardware.sensors@1.0-service
    pin_proc_on_pwr "\.hardware\."
    change_task_affinity "\.hardware\." "ff"
    # pwr cluster has enough capacity for surfaceflinger
    pin_proc_on_pwr "surfaceflinger"
    # MediaProvider is background service
    pin_proc_on_pwr "android\.process\.media"
    unpin_proc "com\.android\.providers\.media"
    change_thread_nice "com\.android\.providers\.media" "Thread-" "4"
    change_thread_affinity "com\.android\.providers\.media" "Thread-" "f"
    # com.miui.securitycenter & com.miui.securityadd
    pin_proc_on_pwr "miui\.security"
    # ueventd related to hotplug of camera, wifi, usb... 
    # pin_proc_on_pwr "ueventd"

    # system_server blacklist
    pin_proc_on_mid "system_server"
    # input dispatcher
    change_thread_high_prio "system_server" "input"
    # related to camera startup
    change_thread_affinity "system_server" "ProcessManager" "ff"
    # not important
    pin_thread_on_pwr "system_server" "Miui"
    pin_thread_on_pwr "system_server" "ActivityManager"
    pin_thread_on_pwr "system_server" "Connect"
    pin_thread_on_pwr "system_server" "Network"
    pin_thread_on_pwr "system_server" "Wifi"
    pin_thread_on_pwr "system_server" "backup"
    pin_thread_on_pwr "system_server" "Sync"
    pin_thread_on_pwr "system_server" "Observer"
    pin_thread_on_pwr "system_server" "Power"
    pin_thread_on_pwr "system_server" "Sensor"
    pin_thread_on_pwr "system_server" "batterystats"
    pin_thread_on_pwr "system_server" "Thread-"
    pin_thread_on_pwr "system_server" "pool-"
    pin_thread_on_pwr "system_server" "Jit thread pool"
    pin_thread_on_pwr "system_server" "CachedAppOpt"
    pin_thread_on_pwr "system_server" "Greezer"
    pin_thread_on_pwr "system_server" "TaskSnapshot"
    pin_thread_on_pwr "system_server" "Oom"
    change_thread_nice "system_server" "Greezer" "4"
    change_thread_nice "system_server" "TaskSnapshot" "4"
    change_thread_nice "system_server" "Oom" "4"
    # pin_thread_on_pwr "system_server" "Async" # it blocks camera
    # pin_thread_on_pwr "system_server" "\.bg" # it blocks binders
    # do not let GC thread block system_server
    # pin_thread_on_mid "system_server" "HeapTaskDaemon"
    # pin_thread_on_mid "system_server" "FinalizerDaemon"

    # Render Pipeline
    # speed up searching service binder
    change_task_cgroup "servicemanag" "top-app" "cpuset"
    # prevent display service from being preempted by normal tasks
    # vendor.qti.hardware.display.allocator-service cannot be set to RT policy, will be reset to 120
    unpin_proc "\.hardware\.display"
    change_task_rt "\.hardware\.display" "2"
    change_task_rt "\.composer" "2"
    # vendor.qti.hardware.perf@2.2-service blocks hardware.display.composer-service
    # perf will automatically set self to prio=100
    unpin_proc "\.hardware\.perf"
    # fix laggy bilibili feed scrolling
    change_thread_cgroup "android\.phone" "Binder" "top-app" "cpuset"
    # sometimes surfaceflinger main thread has quite high load
    change_task_rt "surfaceflinger" "4"
    change_main_thread_cgroup "surfaceflinger" "top-app" "cpuset"
    change_main_thread_cgroup "surfaceflinger" "top-app" "stune"
    change_main_thread_cgroup "surfaceflinger" "top-app" "cpuctl"
    pin_thread_on_mid "surfaceflinger" "app"
    # let UX related Binders run with top-app
    change_thread_cgroup "surfaceflinger" "^Binder" "top-app" "cpuset"
    change_thread_cgroup "system_server" "^Binder" "top-app" "cpuset"
    change_thread_cgroup "system_server" "^Binder" "top-app" "stune"
    change_thread_cgroup "system_server" "^Binder" "top-app" "cpuctl"
    change_thread_cgroup "\.hardware\.display" "^Binder" "top-app" "cpuset"
    change_thread_cgroup "\.hardware\.display" "^HwBinder" "top-app" "cpuset"
    change_thread_cgroup "\.composer" "^Binder" "top-app" "cpuset"
    # transition animation
    change_thread_cgroup "system_server" "android\.anim" "top-app" "cpuset"
    change_thread_cgroup "system_server" "android\.anim" "top-app" "stune"
    change_thread_cgroup "system_server" "android\.anim" "top-app" "cpuctl"
    change_thread_cgroup "system_server" "android\.display" "top-app" "cpuset"
    change_thread_cgroup "system_server" "android\.display" "top-app" "stune"
    change_thread_cgroup "system_server" "android\.display" "top-app" "cpuctl"
    change_thread_cgroup "system_server" "android\.ui" "top-app" "cpuset"

    # Heavy Scene Boost
    # camera & video recording
    unpin_proc "\.hardware\.camera"
    pin_proc_on_mid "^camera"
    pin_proc_on_mid "\.hardware\.audio"
    pin_proc_on_mid "^audio"
    # provide best performance for fingerprint service
    pin_proc_on_perf "\.hardware\.biometrics\."
    change_task_high_prio "\.hardware\.biometrics\."
    # mfp-daemon: goodix in-screen fingerprint daemon
    pin_proc_on_perf "mfp"
    change_task_high_prio "mfp"
    # boost app boot process, zygote--com.xxxx.xxx
    unpin_proc "zygote"
    change_task_high_prio "zygote"
    # boost android process pool, usap--com.xxxx.xxx
    unpin_proc "usap"
    change_task_high_prio "usap"

    # busybox fork from magiskd
    pin_proc_on_mid "magiskd"
    change_task_nice "magiskd" "39"
}

unify_cpufreq()
{
    # no msm_performance limit
    set_cpufreq_min "0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0"
    set_cpufreq_max "0:9999000 1:9999000 2:9999000 3:9999000 4:9999000 5:9999000 6:9999000 7:9999000"

    # stop sched core_ctl, game's main thread need be pinned on prime core
    set_corectl_param "enable" "0:0 2:0 4:0 6:0 7:0"

    # clear cpu load scale factor
    for i in 0 1 2 3 4 5 6 7 8 9; do
        lock_val "0" $CPU/cpu$i/sched_load_boost
    done

    # unify governor, use schedutil if kernel has it
    set_governor_param "scaling_governor" "0:interactive 2:interactive 4:interactive 6:interactive 7:interactive"
    set_governor_param "scaling_governor" "0:schedutil 2:schedutil 4:schedutil 6:schedutil 7:schedutil"

    # unify walt schedutil governor
    set_governor_param "schedutil/hispeed_freq" "0:1200000 2:1200000 4:1200000 6:1200000 7:1200000"
    set_governor_param "schedutil/hispeed_freq" "0:1000000"
    set_governor_param "schedutil/hispeed_load" "0:70 2:70 4:70 6:70 7:70"
    set_governor_param "schedutil/pl" "0:0 2:0 4:0 6:0 7:0"
    set_governor_param "schedutil/pl" "7:1"

    # unify hmp interactive governor, only 2+2 4+2 4+4
    set_governor_param "interactive/use_sched_load" "0:1 2:1 4:1"
    set_governor_param "interactive/use_migration_notif" "0:1 2:1 4:1"
    set_governor_param "interactive/enable_prediction" "0:0 2:0 4:0"
    set_governor_param "interactive/ignore_hispeed_on_notif" "0:0 2:0 4:0"
    set_governor_param "interactive/fast_ramp_down" "0:0 2:0 4:0"
    set_governor_param "interactive/boostpulse_duration" "0:0 2:0 4:0"
    set_governor_param "interactive/boost" "0:0 2:0 4:0"
    set_governor_param "interactive/timer_slack" "0:12345678 2:12345678 4:12345678"
}

unify_sched()
{
    # disable sched global placement boost
    lock_val "0" $SCHED/sched_boost
    lock_val "0" $SCHED/sched_walt_rotate_big_tasks
    lock_val "1000" $SCHED/sched_min_task_util_for_boost
    lock_val "1000" $SCHED/sched_min_task_util_for_colocation
    lock_val "0" $SCHED/sched_conservative_pl
    lock_val "0" $SCHED/sched_force_lb_enable
    lock_val "0" $SCHED/sched_boost_top_app

    # unify WALT HMP sched
    lock_val "5" $SCHED/sched_ravg_hist_size
    lock_val "2" $SCHED/sched_window_stats_policy
    lock_val "90" $SCHED/sched_spill_load
    lock_val "1" $SCHED/sched_restrict_cluster_spill
    lock_val "1" $SCHED/sched_prefer_sync_wakee_to_waker
    lock_val "200000" $SCHED/sched_freq_inc_notify
    lock_val "400000" $SCHED/sched_freq_dec_notify

    # place a little heavier processes on big cluster, due to Cortex-A55 poor efficiency
    # The same Binder, A55@1.0g took 7.3ms，A76@1.0g took 3.0ms, in this case, A76's efficiency is 2.4x of A55's.
    # However in EAS model A76's efficiency is 1.7x of A55's, so the down migrate threshold need compensate.
    set_sched_migrate "40" "20" "999" "888"
    set_sched_migrate "40 80" "20 40" "999" "888"

    # prefer to use prev cpu, decrease jitter from 0.5ms to 0.3ms with lpm settings
    # system_server binders maybe pinned on perf cluster due to this
    # lock_val "10000000" $SCHED/sched_migration_cost_ns
}

unify_lpm()
{
    # enter C-state level 3 took ~500us
    # Qualcomm C-state ctrl
    lock_val "0" $LPM/sleep_disabled
    lock_val "0" $LPM/lpm_ipi_prediction
    if [ -f "$LPM/bias_hyst" ]; then
        lock_val "2" $LPM/bias_hyst
        lock_val "0" $LPM/lpm_prediction
    elif [ -f "$SCHED/sched_busy_hyst_ns" ]; then
        lock_val "255" $SCHED/sched_busy_hysteresis_enable_cpus
        lock_val "0" $SCHED/sched_coloc_busy_hysteresis_enable_cpus
        lock_val "2000000" $SCHED/sched_busy_hyst_ns
        lock_val "0" $LPM/lpm_prediction
    else
        lock_val "1" $LPM/lpm_prediction
    fi
}

disable_hotplug()
{
    # Exynos hotplug
    mutate "0" /sys/power/cpuhotplug/enabled
    mutate "0" $CPU/cpuhotplug/enabled

    # turn off msm_thermal
    lock_val "0" /sys/module/msm_thermal/core_control/enabled
    lock_val "N" /sys/module/msm_thermal/parameters/enabled

    # 3rd
    lock_val "0" /sys/kernel/intelli_plug/intelli_plug_active
    lock_val "0" /sys/module/blu_plug/parameters/enabled
    lock_val "0" /sys/devices/virtual/misc/mako_hotplug_control/enabled
    lock_val "0" /sys/module/autosmp/parameters/enabled
    lock_val "0" /sys/kernel/zen_decision/enabled

    # bring all cores online
    for i in 0 1 2 3 4 5 6 7 8 9; do
        mutate "1" $CPU/cpu$i/online
    done
}

disable_kernel_boost()
{
    # Qualcomm
    lock_val "0" /sys/devices/system/cpu/cpu_boost/parameters/input_boost_ms
    lock_val "0" /sys/devices/system/cpu/cpu_boost/parameters/powerkey_input_boost_ms
    lock_val "0" /sys/devices/system/cpu/cpu_boost/input_boost_ms
    lock_val "0" /sys/devices/system/cpu/cpu_boost/powerkey_input_boost_ms
    lock_val "0" /sys/module/cpu_boost/parameters/input_boost_ms
    lock_val "0" /sys/module/msm_performance/parameters/touchboost
    lock_val "0" /sys/module/cpu_boost/parameters/boost_ms

    # MediaTek
    # policy_status
    # [0] PPM_POLICY_PTPOD: Meature PMIC buck currents
    # [1] PPM_POLICY_UT: Unit test
    # [2] PPM_POLICY_FORCE_LIMIT: enabled
    # [3] PPM_POLICY_PWR_THRO: enabled
    # [4] PPM_POLICY_THERMAL: enabled
    # [5] PPM_POLICY_DLPT: Power measurment and power budget managing
    # [6] PPM_POLICY_HARD_USER_LIMIT: enabled
    # [7] PPM_POLICY_USER_LIMIT: enabled
    # [8] PPM_POLICY_LCM_OFF: disabled
    # [9] PPM_POLICY_SYS_BOOST: disabled
    # [10] PPM_POLICY_HICA: ?
    # Usage: echo <policy_idx> <1(enable)/0(disable)> > /proc/ppm/policy_status
    lock_val "1" /proc/ppm/enabled
    # used by uperf
    mutate "6 1" /proc/ppm/policy_status

    # Samsung
    mutate "0" /sys/class/input_booster/level
    mutate "0" /sys/class/input_booster/head
    mutate "0" /sys/class/input_booster/tail

    # Samsung EPIC interfaces, used by uperf
    # mutate "0" /dev/cluster0_freq_min
    # mutate "0" /dev/cluster1_freq_min
    # mutate "0" /dev/cluster2_freq_min
    # lock_val "0" /dev/bus_throughput
    # lock_val "0" /dev/gpu_freq_min
    # Samsung /kernel/sched/ems/...
    mutate "0" /sys/kernel/ems/eff_mode

    # Oneplus
    lock_val "N" /sys/module/control_center/parameters/cpu_boost_enable
    lock_val "N" /sys/module/control_center/parameters/ddr_boost_enable
    lock_val "0" /sys/module/aigov/parameters/enable
    lock_val "0" /sys/module/houston/parameters/ais_enable
    lock_val "0" /sys/module/houston/parameters/fps_boost_enable
    lock_val "0" /sys/module/houston/parameters/ht_registed
    # OnePlus opchain pins UX threads on the big cluster
    lock_val "0" /sys/module/opchain/parameters/chain_on

    # HTC
    lock_val "0" /sys/power/pnpmgr/touch_boost
    lock_val "0" /sys/power/pnpmgr/long_duration_touch_boost

    # 3rd
    lock_val "0" /sys/kernel/cpu_input_boost/enabled
    lock_val "0" /sys/kernel/cpu_input_boost/ib_freqs
    lock_val "0" /sys/kernel/cpu_input_boost/ib_duration_m
    lock_val "0" /sys/kernel/cpu_input_boost/ib_duration_ms
    lock_val "0" /sys/module/cpu_boost/parameters/input_boost_enabled
    lock_val "0" /sys/module/cpu_boost/parameters/dynamic_stune_boost
    lock_val "0" /sys/module/cpu_boost/parameters/input_boost_ms
    lock_val "0" /sys/module/cpu_boost/parameters/input_boost_ms_s2
    lock_val "0" /sys/module/dsboost/parameters/input_boost_duration
    lock_val "0" /sys/module/dsboost/parameters/input_stune_boost
    lock_val "0" /sys/module/dsboost/parameters/sched_stune_boost
    lock_val "0" /sys/module/dsboost/parameters/cooldown_boost_duration
    lock_val "0" /sys/module/dsboost/parameters/cooldown_stune_boost
    lock_val "0" /sys/module/cpu_input_boost/parameters/input_boost_duration
    lock_val "0" /sys/module/cpu_input_boost/parameters/dynamic_stune_boost
    lock_val "0" /sys/module/cpu_input_boost/parameters/input_boost_freq_lp
    lock_val "0" /sys/module/cpu_input_boost/parameters/input_boost_freq_hp
    lock_val "0" /sys/module/cpu_input_boost/parameters/input_boost_freq_gold
    lock_val "0" /sys/module/cpu_input_boost/parameters/flex_stune_boost_offset
    lock_val "0" /sys/module/cpu_input_boost/parameters/dynamic_stune_boost
    lock_val "0" /sys/module/cpu_input_boost/parameters/input_stune_boost_offset
    lock_val "0" /sys/module/cpu_input_boost/parameters/max_stune_boost_offset
    lock_val "0" /sys/module/cpu_input_boost/parameters/stune_boost_extender_ms
    lock_val "0" /sys/module/cpu_input_boost/parameters/max_stune_boost_extender_ms
    lock_val "0" /sys/module/cpu_input_boost/parameters/gpu_boost_extender_ms
    lock_val "0" /sys/module/cpu_input_boost/parameters/flex_boost_freq_gold
    lock_val "0" /sys/module/cpu_input_boost/parameters/flex_boost_freq_hp
    lock_val "0" /sys/module/cpu_input_boost/parameters/flex_boost_freq_lp
    lock_val "0" /sys/module/devfreq_boost/parameters/input_boost_duration
}

disable_userspace_boost()
{
    # Qualcomm perfd
    stop perfd 2> /dev/null

    # Qualcomm&MTK perfhal
    # keep perfhal running with empty config file in magisk mode
    [ "$(is_magisk)" == "false" ] && perfhal_stop

    # xiaomi perfservice
    stop vendor.perfservice

    # brain service maybe not smart
    stop oneplus_brain_service 2> /dev/null

    # disable service below will BOOM
    # stop vendor.power.stats-hal-1-0
    # stop vendor.power-hal-1-0
    # stop vendor.power-hal-1-1
    # stop vendor.power-hal-1-2
    # stop vendor.power-hal-1-3
}

log "PATH=$PATH"
log "sh=$(which sh)"
disable_userspace_boost
disable_kernel_boost
disable_hotplug
unify_cpufreq
unify_sched
unify_lpm

# make sure that all the related cpu is online
unify_cgroup

# start uperf once only
uperf_stop
uperf_start
