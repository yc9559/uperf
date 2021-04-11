#!/system/bin/sh
# Powercfg Library
# https://github.com/yc9559/
# Author: Matt Yang
# Version: 20210411

BASEDIR="$(dirname "$0")"
. $BASEDIR/pathinfo.sh
. $BASEDIR/libcommon.sh

###############################
# PATHs
###############################

PERFCFG_REL="./system/vendor/etc/perf"

###############################
# Abbreviations
###############################

SCHED="/proc/sys/kernel"
CPU="/sys/devices/system/cpu"
KSGL="/sys/class/kgsl/kgsl-3d0"
DEVFREQ="/sys/class/devfreq"
LPM="/sys/module/lpm_levels/parameters"
MSM_PERF="/sys/module/msm_performance/parameters"
SDA_Q="/sys/block/sda/queue"

###############################
# Powermodes helper functions
###############################

# $1:keyword $2:nr_max_matched
get_package_name_by_keyword()
{
    echo "$(pm list package | grep "$1" | head -n "$2" | cut -d: -f2)"
}

is_eas()
{
    if [ "$(grep sched $CPU/cpu0/cpufreq/scaling_available_governors)" != "" ]; then
        echo "true"
    else
        echo "false"
    fi
}

# $1:cpuid
get_maxfreq()
{
    local fpath="/sys/devices/system/cpu/cpu$1/cpufreq/scaling_available_frequencies"
    local maxfreq="0"

    if [ ! -f "$fpath" ]; then
        echo ""
        return
    fi

    for f in $(cat $fpath); do
        [ "$f" -gt "$maxfreq" ] && maxfreq="$f"
    done
    echo "$maxfreq"
}

# $1:"0:576000 4:710400 7:825600"
set_cpufreq_min()
{
    mutate "$1" $MSM_PERF/cpu_min_freq
    local key
    local val
    for kv in $1; do
        key=${kv%:*}
        val=${kv#*:}
        mutate "$val" $CPU/cpu$key/cpufreq/scaling_min_freq
    done
}

# $1:"0:576000 4:710400 7:825600"
set_cpufreq_max()
{
    mutate "$1" $MSM_PERF/cpu_max_freq
}

# $1:"0:576000 4:710400 7:825600"
set_cpufreq_dyn_max()
{
    local key
    local val
    for kv in $1; do
        key=${kv%:*}
        val=${kv#*:}
        mutate "$val" $CPU/cpu$key/cpufreq/scaling_max_freq
    done
}

# $1:"schedutil/pl" $2:"0:4 4:3 7:1"
set_governor_param()
{
    local key
    local val
    for kv in $2; do
        key=${kv%:*}
        val=${kv#*:}
        mutate "$val" $CPU/cpu$key/cpufreq/$1
        # sdm625 hmp
        mutate "$val" $CPU/cpufreq/$1
    done
}

# $1:"min_cpus" $2:"0:4 4:3 7:1"
set_corectl_param()
{
    local key
    local val
    for kv in $2; do
        key=${kv%:*}
        val=${kv#*:}
        mutate "$val" $CPU/cpu$key/core_ctl/$1
    done
}

# $1:upmigrate $2:downmigrate $3:group_upmigrate $4:group_downmigrate
set_sched_migrate()
{
    mutate "$2" $SCHED/sched_downmigrate
    mutate "$1" $SCHED/sched_upmigrate
    mutate "$2" $SCHED/sched_downmigrate
    mutate "$4" $SCHED/sched_group_downmigrate
    mutate "$3" $SCHED/sched_group_upmigrate
    mutate "$4" $SCHED/sched_group_downmigrate
}

###############################
# QTI perf framework functions
###############################

perfhal_mode="balance"

# stop before updating cfg
perfhal_stop()
{
    for i in 0 1 2 3 4; do
        for j in 0 1 2 3 4; do
            stop "perf-hal-$i-$j" 2> /dev/null
        done
    done
    usleep 500
}

# start after updating cfg
perfhal_start()
{
    for i in 0 1 2 3 4; do
        for j in 0 1 2 3 4; do
            start "perf-hal-$i-$j" 2> /dev/null
        done
    done
}

# $1:mode(such as balance)
perfhal_update()
{
    perfhal_mode="$1"
    rm /data/vendor/perfd/default_values
    cp -af "$MODULE_PATH/$PERFCFG_REL/perfd_profiles/$perfhal_mode"/* "$MODULE_PATH/$PERFCFG_REL/"
}

# return:status
perfhal_status()
{
    if [ "$(ps -A | grep "qti.hardware.perf")" != "" ]; then
        echo "Running. Current mode is $perfhal_mode."
    else
        echo "QTI boost framework not equipped with this system."
    fi
}
