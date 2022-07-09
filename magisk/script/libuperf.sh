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

BASEDIR="$(dirname "$0")"
. $BASEDIR/pathinfo.sh
. $BASEDIR/libcommon.sh
. $BASEDIR/libcgroup.sh

uperf_stop() {
    killall uperf
}

uperf_start() {
    # raise inotify limit in case file sync existed
    lock_val "1048576" /proc/sys/fs/inotify/max_queued_events
    lock_val "1048576" /proc/sys/fs/inotify/max_user_watches
    lock_val "1024" /proc/sys/fs/inotify/max_user_instances

    mv $USER_PATH/uperf_log.txt $USER_PATH/uperf_log.txt.bak
    if [ -f $BIN_PATH/libc++_shared.so ]; then
        ASAN_LIB="$(ls $BIN_PATH/libclang_rt.asan-*-android.so)"
        export LD_PRELOAD="$ASAN_LIB $BIN_PATH/libc++_shared.so"
    fi
    $BIN_PATH/uperf $USER_PATH/uperf.json -o $USER_PATH/uperf_log.txt

    # waiting for uperf initialization
    sleep 2
    # uperf shouldn't preempt foreground tasks
    rebuild_process_scan_cache
    change_task_cgroup "uperf" "background" "cpuset"
}
