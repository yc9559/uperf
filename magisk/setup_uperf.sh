#!/vendor/bin/sh
# Uperf Setup
# https://github.com/yc9559/
# Author: Matt Yang & cjybyjk (cjybyjk@gmail.com)
# Version: 20201129

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

_get_nr_core()
{
    echo "$(cat /proc/stat | grep cpu[0-9] | wc -l)"
}

_is_aarch64()
{
    if [ "$(getprop ro.product.cpu.abi)" == "arm64-v8a" ]; then
        echo "true"
    else
        echo "false"
    fi
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
    local fpath="/sys/devices/system/cpu/cpu$1/cpufreq/scaling_available_frequencies"
    local maxfreq="0"

    if [ ! -f "$fpath" ]; then
        echo ""
        return
    fi

    for f in $(cat $fpath); do
        [ "$f" -gt "$maxfreq" ] && maxfreq="$f"
    done
    echo "$maxfreq"
}

_get_socid()
{
    if [ -f /sys/devices/soc0/soc_id ]; then
        echo "$(cat /sys/devices/soc0/soc_id)"
    else
        echo "$(cat /sys/devices/system/soc/soc0/id)"
    fi
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
    local ddr_type4="07"
	local ddr_type5="08"
    local ddr_type
    ddr_type="$(od -An -tx /proc/device-tree/memory/ddr_device_type)"
    if [ ${ddr_type:4:2} == $ddr_type5 ]; then
        echo "sdm865_lp5"
    elif [ ${ddr_type:4:2} == $ddr_type4 ]; then
        echo "sdm865_lp4x"
    else
        echo "sdm865_lp5"
    fi
}

_get_sdm76x_type()
{
    if [ "$(_get_maxfreq 7)" -gt 2800000 ]; then
        echo "sdm768"
    else
        echo "sdm765"
    fi
}

_get_msm8916_type()
{
    case "$(_get_socid)" in
    "206"|"247"|"248"|"249"|"250") echo "msm8916" ;;
    "233"|"240"|"242") echo "sdm610" ;;
    "239"|"241"|"263"|"268"|"269"|"270"|"271") echo "sdm616" ;;
    *) echo "msm8916" ;;
    esac
}

_get_msm8952_type()
{
    case "$(_get_socid)" in
    "264"|"289")
        echo "msm8952"
    ;;
    *)
        if [ "$(_get_nr_core)" == "8" ]; then
            echo "sdm652"
        else
            echo "sdm650"
        fi
    ;;
    esac
}

_get_sdm636_type()
{
    if [ "$(_is_eas)" == "true" ]; then
        echo "sdm636_eas"
    else
        echo "sdm636_hmp"
    fi
}

_get_sdm660_type()
{
    local b_max
    b_max="$(_get_maxfreq 4)"
    # sdm660 & sdm636 may share the same platform name
    if [ "$b_max" -gt 2000000 ]; then
        if [ "$(_is_eas)" == "true" ]; then
            echo "sdm660_eas"
        else
            echo "sdm660_hmp"
        fi
    else
        echo "$(_get_sdm636_type)"
    fi
}

_get_sdm626_type()
{
    if [ "$(_is_eas)" == "true" ]; then
        echo "sdm626_eas"
    else
        echo "sdm626_hmp"
    fi
}

_get_sdm625_type()
{
    local b_max
    b_max="$(_get_maxfreq 4)"
    # sdm625 & sdm626 may share the same platform name
    if [ "$b_max" -lt 2100000 ]; then
        if [ "$(_is_eas)" == "true" ]; then
            echo "sdm625_eas"
        else
            echo "sdm625_hmp"
        fi
    else
        echo "$(_get_sdm626_type)"
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

    # sdm820 OC 1728/2150
    if [ "$l_max" -lt 1800000 ]; then
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

_get_e8895_type()
{
    if [ "$(_is_eas)" == "true" ]; then
        echo "e8895_eas"
    else
        echo "e8895_hmp"
    fi
}

_get_mt6873_type()
{
    local b_max
    b_max="$(_get_maxfreq 4)"
    if [ "$b_max" -gt 2500000 ]; then
        echo "mt6875"
    else
        echo "mt6873"
    fi
}

_get_mt6885_type()
{
    local b_max
    b_max="$(_get_maxfreq 4)"
    if [ "$b_max" -gt 2500000 ]; then
        echo "mt6889"
    else
        echo "mt6885"
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

# $1:board_name
_get_cfgname()
{
    local ret
    case "$1" in
    "lahaina")       ret="sdm888" ;;
    "shima")         ret="sdm775" ;;
    "kona")          ret="$(_get_sdm865_type)" ;;
    "msmnile")       ret="sdm855" ;;
    "sdm845")        ret="sdm845" ;;
    "lito")          ret="$(_get_sdm76x_type)" ;;
    "sm6150")        ret="$(_get_sm6150_type)" ;;
    "sdm710")        ret="sdm710" ;;
    "msm8916")       ret="$(_get_msm8916_type)" ;;
    "msm8939")       ret="sdm616" ;;
    "msm8952")       ret="$(_get_msm8952_type)" ;;
    "msm8953")       ret="$(_get_sdm625_type)" ;;
    "msm8953pro")    ret="$(_get_sdm626_type)" ;;
    "sdm660")        ret="$(_get_sdm660_type)" ;;
    "sdm636")        ret="$(_get_sdm636_type)" ;;
    "trinket")       ret="sdm665" ;;
    "msm8976")       ret="sdm652" ;;
    "msm8956")       ret="sdm650" ;;
    "msm8998")       ret="$(_get_sdm835_type)" ;;
    "msm8996")       ret="$(_get_sdm82x_type)" ;;
    "msm8996pro")    ret="$(_get_sdm82x_type)" ;;
    "universal9825") ret="e9820" || echo "! Uperf may have compatibility issuses on Exynos 9825 platform." ;;
    "universal9820") ret="e9820" || echo "! Uperf may have compatibility issuses on Exynos 9820 platform." ;;
    "universal9810") ret="e9810" ;;
    "universal8895") ret="$(_get_e8895_type)" ;;
    "universal8890") ret="e8890" ;;
    "universal7420") ret="e7420" ;;
    "mt6785")        ret="mt6785" ;;
    "mt6873")        ret="$(_get_mt6873_type)" ;;
    "mt6875")        ret="$(_get_mt6873_type)" ;;
    "mt6885")        ret="$(_get_mt6885_type)" ;;
    "mt6889")        ret="$(_get_mt6885_type)" ;;
    *)               ret="unsupported" ;;
    esac
    echo "$ret"
}

uperf_print_banner()
{
    echo ""
    echo "* Uperf https://github.com/yc9559/uperf/"
    echo "* Author: Matt Yang"
    echo "* Version: v2 (21.01.24)"
    echo ""
}

uperf_install()
{
    local target
    local cfgname

    target="$(getprop ro.board.platform)"
    cfgname="$(_get_cfgname $target)"
    if [ "$cfgname" == "unsupported" ]; then
        target="$(getprop ro.product.board)"
        cfgname="$(_get_cfgname $target)"
    fi

    if [ "$cfgname" != "unsupported" ]; then
        echo "- The platform name is $target. Use $cfgname.json"
        _setup_platform_file "$cfgname"
    else
        _abort "! [$target] not supported."
    fi

    if [ "$(_is_aarch64)" == "true" ]; then
        cp "$BASEDIR/uperf/arm64-v8a/uperf" "$BASEDIR/bin"
    else
        cp "$BASEDIR/uperf/armeabi-v7a/uperf" "$BASEDIR/bin"
    fi

    _set_perm_recursive $BASEDIR 0 0 0755 0644
    _set_perm_recursive $BASEDIR/bin 0 0 0755 0755
    # in case of set_perm_recursive is broken
    chmod 0755 $BASEDIR/bin/*

    echo "- Uperf installation was successful."
}

sfa_install()
{
    local sfanalysis_path
    local target_lib_path
    if [ "$(_is_aarch64)" == "true" ]; then
        sfanalysis_path="$BASEDIR/sfanalysis/arm64-v8a"
        target_lib_path="$BASEDIR/system/lib64"
    else
        sfanalysis_path="$BASEDIR/sfanalysis/armeabi-v7a"
        target_lib_path="$BASEDIR/system/lib"
    fi

    mkdir -p "$target_lib_path"
    cp "$sfanalysis_path/injector" "$BASEDIR/bin/"
    cp "$sfanalysis_path/libsfanalysis.so" "$target_lib_path"

    _set_perm "$BASEDIR/bin/injector" 0 0 0755 u:object_r:system_file:s0
    _set_perm "$target_lib_path/libsfanalysis.so" 0 0 0644 u:object_r:system_lib_file:s0
    # in case of set_perm_recursive is broken
    chmod 0755 $BASEDIR/bin/*

    # create sfanalysis enable flag
    touch $BASEDIR/enable_sfanalysis
}

powerhal_stub_install()
{
    _set_perm "$BASEDIR/system/vendor/etc/powerhint.json" 0 0 0755 u:object_r:vendor_configs_file:s0
}

uperf_print_banner
uperf_install
sfa_install
powerhal_stub_install
exit 0
