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

default_gomemlimit(){
    mem_kb="$(awk '/MemTotal/ { print $2; exit }' /proc/meminfo 2>/dev/null)"
    case "$mem_kb" in
        ''|*[!0-9]*) echo 128MiB; return 0 ;;
    esac
    if [ "$mem_kb" -le 524288 ] 2>/dev/null; then
        echo 128MiB
    elif [ "$mem_kb" -le 1048576 ] 2>/dev/null; then
        echo 192MiB
    else
        echo 384MiB
    fi
}

apply_go_memory_limits(){
    export GOMEMLIMIT="${linkeaselite_gomemlimit:-$(default_gomemlimit)}"
    export GOGC="${linkeaselite_gogc:-50}"
}

wait_lite_stopped(){
    i=0
    while pidof linkease-lite >/dev/null 2>&1 && [ "$i" -lt 10 ]; do
        sleep 1
        i=$((i + 1))
    done
}

start_lite(){
    killall link-ease >/dev/null 2>&1
    killall linkease-full >/dev/null 2>&1
    killall linkease-lite >/dev/null 2>&1
    wait_lite_stopped
    dbus set linkease_enable=0
    configure_data_paths
    apply_go_memory_limits
    ulimit -v unlimited 2>/dev/null || true
    mkdir -p "$USER_DATA_PATH" "$SYSTEM_DATA_PATH" "$TEMP_PATH"
    [ -n "$LINKEASE_RECYCLE_ROOT" ] && mkdir -p "$LINKEASE_RECYCLE_ROOT"
    LINKEASE_SIMPLE=1 start-stop-daemon -S -b -x /koolshare/bin/linkease-lite -- --rootDir "$LINKEASE_DATA_ROOT" --deviceAddr :8897
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
