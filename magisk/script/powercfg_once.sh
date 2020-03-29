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
lock_val "0" $ST_BACK/schedtune.boost
lock_val "0" $ST_BACK/schedtune.prefer_idle
lock_val "0" $ST_FORE/schedtune.boost
lock_val "0" $ST_FORE/schedtune.prefer_idle
lock_val "0" $ST_TOP/schedtune.boost
lock_val "0" $ST_TOP/schedtune.prefer_idle

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

# treat crtc_commit as background, avoid display preemption on big
change_task_cgroup "crtc_commit" "system-background" "cpuset"

# fix laggy bilibili feed scrolling
change_task_cgroup "servicemanager" "top-app" "cpuset"
change_task_cgroup "servicemanager" "foreground" "stune"
change_task_cgroup "android.phone" "top-app" "cpuset"
change_task_cgroup "android.phone" "foreground" "stune"

# treat surfaceflinger as top-app, foreground is restricted by uperf
change_task_cgroup "surfaceflinger" "top-app" "cpuset"
change_task_cgroup "surfaceflinger" "foreground" "stune"

# reduce big cluster wakeup, eg. android.hardware.sensors@1.0-service
change_task_cgroup ".hardware." "background" "cpuset"
change_task_affinity ".hardware." "0f"
# ...but exclude the fingerprint&camera service for speed
change_task_cgroup ".hardware.biometrics.fingerprint" "" "cpuset"
change_task_cgroup ".hardware.camera.provider" "" "cpuset"
change_task_affinity ".hardware.biometrics.fingerprint" "ff"
change_task_affinity ".hardware.camera.provider" "ff"

# provide best performance for fingerprint service
change_task_cgroup ".hardware.biometrics.fingerprint" "rt" "stune"
change_task_nice ".hardware.biometrics.fingerprint" "-20"
lock_val "100" $ST_RT/schedtune.boost
lock_val "1" $ST_RT/schedtune.prefer_idle

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
lock_val "0" /sys/class/input_booster/level
lock_val "0" /sys/class/input_booster/head
lock_val "0" /sys/class/input_booster/tail
# Samsung EPIC interfaces
lock_val "0" /dev/cluster0_freq_min
lock_val "0" /dev/cluster1_freq_min
lock_val "0" /dev/cluster2_freq_min
# lock_val "0" /dev/bus_throughput
# lock_val "0" /dev/gpu_freq_min
# Samsung /kernel/sched/ems/...
lock_val "0" /sys/kernel/ems/eff_mode
# 3rd
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
perfhal_stop
# disable service below will BOOM
# stop vendor.power.stats-hal-1-0
# stop vendor.power-hal-1-0
# stop vendor.power-hal-1-1
# stop vendor.power-hal-1-2
# stop vendor.power-hal-1-3

# Exynos hotplug
lock_val "0" /sys/power/cpuhotplug/enabled
lock_val "0" $CPU/cpuhotplug/enabled
# bring all cores online
for i in 0 1 2 3 4 5 6 7 8 9; do
    lock_val "1" $CPU/cpu$i/online
done
# no msm_performance limit
set_cpufreq_min "0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0"
set_cpufreq_max "0:9999000 1:9999000 2:9999000 3:9999000 4:9999000 5:9999000 6:9999000 7:9999000"
# more conservative governor
set_governor_param "schedutil/hispeed_load" "0:90 4:90 6:90 7:90"
set_governor_param "schedutil/hispeed_freq" "0:1200000 4:1200000 6:1200000 7:1200000"
# unify walt hmp interactive governor
set_governor_param "interactive/use_sched_load" "0:1 4:1 6:1 7:1"
set_governor_param "interactive/use_migration_notif" "0:1 4:1 6:1 7:1"
set_governor_param "interactive/enable_prediction" "0:0 4:0 6:0 7:0"
set_governor_param "interactive/ignore_hispeed_on_notif" "0:0 4:0 6:0 7:0"
set_governor_param "interactive/fast_ramp_down" "0:0 4:0 6:0 7:0"
# conservative sched core_ctl
set_corectl_param "enable" "0:1 2:1 4:1 6:1 7:1"
set_corectl_param "busy_down_thres" "0:10 2:10 4:10 6:10 7:10"
set_corectl_param "busy_up_thres" "0:20 2:20 4:20 6:20 7:20"
set_corectl_param "offline_delay_ms" "0:100 2:100 4:100 6:100 7:100"

# disable sched global placement boost
lock_val "0" $SCHED/sched_boost
lock_val "0" $SCHED/sched_walt_rotate_big_tasks
lock_val "1000" $SCHED/sched_min_task_util_for_boost
lock_val "1000" $SCHED/sched_min_task_util_for_colocation
# scheduler boost for top app main from msm kernel 4.19
lock_val "0" $SCHED/sched_boost_top_app
# unify WALT HMP sched
lock_val "5" $SCHED/sched_ravg_hist_size
lock_val "2" $SCHED/sched_window_stats_policy
# do not place light processes on big cluster
set_sched_migrate "95 80" "80 60" "140" "120"
# prefer to use prev cpu, decrease jitter from 0.5ms to 0.3ms with lpm settings
lock_val "30000000" $SCHED/sched_migration_cost_ns
# OnePlus opchain pins UX threads on the big cluster
lock_val "0" /sys/module/opchain/parameters/chain_on

# traditional C-state controller
lock_val "0" $LPM/lpm_prediction
lock_val "0" $LPM/sleep_disabled

# start uperf once only
uperf_start
