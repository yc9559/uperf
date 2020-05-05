MODDIR=${0%/*}

# do not place empty powerhint.json if it doesn't exist in system
if [ -f /vendor/etc/powerhint.json ]; then
    cp $MODDIR/system/vendor/etc/powerhint.json.override $MODDIR/system/vendor/etc/powerhint.json
fi
