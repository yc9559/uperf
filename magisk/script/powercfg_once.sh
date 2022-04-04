#!/system/bin/sh
#
# Copyright (C) 2021-2022 Matt Yang
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Runonce after boot, to speed up the transition of power modes in powercfg

BASEDIR="$(dirname $(readlink -f "$0"))"
. $BASEDIR/pathinfo.sh
. $BASEDIR/libcommon.sh
. $BASEDIR/libpowercfg.sh
. $BASEDIR/libcgroup.sh

unify_cgroup() {
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
            echo $p >/dev/$cg/foreground/tasks
        done
    done

    # unused
    rmdir /dev/cpuset/foreground/boost

    # work with uperf/ContextScheduler
    change_task_cgroup "system_server" "" "cpuset"
    change_task_cgroup "surfaceflinger" "" "cpuset"
    change_task_cgroup "composer|allocator" "foreground" "cpuset"
    change_task_cgroup "android.hardware.media|android.hardware.audio|audioserver" "top-app" "cpuset"
    change_task_cgroup "kswapd0|kcompactd0|ion-pool-" "foreground" "cpuset"
    # MTK kernel threads seems always wakeup on cpu7
    change_task_cgroup "aal_sof|kfps|dsp_send_thread|vdec_ipi_recv|mtk_drm_disp_id|hif_thread" "background" "cpuset"
}

unify_cpufreq() {
    # no msm_performance limit
    set_cpufreq_min "0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0"
    set_cpufreq_max "0:9999000 1:9999000 2:9999000 3:9999000 4:9999000 5:9999000 6:9999000 7:9999000"

    # stop sched core_ctl, omit cpu7
    set_corectl_param "enable" "0:0 2:0 4:0 6:0"

    # clear cpu load scale factor
    for i in 0 1 2 3 4 5 6 7 8 9; do
        lock_val "0" /sys/devices/system/cpu/cpu$i/sched_load_boost
    done
}

unify_sched() {
    # disable sched global placement boost
    for d in kernel walt; do
        lock_val "0" /proc/sys/$d/sched_boost
        lock_val "0" /proc/sys/$d/sched_force_lb_enable
        lock_val "0" /proc/sys/$d/sched_walt_rotate_big_tasks
        lock_val "0" /proc/sys/$d/sched_stask_to_big
    done

    # 90/60
    set_sched_migrate "90" "60" "90" "60"
    set_sched_migrate "90 90" "60 60" "90" "60"

    # CFS
    lock_val "1500000" /proc/sys/kernel/sched_migration_cost_ns
    lock_val "1000000" /proc/sys/kernel/sched_wakeup_granularity_ns
    lock_val "2000000" /proc/sys/kernel/sched_min_granularity_ns
}

disable_hotplug() {
    # Exynos hotplug
    mutate "0" /sys/power/cpuhotplug/enabled
    mutate "0" /sys/devices/system/cpu/cpuhotplug/enabled

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
        lock_val "1" /sys/devices/system/cpu/cpu$i/online
    done
}

disable_kernel_boost() {
    # Qualcomm
    lock_val "0" "/sys/devices/system/cpu/cpu_boost/*"
    lock_val "0" "/sys/devices/system/cpu/cpu_boost/parameters/*"
    lock_val "0" "/sys/module/cpu_boost/parameters/*"
    lock_val "0" "/sys/module/msm_performance/parameters/*"
    lock_val "0" "/proc/sys/walt/input_boost/*"

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
    lock_val "0" /proc/ppm/enabled
    # used by uperf
    # mutate "6 1" /proc/ppm/policy_status

    # Samsung
    mutate "0" "/sys/class/input_booster/*"

    # Samsung EPIC interfaces, used by uperf
    # mutate "0" /dev/cluster0_freq_min
    # mutate "0" /dev/cluster1_freq_min
    # mutate "0" /dev/cluster2_freq_min
    # lock_val "0" /dev/bus_throughput
    # lock_val "0" /dev/gpu_freq_min
    # Samsung /kernel/sched/ems/...
    mutate "0" /sys/kernel/ems/eff_mode

    # Oneplus
    lock_val "N" "/sys/module/control_center/parameters/*"
    lock_val "0" /sys/module/aigov/parameters/enable
    lock_val "0" "/sys/module/houston/parameters/*"
    # OnePlus opchain always pins UX threads on the big cluster
    lock_val "0" /sys/module/opchain/parameters/chain_on

    # 3rd
    lock_val "0" "/sys/kernel/cpu_input_boost/*"
    lock_val "0" "/sys/module/cpu_input_boost/parameters/*"
    lock_val "0" "/sys/module/dsboost/parameters/*"
    lock_val "0" "/sys/module/devfreq_boost/parameters/*"
}

disable_userspace_boost() {
    # xiaomi perfservice
    stop vendor.perfservice
    stop miuibooster
    # stop vendor.miperf

    # brain service maybe not smart
    stop oneplus_brain_service 2>/dev/null

    # Qualcomm perfd
    stop perfd 2>/dev/null

    # Qualcomm&MTK perfhal
    # keep perfhal running with empty config file in magisk mode
    [ ! -f "$FLAG_PATH/enable_perfhal_stub" ] && perfhal_stop

    # MTK
    # stop fpsgo
    # yes, it will automatically respawn, don't let it die
    killall vendor.mediatek.hardware.mtkpower@1.0-service
}

disable_aggressive_thermal() {
    # prohibit mi_thermald use cpu thermal interface
    # yes, kill twice
    chmod 0444 /sys/devices/virtual/thermal/thermal_message/cpu_limits
    chmod 0444 /sys/devices/system/cpu/cpufreq/policy*/scaling_max_freq
    killall mi_thermald
}

clear_log
log "PATH=$PATH"
log "sh=$(which sh)"

disable_userspace_boost
disable_kernel_boost
disable_hotplug
unify_cpufreq
unify_sched
disable_aggressive_thermal

# make sure that all the related cpu is online
rebuild_process_scan_cache
unify_cgroup
