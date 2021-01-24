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
    # clear stune
    mutate "0" /dev/stune/background/schedtune.sched_boost_no_override
    mutate "0" /dev/stune/background/schedtune.boost
    mutate "0" /dev/stune/background/schedtune.prefer_idle
    mutate "0" /dev/stune/foreground/schedtune.sched_boost_no_override
    mutate "0" /dev/stune/foreground/schedtune.boost
    mutate "0" /dev/stune/foreground/schedtune.prefer_idle
    mutate "1" /dev/stune/top-app/schedtune.sched_boost_no_override
    mutate "0" /dev/stune/top-app/schedtune.boost
    mutate "0" /dev/stune/top-app/schedtune.prefer_idle

    # clear uclamp
    mutate "0" /dev/cpuctl/background/cpu.uclamp.sched_boost_no_override
    mutate "0" /dev/cpuctl/background/cpu.uclamp.min
    mutate "0" /dev/cpuctl/background/cpu.uclamp.latency_sensitive
    mutate "0" /dev/cpuctl/foreground/cpu.uclamp.sched_boost_no_override
    mutate "0" /dev/cpuctl/foreground/cpu.uclamp.min
    mutate "0" /dev/cpuctl/foreground/cpu.uclamp.latency_sensitive
    mutate "1" /dev/cpuctl/top-app/cpu.uclamp.sched_boost_no_override
    mutate "0" /dev/cpuctl/top-app/cpu.uclamp.min
    mutate "0" /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive

    # launcher&home usually in foreground cpuset group
    mutate "4-6" /dev/cpuset/foreground/boost/cpus
    mutate "0-2,4-6" /dev/cpuset/foreground/cpus
    mutate "0-3" /dev/cpuset/background/cpus

    # Reduce Perf Cluster Wakeup
    # daemons
    pin_proc_on_pwr "\[rcu"
    pin_proc_on_pwr "crtc_commit"
    pin_proc_on_pwr "crtc_event"
    pin_proc_on_pwr "ueventd"
    pin_proc_on_pwr "netd"
    pin_proc_on_pwr "mdnsd"
    pin_proc_on_pwr "pdnsd"
    pin_proc_on_pwr "qcrild"
    pin_proc_on_pwr "magiskd"
    pin_proc_on_pwr "daemon"
    pin_proc_on_pwr "analytics"
    # hardware services, eg. android.hardware.sensors@1.0-service
    pin_proc_on_pwr "\.hardware\."
    # save bandwidth for UI
    pin_proc_on_pwr "system_server"
    # pwr cluster has enough capacity for surfaceflinger
    pin_proc_on_pwr "surfaceflinger"
    # MediaProvider is background service
    pin_proc_on_pwr "com.android.providers.media.module"
    pin_proc_on_pwr "android.process.media"

    # Render Pipeline
    # input dispatcher
    change_thread_high_prio "system_server" "input"
    # transition animation
    unpin_thread "system_server" "android\.anim"
    unpin_thread "system_server" "android\.ui"
    unpin_thread "system_server" "android\.display"
    pin_thread_on_perf "system_server" "android\.anim"
    pin_thread_on_perf "system_server" "android\.ui"
    pin_thread_on_perf "system_server" "android\.display"
    change_thread_rt "system_server" "android\.anim" "1"
    change_thread_rt "system_server" "android\.ui" "1"
    change_thread_rt "system_server" "android\.display" "1"
    # speed up searching service binder
    change_task_cgroup "servicemanag" "top-app" "cpuset"
    # prevent display service from being preempted by normal tasks
    change_task_rt "\.hardware\.display" "2"
    change_task_rt "\.composer" "2"
    # kworkers may block binders
    change_task_high_prio "\[rcu"
    change_task_high_prio "\[kworker\/"
    change_task_high_prio "\[ksoftirqd\/"
    # fix laggy bilibili feed scrolling
    change_task_cgroup "android\.phone" "foreground" "cpuset"
    change_thread_cgroup "android\.phone" "Binder" "top-app" "cpuset"
    # let UX related Binders run with top-app
    change_thread_cgroup "surfaceflinger" "surfaceflinger" "top-app" "cpuset"
    change_thread_cgroup "surfaceflinger" "Binder" "top-app" "cpuset"
    change_thread_cgroup "\.composer" "Binder" "top-app" "cpuset"
    change_thread_cgroup "system_server" "Binder" "top-app" "cpuset"

    # Latency Sensitive Scene Boost
    # camera service
    unpin_proc "\.hardware\.camera\.provider"
    # provide best performance for fingerprint service
    unpin_proc "\.hardware\.biometrics\.fingerprint"
    change_task_high_prio "\.hardware\.biometrics\.fingerprint"
    # mfp-daemon: goodix in-screen fingerprint daemon
    unpin_proc "mfp"
    change_task_high_prio "mfp"
    # boost app boot process, zygote--com.xxxx.xxx
    unpin_proc "zygote"
    change_task_high_prio "zygote"
}

unify_cpufreq()
{
    # no msm_performance limit
    set_cpufreq_min "0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0"
    set_cpufreq_max "0:9999000 1:9999000 2:9999000 3:9999000 4:9999000 5:9999000 6:9999000 7:9999000"

    # stop sched core_ctl, game's main thread need be pinned on prime core
    set_corectl_param "enable" "0:0 2:0 4:0 6:0 7:0"

    # unify governor
    if [ "$(is_eas)" == "true" ]; then
        set_governor_param "scaling_governor" "0:schedutil 2:schedutil 4:schedutil 6:schedutil 7:schedutil"
    else
        set_governor_param "scaling_governor" "0:interactive 2:interactive 4:interactive 6:interactive 7:interactive"
    fi

    # unify walt schedutil governor
    set_governor_param "schedutil/hispeed_freq" "0:0 2:0 4:0 6:0 7:0"
    set_governor_param "schedutil/hispeed_load" "0:100 2:100 4:100 6:100 7:100"
    set_governor_param "schedutil/pl" "0:1 2:1 4:1 6:1 7:1 0:0"

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

unify_gpufreq()
{
    # save ~100mw under light 3D workload
    lock_val "0" $KSGL/force_no_nap
    lock_val "1" $KSGL/bus_split
    lock_val "0" $KSGL/force_bus_on
    lock_val "0" $KSGL/force_clk_on
    lock_val "0" $KSGL/force_rail_on

    # unlock mtk gpu strict limit
    lock_val "1" /sys/module/ged/parameters/gpu_dvfs
    lock_val "1" /sys/module/ged/parameters/gx_game_mode
    lock_val "0" /sys/module/ged/parameters/gx_3d_benchmark_on
    lock_val "1" /proc/mali/dvfs_enable
    lock_val "0" /proc/gpufreq/gpufreq_opp_freq
}

unify_sched()
{
    # disable sched global placement boost
    lock_val "0" $SCHED/sched_boost
    lock_val "0" $SCHED/sched_walt_rotate_big_tasks
    lock_val "1000" $SCHED/sched_min_task_util_for_boost
    lock_val "1000" $SCHED/sched_min_task_util_for_colocation
    lock_val "0" $SCHED/sched_conservative_pl

    # scheduler boost for top app main from msm kernel 4.19
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
    # However in EAS model A76's efficiency is 1.7x of A55's, so the migrate thresholds need compensate.
    set_sched_migrate "99" "40" "999" "888"
    set_sched_migrate "99 99" "40 40" "999" "888"

    # prefer to use prev cpu, decrease jitter from 0.5ms to 0.3ms with lpm settings
    lock_val "10000000" $SCHED/sched_migration_cost_ns
}

unify_lpm()
{
    # C-state controller
    lock_val "1" $LPM/lpm_prediction
    lock_val "0" $LPM/sleep_disabled
    lock_val "10" $LPM/bias_hyst
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
    lock_val "0" /sys/devices/system/cpu/cpu_boost/input_boost_ms
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
    lock_val "0 0" /proc/ppm/policy_status
    lock_val "1 0" /proc/ppm/policy_status
    lock_val "2 0" /proc/ppm/policy_status
    lock_val "3 0" /proc/ppm/policy_status
    lock_val "4 0" /proc/ppm/policy_status
    lock_val "5 0" /proc/ppm/policy_status
    lock_val "6 1" /proc/ppm/policy_status # used by uperf
    lock_val "7 0" /proc/ppm/policy_status
    lock_val "8 0" /proc/ppm/policy_status
    lock_val "9 0" /proc/ppm/policy_status
    lock_val "10 0" /proc/ppm/policy_status

    # Samsung
    mutate "0" /sys/class/input_booster/level
    mutate "0" /sys/class/input_booster/head
    mutate "0" /sys/class/input_booster/tail

    # Samsung EPIC interfaces
    mutate "0" /dev/cluster0_freq_min
    mutate "0" /dev/cluster1_freq_min
    mutate "0" /dev/cluster2_freq_min
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
    stop perfd
    # Qualcomm perfhal
    perfhal_stop
    # brain service maybe not smart
    stop oneplus_brain_service
    # disable service below will BOOM
    # stop vendor.power.stats-hal-1-0
    # stop vendor.power-hal-1-0
    # stop vendor.power-hal-1-1
    # stop vendor.power-hal-1-2
    # stop vendor.power-hal-1-3
}

clear_log
disable_userspace_boost
disable_kernel_boost
disable_hotplug
unify_cpufreq
unify_gpufreq
unify_sched
unify_lpm

# make sure that all the related cpu is online
unify_cgroup

# start uperf once only
uperf_stop
uperf_start
