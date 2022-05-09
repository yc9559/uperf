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

###############################
# Powermodes helper functions
###############################

# $1:keyword $2:nr_max_matched
get_package_name_by_keyword() {
    echo "$(pm list package | grep "$1" | head -n "$2" | cut -d: -f2)"
}

# $1:"0:576000 4:710400 7:825600"
set_cpufreq_min() {
    lock_val "$1" /sys/module/msm_performance/parameters/cpu_min_freq
    local key
    local val
    for kv in $1; do
        key=${kv%:*}
        val=${kv#*:}
        lock_val "$val" /sys/devices/system/cpu/cpu$key/cpufreq/scaling_min_freq
    done
}

# $1:"0:576000 4:710400 7:825600"
set_cpufreq_max() {
    lock_val "$1" /sys/module/msm_performance/parameters/cpu_max_freq
    local key
    local val
    for kv in $1; do
        key=${kv%:*}
        val=${kv#*:}
        lock_val "$val" /sys/devices/system/cpu/cpu$key/cpufreq/scaling_max_freq
    done
}

# $1:"schedutil/pl" $2:"0:4 4:3 7:1"
set_governor_param() {
    local key
    local val
    for kv in $2; do
        key=${kv%:*}
        val=${kv#*:}
        lock_val "$val" /sys/devices/system/cpu/cpu$key/cpufreq/$1
        # sdm625 hmp
        lock_val "$val" /sys/devices/system/cpu/cpufreq/$1
    done
}

# $1:"min_cpus" $2:"0:4 4:3 7:1"
set_corectl_param() {
    local key
    local val
    for kv in $2; do
        key=${kv%:*}
        val=${kv#*:}
        lock_val "$val" /sys/devices/system/cpu/cpu$key/core_ctl/$1
    done
}

# stop before updating cfg
perfhal_stop() {
    for i in 0 1 2 3 4; do
        for j in 0 1 2 3 4; do
            stop "perf-hal-$i-$j" 2>/dev/null
        done
    done
    usleep 500
}

# start after updating cfg
perfhal_start() {
    for i in 0 1 2 3 4; do
        for j in 0 1 2 3 4; do
            start "perf-hal-$i-$j" 2>/dev/null
        done
    done
}
