#!/system/bin/sh
# https://github.com/yc9559/
# Author: Matt Yang

BASEDIR="$(dirname "$0")"
. $BASEDIR/pathinfo.sh
. $BASEDIR/libcommon.sh

# clear module init log
clear_log
log "$(date '+%Y-%m-%d %H:%M:%S')"
log ""
