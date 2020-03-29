# Uperf


## Requirements

1. Android >= 8.0
2. Rooted
3. Magisk >= 17.0

## Installation

1. Download zip in [Release Page](https://github.com/yc9559/uperf/releases)
2. Flash in Magisk manager
3. Reboot
4. Check whether `/sdcard/Android/panel_uperf.txt` exists

## Switch modes

### Switching on boot

1. Open `/sdcard/Android/panel_uperf.txt`
2. Edit line `default_mode=balance`, where `balance` is the default mode applied at boot
3. Reboot

### Switching after boot

Option 1:  
Exec `sh /data/powercfg.sh balance`, where `balance` is the mode you want to switch.  

Option 2:  
Install [vtools](https://www.coolapk.com/apk/com.omarea.vtools) and bind APPs to power mode.  

## Credit

```plain
```
