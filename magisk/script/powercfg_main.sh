#!/system/bin/sh
# Uperf https://github.com/yc9559/uperf/
# Author: Matt Yang

BASEDIR="$(dirname "$0")"
. $BASEDIR/libcommon.sh
. $BASEDIR/libuperf.sh

# $1: power_mode
apply_power_mode()
{
    uperf_set_powermode "$1"
    echo "Applying $1 done."
}

# $1: power_mode
verify_power_mode()
{
    # fast -> performance
    case "$1" in
        "powersave"|"balance"|"performance") echo "$1" ;;
        "fast") echo "performance" ;;
        *) echo "balance" ;;
    esac
}

save_panel()
{
    clear_panel
    write_panel ""
    write_panel "Uperf https://github.com/yc9559/uperf/"
    write_panel "Author: Matt Yang"
    write_panel "Version: DEV 20200405"
    write_panel "Last performed: $(date '+%Y-%m-%d %H:%M:%S')"
    write_panel ""
    write_panel "[Uperf status]"
    write_panel "$(uperf_status)"
    write_panel ""
    write_panel "[Settings]"
    write_panel "# The default mode applied at boot"
    write_panel "# Available mode: balance powersave performance"
    write_panel "default_mode=$default_mode"
}

# 1. target from exec parameter
action="$1"
if [ "$action" != "" ]; then
    action="$(verify_power_mode "$action")"
    apply_power_mode "$action"
    exit 0
fi

# 2. target from panel
default_mode="$(read_cfg_value default_mode)"
default_mode="$(verify_power_mode "$default_mode")"
apply_power_mode "$default_mode"

# save mode for automatic applying mode after reboot
save_panel

exit 0
