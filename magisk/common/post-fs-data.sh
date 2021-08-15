MODDIR=${0%/*}

if [ -f "$MODDIR/flags/.need_recuser" ]; then
    rm -f $MODDIR/flags/.need_recuser
    true > $MODDIR/disable
else
    true > $MODDIR/flags/.need_recuser
fi
