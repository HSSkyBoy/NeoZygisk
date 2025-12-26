#!/system/bin/sh

check_reset_prop() {
    [ "$(resetprop "$1")" != "$2" ] && resetprop -n "$1" "$2"
}

contains_reset_prop() {
    case "$(resetprop "$1")" in
        *"$2"*) resetprop -n "$1" "$3" ;;
    esac
}

empty_reset_prop() {
    [ -z "$(resetprop "$1")" ] && resetprop -n "$1" "$2"
}

resetprop -w sys.boot_completed 0

check_reset_prop "ro.boot.vbmeta.device_state" "locked"
check_reset_prop "ro.boot.verifiedbootstate" "green"
check_reset_prop "ro.boot.flash.locked" "1"
check_reset_prop "ro.boot.veritymode" "enforcing"
check_reset_prop "ro.boot.warranty_bit" "0"
check_reset_prop "ro.warranty_bit" "0"
check_reset_prop "ro.debuggable" "0"
check_reset_prop "ro.force.debuggable" "0"
check_reset_prop "ro.secure" "1"
check_reset_prop "ro.adb.secure" "1"
check_reset_prop "ro.build.type" "user"
check_reset_prop "ro.build.tags" "release-keys"
check_reset_prop "ro.vendor.boot.warranty_bit" "0"
check_reset_prop "ro.vendor.warranty_bit" "0"
check_reset_prop "vendor.boot.vbmeta.device_state" "locked"
check_reset_prop "vendor.boot.verifiedbootstate" "green"
check_reset_prop "sys.oem_unlock_allowed" "0"

# MIUI specific
check_reset_prop "ro.secureboot.lockstate" "locked"

# Realme specific
check_reset_prop "ro.boot.realmebootstate" "green"
check_reset_prop "ro.boot.realme.lockstate" "1"

# OPlus specific
check_reset_prop "ro.is_ever_orange" "0"
check_reset_prop "ro.boot.is_ever_orange" "0"
check_reset_prop "ro.boot.hw.is_ever_orange" "0"

# Hide that we booted from recovery when magisk is in recovery mode
contains_reset_prop "ro.bootmode" "recovery" "unknown"
contains_reset_prop "ro.boot.bootmode" "recovery" "unknown"
contains_reset_prop "vendor.boot.bootmode" "recovery" "unknown"

# Reset vbmeta related prop
if [ -f "/data/adb/boot_hash" ]; then
    hash_value=$(grep -v '^#' "/data/adb/boot_hash" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    [ -z "$hash_value" ] && rm -f /data/adb/boot_hash || resetprop -n ro.boot.vbmeta.digest "$hash_value"
fi

empty_reset_prop "ro.boot.vbmeta.device_state" "locked"
empty_reset_prop "ro.boot.vbmeta.invalidate_on_error" "yes"
empty_reset_prop "ro.boot.vbmeta.avb_version" "1.2"
empty_reset_prop "ro.boot.vbmeta.hash_alg" "sha256"
empty_reset_prop "ro.boot.vbmeta.size" "4096"
