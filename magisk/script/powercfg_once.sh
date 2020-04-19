#!/system/bin/sh
# Uperf https://github.com/yc9559/uperf/
# Author: Matt Yang

# Runonce after boot, to speed up the transition of power modes in powercfg

BASEDIR="$(dirname "$0")"
. $BASEDIR/libcommon.sh
. $BASEDIR/libpowercfg.sh
. $BASEDIR/libuperf.sh

# unify schedtune misc
# android 10 doesn't have schedtune.sched_boost_enabled exposed, default = true
mutate "0" $ST_BACK/schedtune.boost
mutate "0" $ST_BACK/schedtune.prefer_idle
mutate "0" $ST_FORE/schedtune.boost
mutate "0" $ST_FORE/schedtune.prefer_idle
mutate "0" $ST_TOP/schedtune.boost
mutate "0" $ST_TOP/schedtune.prefer_idle

# CFQ io scheduler takes cgroup into consideration
lock_val "cfq" $SDA_Q/scheduler
# Flash doesn't have back seek problem, so penalty is as low as possible
lock_val "1" $SDA_Q/iosched/back_seek_penalty
# slice_idle = 0 means CFQ IOP mode, https://lore.kernel.org/patchwork/patch/944972/
lock_val "0" $SDA_Q/iosched/slice_idle
# UFS 2.0+ hardware queue depth is 32
lock_val "16" $SDA_Q/iosched/quantum
# lower read_ahead_kb to reduce random access overhead
lock_val "128" $SDA_Q/read_ahead_kb

# Reserve 90% IO bandwith for foreground tasks
lock_val "1000" /dev/blkio/blkio.weight
lock_val "1000" /dev/blkio/blkio.leaf_weight
lock_val "100" /dev/blkio/background/blkio.weight
lock_val "100" /dev/blkio/background/blkio.leaf_weight

# save ~100mw under light 3D workload
lock_val "0" $KSGL/force_no_nap
lock_val "1" $KSGL/bus_split
lock_val "0" $KSGL/force_bus_on
lock_val "0" $KSGL/force_clk_on
lock_val "0" $KSGL/force_rail_on

# cleanup top-app cpuset
for p in $(cat /dev/cpuset/top-app/tasks); do
    echo "$p" > /dev/cpuset/foreground/tasks
done

# treat crtc_commit as background, avoid display preemption on big
change_task_cgroup "crtc_commit" "background" "cpuset"

# fix laggy bilibili feed scrolling
change_task_cgroup "servicemanager" "top-app" "cpuset"
change_task_cgroup "servicemanager" "foreground" "stune"
change_task_cgroup "android.phone" "top-app" "cpuset"
change_task_cgroup "android.phone" "foreground" "stune"

# treat surfaceflinger as top-app, foreground is restricted by uperf
change_task_cgroup "surfaceflinger" "top-app" "cpuset"
change_task_cgroup "surfaceflinger" "foreground" "stune"

# fix system_server in /dev/stune/top-app/cgroup.procs
change_proc_cgroup "system_server" "top-app" "cpuset"
change_proc_cgroup "system_server" "foreground" "stune"
# ...but exclude UI related
change_thread_cgroup "system_server" "android.anim" "top-app" "stune"
change_thread_cgroup "system_server" "android.anim.lf" "top-app" "stune"
change_thread_cgroup "system_server" "android.ui" "top-app" "stune"
# ...and pin HeapTaskDaemon on LITTLE
change_thread_cgroup "system_server" "HeapTaskDaemon" "background" "cpuset"

# reduce big cluster wakeup, eg. android.hardware.sensors@1.0-service
change_task_cgroup ".hardware." "background" "cpuset"
change_task_affinity ".hardware." "0f"
# ...but exclude fingerprint&camera&display service for speed
change_task_cgroup ".hardware.biometrics.fingerprint" "" "cpuset"
change_task_cgroup ".hardware.camera.provider" "" "cpuset"
change_task_cgroup ".hardware.display" "" "cpuset"
change_task_affinity ".hardware.biometrics.fingerprint" "ff"
change_task_affinity ".hardware.camera.provider" "ff"
change_task_affinity ".hardware.display" "ff"

# provide best performance for fingerprint service
change_task_cgroup ".hardware.biometrics.fingerprint" "rt" "stune"
change_task_nice ".hardware.biometrics.fingerprint" "-20"
mutate "100" $ST_RT/schedtune.boost
mutate "1" $ST_RT/schedtune.prefer_idle

# try to disable all kernel input boost
# Qualcomm
lock_val "0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0" $CPU_BOOST/input_boost_freq
lock_val "0" $CPU_BOOST/input_boost_ms
lock_val "0" $CPU_BOOST/sched_boost_on_input
lock_val "0" /sys/module/msm_performance/parameters/touchboost
lock_val "0" /sys/module/cpu_boost/parameters/boost_ms
# HTC
lock_val "0" /sys/power/pnpmgr/touch_boost
lock_val "0" /sys/power/pnpmgr/long_duration_touch_boost
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

# stop qualcomm perfd
stop perfd
# stop qualcomm perfd
perfhal_stop
# brain service maybe not smart
stop oneplus_brain_service
# disable service below will BOOM
# stop vendor.power.stats-hal-1-0
# stop vendor.power-hal-1-0
# stop vendor.power-hal-1-1
# stop vendor.power-hal-1-2
# stop vendor.power-hal-1-3

# Exynos hotplug
mutate "0" /sys/power/cpuhotplug/enabled
mutate "0" $CPU/cpuhotplug/enabled
# turn off msm_thermal
lock_val "0" /sys/module/msm_thermal/core_control/enabled
lock_val "N" /sys/module/msm_thermal/parameters/enabled
# bring all cores online
for i in 0 1 2 3 4 5 6 7 8 9; do
    mutate "1" $CPU/cpu$i/online
done

# no msm_performance limit
set_cpufreq_min "0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0"
set_cpufreq_max "0:9999000 1:9999000 2:9999000 3:9999000 4:9999000 5:9999000 6:9999000 7:9999000"
# conservative sched core_ctl
set_corectl_param "enable" "0:1 2:1 4:1 6:1 7:1"
set_corectl_param "busy_down_thres" "0:10 2:10 4:10 6:10 7:10"
set_corectl_param "busy_up_thres" "0:20 2:20 4:20 6:20 7:20"
set_corectl_param "offline_delay_ms" "0:100 2:100 4:100 6:100 7:100"

# unify governor
if [ "$(is_eas)" == "true" ]; then
    set_governor_param "scaling_governor" "0:schedutil 2:schedutil 4:schedutil 6:schedutil 7:schedutil"
else
    set_governor_param "scaling_governor" "0:interactive 2:interactive 4:interactive 6:interactive 7:interactive"
fi
# more conservative governor
set_governor_param "schedutil/hispeed_load" "0:95 2:95 4:95 6:95 7:95"
set_governor_param "schedutil/hispeed_freq" "0:1200000 2:1200000 4:1200000 6:1200000 7:1200000"
set_governor_param "schedutil/pl" "0:0 2:0 4:0 6:0 7:0"
set_governor_param "schedutil/hispeed_load" "0:90"
set_governor_param "schedutil/hispeed_freq" "0:1000000"
# unify hmp interactive governor, only 2+2 4+2 4+4
set_governor_param "interactive/use_sched_load" "0:1 2:1 4:1"
set_governor_param "interactive/use_migration_notif" "0:1 2:1 4:1"
set_governor_param "interactive/enable_prediction" "0:0 2:0 4:0"
set_governor_param "interactive/ignore_hispeed_on_notif" "0:0 2:0 4:0"
set_governor_param "interactive/fast_ramp_down" "0:0 2:0 4:0"
set_governor_param "interactive/boostpulse_duration" "0:0 2:0 4:0"
set_governor_param "interactive/boost" "0:0 2:0 4:0"
set_governor_param "interactive/timer_slack" "0:12345678 2:12345678 4:12345678"

# disable sched global placement boost
lock_val "0" $SCHED/sched_boost
lock_val "1" $SCHED/sched_walt_rotate_big_tasks
lock_val "1000" $SCHED/sched_min_task_util_for_boost
lock_val "1000" $SCHED/sched_min_task_util_for_colocation
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
set_sched_migrate "80 90" "30 60" "120" "100"
# prefer to use prev cpu, decrease jitter from 0.5ms to 0.3ms with lpm settings
lock_val "30000000" $SCHED/sched_migration_cost_ns
# OnePlus opchain pins UX threads on the big cluster
lock_val "0" /sys/module/opchain/parameters/chain_on

# C-state controller
lock_val "1" $LPM/lpm_prediction
lock_val "0" $LPM/sleep_disabled
lock_val "25" $LPM/bias_hyst

# start uperf once only
uperf_start
