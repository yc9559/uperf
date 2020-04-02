#!/vendor/bin/sh
# Uperf Runner
# https://github.com/yc9559/
# Author: Matt Yang
# Version: 20200401

BASEDIR="$(dirname $(readlink -f "$0"))"
SCRIPT_DIR="$BASEDIR/script"

wait_until_login()
{
    # we doesn't have the permission to rw "/sdcard" before the user unlocks the screen
    while [ ! -d "/sdcard/Android" ]; do
        sleep 2
    done
}

if [ "$(cat $SCRIPT_DIR/pathinfo.sh | grep "$PATH")" == "" ]; then
    echo "" >> $SCRIPT_DIR/pathinfo.sh
    echo "# prefer to use busybox provided by magisk" >> $SCRIPT_DIR/pathinfo.sh
    echo "PATH=$PATH" >> $SCRIPT_DIR/pathinfo.sh
fi

# support vtools
cp -af $SCRIPT_DIR/vtools-powercfg.sh /data/powercfg.sh
cp -af $SCRIPT_DIR/vtools-powercfg.sh /data/powercfg-base.sh
chmod 755 /data/powercfg.sh
chmod 755 /data/powercfg-base.sh

# powercfg path provided by magisk module
echo "sh $SCRIPT_DIR/powercfg_main.sh \"\$1\"" >> /data/powercfg.sh

# not relying on executable permissions
wait_until_login
sleep 10
sh $SCRIPT_DIR/powercfg_once.sh
sh $SCRIPT_DIR/powercfg_main.sh
