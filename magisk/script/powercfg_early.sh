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

BASEDIR="$(dirname $(readlink -f "$0"))"
. $BASEDIR/libcommon.sh

# prohibit mi_thermald use cpu thermal interface
chmod 0444 /sys/devices/virtual/thermal/thermal_message/cpu_limits
chmod 0444 /sys/devices/system/cpu/cpufreq/policy*/scaling_max_freq
killall mi_thermald

# xiaomi vip-task scheduler override
chmod 0444 /dev/migt
lock_val "0" "/sys/module/migt/parameters/*"
lock_val "1" "/sys/module/migt/parameters/*disable*"

# ioctl interface used by vendor.mediatek.hardware.mtkpower@1.0-service
chmod 0000 /proc/perfmgr/eara_ioctl
chmod 0000 /proc/perfmgr/eas_ioctl
chmod 0000 /proc/perfmgr/xgff_ioctl

# why MTK system_server place surfaceflinger into this cgroup?
chmod 0444 /dev/cpuset/system-background/tasks
