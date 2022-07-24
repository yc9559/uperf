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
    echo "$(cat "/sys/devices/system/cpu/cpu$1/cpufreq/cpuinfo_max_freq")"
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

_get_lahaina_type() {
    if [ "$(get_maxfreq 7)" -gt 2600000 ]; then
        echo "sdm888"
    else
        if [ "$(get_maxfreq 4)" -gt 2300000 ]; then
            echo "sdm778"
        else
            echo "sdm780"
        fi
    fi
}

_get_taro_type() {
    if [ "$(get_maxfreq 4)" -gt 2700000 ]; then
        echo "sdm8g1+"
    else
        echo "sdm8g1"
    fi
}

# $1:board_name
get_config_name() {
    case "$1" in
    "taro") echo "$(_get_taro_type)" ;;
    "lahaina") echo "$(_get_lahaina_type)" ;;
    "shima") echo "$(_get_lahaina_type)" ;;
    "yupik") echo "$(_get_lahaina_type)" ;;
    "kona") echo "sdm865" ;;    # 865, 870
    "msmnile") echo "sdm855" ;; # 855, 860
    "sdm845") echo "sdm845" ;;
    "lito") echo "$(_get_sdm76x_type)" ;;
    "sm6150") echo "$(_get_sm6150_type)" ;;
    "sdm710") echo "sdm710" ;;
    "msm8916") echo "$(_get_msm8916_type)" ;;
    "msm8939") echo "sdm616" ;;
    "msm8953") echo "sdm625" ;;    # 625
    "msm8953pro") echo "sdm625" ;; # 626
    "sdm660") echo "sdm660" ;;
    "sdm636") echo "sdm660" ;;
    "trinket") echo "sdm665" ;; # sdm665
    "bengal") echo "sdm665" ;;  # sdm662
    "msm8976") echo "sdm652" ;;
    "msm8956") echo "sdm650" ;;
    "msm8998") echo "sdm835" ;;
    "msm8996") echo "sdm820" ;;
    "msm8996pro") echo "sdm820" ;;
    "s5e9925") echo "e2200" ;;
    "exynos2100") echo "e2100" ;;
    "exynos1080") echo "e1080" ;;
    "exynos990") echo "e990" ;;
    "universal9925") echo "e2200" ;;
    "universal2100") echo "e2100" ;;
    "universal1080") echo "e1080" ;;
    "universal990") echo "e990" ;;
    "universal9825") echo "e9820" ;;
    "universal9820") echo "e9820" ;;
    "universal9810") echo "e9810" ;;
    "universal8895") echo "e8895" ;;
    "universal8890") echo "e8890" ;;
    "universal7420") echo "e7420" ;;
    "mt6765") echo "mtp35" ;; # Helio P35(mt6765)/G35(mt6765g)/G37(mt6765h)
    "mt6768") echo "mtg80" ;; # Helio P65(mt6768)/G70(mt6769v)/G80(mt6769t)/G85(mt6769z)
    "mt6785") echo "mtg90t" ;;
    "mt6833") echo "mtd720" ;;
    "mt6833p") echo "mtd720" ;; # Dimensity 810
    "mt6833v") echo "mtd720" ;; # Dimensity 810
    "mt6853") echo "mtd720" ;;
    "mt6873") echo "mtd820" ;;
    "mt6875") echo "mtd820" ;;
    "mt6877") echo "mtd920" ;;
    "mt6885") echo "mtd1000" ;;
    "mt6889") echo "mtd1000" ;;
    "mt6891") echo "mtd1100" ;;
    "mt6893") echo "mtd1200" ;;
    "mt6895") echo "mtd8100" ;;
    "mt6983") echo "mtd9000" ;;
    "gs101") echo "gs101" ;;
    *) echo "unsupported" ;;
    esac
}
