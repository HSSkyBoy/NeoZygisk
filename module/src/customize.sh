# shellcheck disable=SC2034
SKIPUNZIP=1

DEBUG=@DEBUG@
MIN_APATCH_VERSION=@MIN_APATCH_VERSION@
MIN_KSU_VERSION=@MIN_KSU_VERSION@
MIN_KSUD_VERSION=@MIN_KSUD_VERSION@
MAX_KSU_VERSION=@MAX_KSU_VERSION@
MIN_MAGISK_VERSION=@MIN_MAGISK_VERSION@

if [ "$BOOTMODE" ] && [ "$APATCH" ]; then
  ui_print "- Installing from APatch app"
  if ! [ "$APATCH_VER_CODE" ] || [ "$APATCH_VER_CODE" -lt "$MIN_APATCH_VERSION" ]; then
    ui_print "*********************************************************"
    ui_print "! APatch version is too old!"
    ui_print "! Please update APatch to latest version"
    abort    "*********************************************************"
  fi
  if [ "$(which magisk)" ]; then
    ui_print "*********************************************************"
    ui_print "! Multiple root implementation is NOT supported!"
    ui_print "! Please uninstall Magisk before installing NeoZygisk"
    abort    "*********************************************************"
  fi
elif [ "$BOOTMODE" ] && [ "$KSU" ]; then
  ui_print "- Installing from KernelSU app"
  KSU_VER="$KSU_KERNEL_VER_CODE"
  KSU_MGR_VER="$KSU_VER_CODE"
  if [ -z "$KSU_VER" ]; then
    ui_print "- KSU kernel version env var not found. Trying ioctl fallback..."
    case "$ARCH" in
      "arm64") KSU_TOOL_FILE="get_ksu_ver-arm64" ;;
      "arm")   KSU_TOOL_FILE="get_ksu_ver-arm" ;;
      "x64")   KSU_TOOL_FILE="get_ksu_ver-x64" ;;
      "x86")   KSU_TOOL_FILE="get_ksu_ver-x86" ;;
      *)       KSU_TOOL_FILE="" ;;
    esac
    KSU_TOOL_PATH="$TMPDIR/$KSU_TOOL_FILE"
    if [ -n "$KSU_TOOL_FILE" ] && unzip -o "$ZIPFILE" "$KSU_TOOL_FILE" -d "$TMPDIR" >&2; then
      set_perm "$KSU_TOOL_PATH" 0 0 0755
      KSU_VER=$("$KSU_TOOL_PATH")
      ui_print "- KSU kernel version via ioctl: $KSU_VER"
    else
      ui_print "! Warning: KSU ioctl tool not found for $ARCH ($KSU_TOOL_FILE)."
    fi
  fi
  ui_print "- KernelSU version: $KSU_VER (kernel) + $KSU_MGR_VER (ksud)"
  if [ -z "$KSU_VER" ]; then
    ui_print "*********************************************************"
    ui_print "! KernelSU kernel version info is missing!"
    abort    "*********************************************************"
  elif [ "$KSU_VER" = "0" ]; then
    ui_print "! Warning: Could not detect KernelSU kernel version (KSU_VER=0)."
    ui_print "- Proceeding to check ksud (manager) version only."
  else
    if [ "$KSU_VER" -lt "$MIN_KSU_VERSION" ]; then
      ui_print "*********************************************************"
      ui_print "! KernelSU version is too old! ($KSU_VER < $MIN_KSU_VERSION)"
      abort    "*********************************************************"
    elif [ "$KSU_VER" -ge "$MAX_KSU_VERSION" ]; then
      ui_print "*********************************************************"
      ui_print "! KernelSU version abnormal!"
      ui_print "! Please integrate KernelSU into your kernel"
      ui_print "  as submodule instead of copying the source code"
      abort    "*********************************************************"
    fi
  fi
  if ! [ "$KSU_MGR_VER" ] || [ "$KSU_MGR_VER" -lt "$MIN_KSUD_VERSION" ]; then
    ui_print "*********************************************************"
    ui_print "! ksud version is too old!"
    ui_print "! Please update KernelSU Manager to latest version"
    abort    "*********************************************************"
  fi
  if [ "$(which magisk)" ]; then
    ui_print "*********************************************************"
    ui_print "! Multiple root implementation is NOT supported!"
    ui_print "! Please uninstall Magisk before installing NeoZygisk"
    abort    "*********************************************************"
  fi
elif [ "$BOOTMODE" ] && [ "$MAGISK_VER_CODE" ]; then
  ui_print "- Installing from Magisk app"
  if [ "$MAGISK_VER_CODE" -lt "$MIN_MAGISK_VERSION" ]; then
    ui_print "*********************************************************"
    ui_print "! Magisk version is too old!"
    ui_print "! Please update Magisk to latest version"
    abort    "*********************************************************"
  fi
else
  ui_print "*********************************************************"
  ui_print "! Install from recovery is not supported"
  ui_print "! Please install from APatch, KernelSU or Magisk app"
  abort    "*********************************************************"
fi

VERSION=$(grep_prop version "${TMPDIR}/module.prop")
ui_print "- Installing NeoZygisk $VERSION"

# check android
if [ "$API" -lt 26 ]; then
  ui_print "! Unsupported sdk: $API"
  abort "! Minimal supported sdk is 26 (Android 8.0)"
else
  ui_print "- Device sdk: $API"
fi

# check architecture
if [ "$ARCH" != "arm" ] && [ "$ARCH" != "arm64" ] && [ "$ARCH" != "x86" ] && [ "$ARCH" != "x64" ]; then
  abort "! Unsupported platform: $ARCH"
else
  ui_print "- Device platform: $ARCH"
fi

ui_print "- Extracting verify.sh"
unzip -o "$ZIPFILE" 'verify.sh' -d "$TMPDIR" >&2
if [ ! -f "$TMPDIR/verify.sh" ]; then
  ui_print "*********************************************************"
  ui_print "! Unable to extract verify.sh!"
  ui_print "! This zip may be corrupted, please try downloading again"
  abort    "*********************************************************"
fi
. "$TMPDIR/verify.sh"
extract "$ZIPFILE" 'customize.sh'  "$TMPDIR/.vunzip"
extract "$ZIPFILE" 'verify.sh'     "$TMPDIR/.vunzip"
extract "$ZIPFILE" 'sepolicy.rule' "$TMPDIR"

if [ "$KSU" ]; then
  ui_print "- Checking SELinux patches"
  if ! check_sepolicy "$TMPDIR/sepolicy.rule"; then
    ui_print "*********************************************************"
    ui_print "! Unable to apply SELinux patches!"
    ui_print "! Your kernel may not support SELinux patch fully"
    abort    "*********************************************************"
  fi
fi

ui_print "- Extracting module files"
extract "$ZIPFILE" 'action.sh'     "$MODPATH"
extract "$ZIPFILE" 'module.prop'     "$MODPATH"
extract "$ZIPFILE" 'post-fs-data.sh' "$MODPATH"
extract "$ZIPFILE" 'service.sh'      "$MODPATH"
extract "$ZIPFILE" 'uninstall.sh'      "$MODPATH"
extract "$ZIPFILE" 'zygisk-ctl.sh'   "$MODPATH"
mv "$TMPDIR/sepolicy.rule" "$MODPATH"

mkdir "$MODPATH/bin"
mkdir "$MODPATH/lib"
mkdir "$MODPATH/lib64"
mv "$MODPATH/zygisk-ctl.sh" "$MODPATH/bin/zygisk-ctl"

case "$ARCH" in
  "arm64")
    BIN_ARCH_PATH="bin/arm64-v8a"
    LIB_ARCH_PATH="lib/arm64-v8a"
    LIB_TARGET_DIR="$MODPATH/lib64"
    ZYGISKD_TARGET_NAME="zygiskd64"
    PTRACE_TARGET_NAME="zygisk-ptrace64"
    ;;
  "arm")
    BIN_ARCH_PATH="bin/armeabi-v7a"
    LIB_ARCH_PATH="lib/armeabi-v7a"
    LIB_TARGET_DIR="$MODPATH/lib"
    ZYGISKD_TARGET_NAME="zygiskd32"
    PTRACE_TARGET_NAME="zygisk-ptrace32"
    ;;
  "x64")
    BIN_ARCH_PATH="bin/x86_64"
    LIB_ARCH_PATH="lib/x86_64"
    LIB_TARGET_DIR="$MODPATH/lib64"
    ZYGISKD_TARGET_NAME="zygiskd64"
    PTRACE_TARGET_NAME="zygisk-ptrace64"
    ;;
  "x86")
    BIN_ARCH_PATH="bin/x86"
    LIB_ARCH_PATH="lib/x86"
    LIB_TARGET_DIR="$MODPATH/lib"
    ZYGISKD_TARGET_NAME="zygiskd32"
    PTRACE_TARGET_NAME="zygisk-ptrace32"
    ;;
  *)
    abort "! Should not happen: Unknown ARCH $ARCH"
    ;;
esac

ui_print "- Extracting $ARCH libraries"

extract "$ZIPFILE" "$BIN_ARCH_PATH/zygiskd" "$MODPATH/bin" true
mv "$MODPATH/bin/zygiskd" "$MODPATH/bin/$ZYGISKD_TARGET_NAME"

extract "$ZIPFILE" "$LIB_ARCH_PATH/libzygisk.so" "$LIB_TARGET_DIR" true

extract "$ZIPFILE" "$LIB_ARCH_PATH/libzygisk_ptrace.so" "$MODPATH/bin" true
mv "$MODPATH/bin/libzygisk_ptrace.so" "$MODPATH/bin/$PTRACE_TARGET_NAME"

ui_print "- Setting permissions"
set_perm_recursive "$MODPATH/bin" 0 0 0755 0755
set_perm_recursive "$MODPATH/lib" 0 0 0755 0644 u:object_r:system_lib_file:s0
set_perm_recursive "$MODPATH/lib64" 0 0 0755 0644 u:object_r:system_lib_file:s0

# If Huawei's Maple is enabled, system_server is created with a special way which is out of Zygisk's control
HUAWEI_MAPLE_ENABLED=$(grep_prop ro.maple.enable)
if [ "$HUAWEI_MAPLE_ENABLED" == "1" ]; then
  ui_print "- Add ro.maple.enable=0"
  echo "ro.maple.enable=0" >>"$MODPATH/system.prop"
fi
