#!/bin/sh
eval "$(dbus export linkeaselite)"
source /koolshare/scripts/base.sh

APP_DIR=/koolshare/linkeaselite
BIN=/koolshare/bin/linkease-lite
ACTION="$1"

configure_data_paths(){
    if [ -n "$linkeaselite_data_disk" ] && [ -d "$linkeaselite_data_disk" ]; then
        export LINKEASE_DATA_ROOT="${linkeaselite_data_disk}/.linkease_lite_data"
        export LINKEASE_RECYCLE_ROOT="${linkeaselite_data_disk}/.linkease_lite_recycle"
    else
        export LINKEASE_DATA_ROOT="${linkeaselite_data_root:-${APP_DIR}/data/bootstrap}"
        export LINKEASE_RECYCLE_ROOT=""
    fi
    export LINKEASE_BOOTSTRAP_FALLBACK=1
    export USER_DATA_PATH="${LINKEASE_DATA_ROOT}/users/admin"
    export SYSTEM_DATA_PATH="${LINKEASE_DATA_ROOT}/system"
    export TEMP_PATH="${LINKEASE_DATA_ROOT}/tmp"
}

start_lite(){
    killall link-ease >/dev/null 2>&1
    killall linkease-full >/dev/null 2>&1
    killall linkease-lite >/dev/null 2>&1
    dbus set linkease_enable=0
    configure_data_paths
    mkdir -p "$USER_DATA_PATH" "$SYSTEM_DATA_PATH" "$TEMP_PATH"
    [ -n "$LINKEASE_RECYCLE_ROOT" ] && mkdir -p "$LINKEASE_RECYCLE_ROOT"
    LINKEASE_SIMPLE=1 start-stop-daemon -S -q -b -x /koolshare/bin/linkease-lite
}

stop_lite(){
    killall linkease-lite >/dev/null 2>&1
}

case "$ACTION" in
    start)
        if [ "$linkeaselite_enable" = "1" ]; then
            start_lite
        fi
        ;;
    *)
        if [ "$linkeaselite_enable" = "1" ]; then
            start_lite
        else
            stop_lite
        fi
        http_response "$1"
        ;;
esac
