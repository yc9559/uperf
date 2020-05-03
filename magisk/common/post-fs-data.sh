MODDIR=${0%/*}

# do not place empty powerhint.json if it doesn't exist in system
[ ! -f /vendor/etc/powerhint.json ] && rm $MODDIR/system/vendor/etc/powerhint.json
