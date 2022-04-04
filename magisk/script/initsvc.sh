#!/vendor/bin/sh
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
. $BASEDIR/pathinfo.sh
. $BASEDIR/libcommon.sh

# create busybox symlinks
$BIN_PATH/busybox/busybox --install -s $BIN_PATH/busybox

# support vtools
cp -af $SCRIPT_PATH/vtools_powercfg.sh /data/powercfg.sh
cp -af $SCRIPT_PATH/vtools_powercfg.sh /data/powercfg-base.sh
chmod 755 /data/powercfg.sh
chmod 755 /data/powercfg-base.sh
echo "sh $SCRIPT_PATH/powercfg_main.sh \"\$1\"" >>/data/powercfg.sh

wait_until_login

sh $SCRIPT_PATH/powercfg_once.sh

# raise inotify limit in case file sync existed
lock_val "1048576" /proc/sys/fs/inotify/max_queued_events
lock_val "1048576" /proc/sys/fs/inotify/max_user_watches
lock_val "1024" /proc/sys/fs/inotify/max_user_instances

mv $USER_PATH/uperf.log $USER_PATH/uperf.log.bak
$BIN_PATH/uperf $USER_PATH/uperf.json -o $USER_PATH/uperf.log
