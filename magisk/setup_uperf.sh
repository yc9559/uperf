#!/vendor/bin/sh
# Uperf Setup
# https://github.com/yc9559/
# Author: Matt Yang
# Version: 20200329

BASEDIR="$(dirname $(readlink -f "$0"))"

# $1:error_message
_abort()
{
    echo "$1"
    echo "! Uperf installation failed."
    exit 1
}

# $1:file_node $2:owner $3:group $4:permission $5:secontext
_set_perm()
{
    local con
    chown $2:$3 $1
    chmod $4 $1
    con=$5
    [ -z $con ] && con=u:object_r:system_file:s0
    chcon $con $1
}

# $1:directory $2:owner $3:group $4:dir_permission $5:file_permission $6:secontext
_set_perm_recursive() {
    find $1 -type d 2>/dev/null | while read dir; do
        _set_perm $dir $2 $3 $4 $6
    done
    find $1 -type f -o -type l 2>/dev/null | while read file; do
        _set_perm $file $2 $3 $5 $6
    done
}

_is_eas()
{
    if [ "$(grep sched /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors)" != "" ]; then
        echo "true"
    else
        echo "false"
    fi
}

# $1:cpuid
_get_maxfreq()
{
    local avail_freqs
    local maxfreq
    avail_freqs="$(cat /sys/devices/system/cpu/cpu$1/cpufreq/scaling_available_frequencies)"
    for f in avail_freqs; do
        [ "$f" -gt "$maxfreq" ] && maxfreq="$f"
    done
    echo "$maxfreq"
}

_get_sm6150_type()
{
    [ -f /sys/devices/soc0/soc_id ] && SOC_ID="$(cat /sys/devices/soc0/soc_id)"
    [ -f /sys/devices/system/soc/soc0/id ] && SOC_ID="$(cat /sys/devices/system/soc/soc0/id)"
    case "$SOC_ID" in
    365 | 366) echo "sdm730" ;;
    355 | 369) echo "sdm675" ;;
    esac
}

_get_sdm865_type()
{
    local ddr_device_type
    ddr_device_type="$(od -An -tx /proc/device-tree/memory/ddr_device_type)"
    ddr_device_type="${ddr_device_type:4:2}"
    [ "$ddr_device_type" == "07" ] && echo "sdm865_lp4x"
    [ "$ddr_device_type" == "08" ] && echo "sdm865_lp5"
}

_get_sdm660_type()
{
    if [ "$(_is_eas)" == "true" ]; then
        echo "sdm660_eas"
    else
        echo "sdm660_hmp"
    fi
}

_get_sdm835_type()
{
    if [ "$(_is_eas)" == "true" ]; then
        echo "sdm835_eas"
    else
        echo "sdm835_hmp"
    fi
}

_get_sdm82x_type()
{
    if [ "$(_is_eas)" == "true" ]; then
        echo "sdm82x_eas"
        return
    fi
    
    local l_max
    local b_max
    l_max="$(_get_maxfreq 0)"
    b_max="$(_get_maxfreq 2)"

    if [ "$l_max" -lt 1600000 ]; then
        if [ "$b_max" -gt 2100000 ]; then
            # 1593/2150
            echo "sdm820_hmp"
        elif [ "$b_max" -gt 1900000 ]; then
            # 1593/1996
            echo "sdm821_v1_hmp"
        else
            # 1363/1824
            echo "sdm820_hmp"
        fi
    else
        if [ "$b_max" -gt 2300000 ]; then
            # 2188/2342
            echo "sdm821_v3_hmp"
        else
            # 1996/2150
            echo "sdm821_v2_hmp"
        fi
    fi
}

# $1:cfg_name
_setup_platform_file()
{
    if [ -f $BASEDIR/config/$1.json ]; then
        mv $BASEDIR/config/cfg_uperf.json $BASEDIR/config/cfg_uperf.json.bak 2> /dev/null
        cp $BASEDIR/config/$1.json $BASEDIR/config/cfg_uperf.json 2> /dev/null
    else
        _abort "! Config file \"$1.json\" not found."
    fi
}

uperf_print_banner()
{
    echo ""
    echo "* Uperf https://github.com/yc9559/uperf/"
    echo "* Author: Matt Yang"
    echo "* Version: v1 preview(20200329)"
    echo ""
}

uperf_install()
{
    local target
    local cfgname

    target="$(getprop ro.board.platform)"
    [ "$target" == "" ] && target="unknown"

    case "$target" in
    "kona")         cfgname="$(_get_sdm865_type)" ;;
    "msmnile")      cfgname="sdm855" ;;
    "sdm845")       cfgname="sdm845" ;;
    "lito")         cfgname="sdm765" ;;
    "sm6150")       cfgname="$(_get_sm6150_type)" ;;
    "sdm710")       cfgname="sdm710" ;;
    "msm8953")      cfgname="sdm625";;
    "msm8953pro")   cfgname="sdm626";;
    "sdm660")       cfgname="$(_get_sdm660_type)";;
    "sdm636")       cfgname="sdm636";;
    "msm8976")      cfgname="sdm652";;
    "msm8956")      cfgname="sdm650";;
    "msm8998")      cfgname="$(_get_sdm835_type)";;
    "msm8996"|"msm8996pro") cfgname="$(_get_sdm82x_type)";;
    "universal9820"|"universal9825") cfgname="e9820" ;;
    "universal9810") cfgname="e9810" ;;
    "universal8895") cfgname="e8895" ;;
    "universal8890") cfgname="e8890" ;;
    "universal7420") cfgname="e7420" ;;
    *)  cfgname="unsupported" ;;
    esac

    if [ "$cfgname" != "unsupported" ]; then
        echo "- The platform name is $target. Use $cfgname.json"
        _setup_platform_file "$cfgname"
        _set_perm_recursive $BASEDIR 0 0 0755 0644
        _set_perm_recursive $BASEDIR/bin 0 0 0755 0755
        # in case of set_perm_recursive is broken
        chmod 0755 $BASEDIR/bin/*
    else
        _abort "! [$target] not supported."
    fi

    echo "- Uperf installation was successful."
}

uperf_print_banner
uperf_install
