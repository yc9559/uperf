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

###############################
# Platform info functions
###############################

# $1:"4.14" return:string_in_version
match_linux_version() {
    echo "$(cat /proc/version | grep -i "$1")"
}

get_socid() {
    if [ -f /sys/devices/soc0/soc_id ]; then
        echo "$(cat /sys/devices/soc0/soc_id)"
    else
        echo "$(cat /sys/devices/system/soc/soc0/id)"
    fi
}

get_nr_core() {
    echo "$(cat /proc/stat | grep cpu[0-9] | wc -l)"
}

# $1:cpuid
get_maxfreq() {
    local fpath="/sys/devices/system/cpu/cpu$1/cpufreq/cpuinfo_max_freq"
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

is_aarch64() {
    if [ "$(getprop ro.product.cpu.abi)" == "arm64-v8a" ]; then
        echo "true"
    else
        echo "false"
    fi
}

is_eas() {
    if [ "$(grep sched /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors)" != "" ]; then
        echo "true"
    else
        echo "false"
    fi
}

is_mtk() {
    if [ "$(getprop | grep ro.mtk)" != "" ]; then
        echo "true"
    else
        echo "false"
    fi
}

_get_sm6150_type() {
    case "$(get_socid)" in
    365 | 366) echo "sdm730" ;;
    355 | 369) echo "sdm675" ;;
    esac
}

_get_sdm76x_type() {
    if [ "$(get_maxfreq 7)" -gt 2300000 ]; then
        echo "sdm765"
    else
        echo "sdm750"
    fi
}

_get_msm8916_type() {
    case "$(get_socid)" in
    "206" | "247" | "248" | "249" | "250") echo "msm8916" ;;
    "233" | "240" | "242") echo "sdm610" ;;
    "239" | "241" | "263" | "268" | "269" | "270" | "271") echo "sdm616" ;;
    *) echo "msm8916" ;;
    esac
}

_get_msm8952_type() {
    case "$(get_socid)" in
    "264" | "289")
        echo "msm8952"
        ;;
    *)
        if [ "$(get_nr_core)" == "8" ]; then
            echo "sdm652"
        else
            echo "sdm650"
        fi
        ;;
    esac
}
_get_mt6833_type() {
    local b_max
    b_max="$(_get_maxfreq 7)"
    if [ "$b_max" -ge 2300000 ]; then
        echo "mtd810"
    else
        echo "mtd700"
    fi
}
_get_mt6853_type() {
    local b_max
    b_max="$(get_maxfreq 6)"
    if [ "$b_max" -gt 2200000 ]; then
        echo "mtd800u"
    else
        echo "mtd720"
    fi
}

_get_mt6873_type() {
    local b_max
    b_max="$(get_maxfreq 4)"
    if [ "$b_max" -gt 2500000 ]; then
        echo "mtd820"
    else
        echo "mtd800"
    fi
}
_get_mt6885_type() {
    local b_max
    b_max="$(get_maxfreq 4)"
    if [ "$b_max" -gt 2500000 ]; then
        echo "mtd1000"
    else
        echo "mtd1000l"
    fi
}
_get_mt6893_type() {
    local b_max
    b_max="$(get_maxfreq 7)"
    if [ "$b_max" -gt 2700000 ]; then
        echo "mtd1200"
    else
        echo "mtd1100"
    fi
}
_get_mt6895_type() {
    local b_max
    b_max="$(get_maxfreq 7)"
    if [ "$b_max" -gt 2800000 ]; then
        echo "mtd8100"
    else
        echo "mtd8000"
    fi
}

_get_lahaina_type() {
    local b_max
    b_max="$(get_maxfreq 7)"
    if [ "$b_max" -gt 2600000 ]; then
        echo "sdm888"
    else
        echo "sdm780"
    fi
}

# $1:board_name
get_config_name() {
    case "$1" in
    "taro") echo "sdm8g1" ;;
    "lahaina") echo "$(_get_lahaina_type)" ;;
    "shima") echo "sdm775" ;;
    "kona") echo "sdm865" ;;    # 865, 870
    "msmnile") echo "sdm855" ;; # 855, 860
    "sdm845") echo "sdm845" ;;
    "lito") echo "$(_get_sdm76x_type)" ;;
    "sm6150") echo "$(_get_sm6150_type)" ;;
    "sdm710") echo "sdm710" ;;
    "msm8916") echo "$(_get_msm8916_type)" ;;
    "msm8939") echo "sdm616" ;;
    "msm8952") echo "$(_get_msm8952_type)" ;;
    "msm8953") echo "sdm625" ;;    # 625, 626
    "msm8953pro") echo "sdm625" ;; # 625, 626
    "sdm660") echo "sdm660" ;;     # 660, 636
    "sdm636") echo "sdm660" ;;     # 660, 636
    "trinket") echo "sdm665" ;;
    "bengal") echo "sdm665" ;; # sdm662
    "msm8976") echo "sdm652" ;;
    "msm8956") echo "sdm650" ;;
    "msm8998") echo "sdm835" ;;
    "msm8996") echo "sdm820" ;;
    "msm8996pro") echo "sdm820" ;;
    "exynos2100") echo "e2100" ;;
    "exynos1080") echo "e1080" ;;
    "exynos990") echo "e990" ;;
    "universal2100") echo "e2100" ;;
    "universal1080") echo "e1080" ;;
    "universal990") echo "e990" ;;
    "universal9825") echo "e9820" ;;
    "universal9820") echo "e9820" ;;
    "universal9810") echo "e9810" ;;
    "universal8895") echo "e8895" ;;
    "universal8890") echo "e8890" ;;
    "universal7420") echo "e7420" ;;
    "mt6768") echo "mtg80" ;; # Helio P65(mt6768)/G70(mt6769v)/G80(mt6769t)/G85(mt6769z)
    "mt6785") echo "mtg90t" ;;
    "mt6833p") echo "$(_get_mt6833_type)" ;; # D810
    "mt6833v") echo "$(_get_mt6833_type)" ;; # D810
    "mt6833") echo "$(_get_mt6833_type)" ;;  # D810
    "mt6853") echo "$(_get_mt6853_type)" ;;
    "mt6873") echo "$(_get_mt6873_type)" ;;
    "mt6875") echo "$(_get_mt6873_type)" ;;
    "mt6885") echo "$(_get_mt6885_type)" ;;
    "mt6889") echo "$(_get_mt6885_type)" ;;
    "mt6891") echo "mtd1100" ;;             # D1100
    "mt6893") echo "$(_get_mt6893_type)" ;; # D1100 & D1200 & D1300
    "mt6877") echo "$(_get_mt6877_type)" ;; # D900 & D920
    "mt6833") echo "$(_get_mt6833_type)" ;; # D810 & D700
    "mt6895") echo "$(_get_mt6895_type)" ;; # D8000 & D8100
    "mt6983") echo "mtd9000" ;;             # D9000
    *) echo "unsupported" ;;
    esac
}
