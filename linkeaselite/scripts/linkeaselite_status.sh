#!/bin/sh
eval "$(dbus export linkeaselite)"
source /koolshare/scripts/base.sh

if pidof linkease-lite >/dev/null 2>&1; then
    http_response "LinkEase Lite running"
elif [ "$linkeaselite_enable" = "1" ]; then
    /koolshare/scripts/linkeaselite_config.sh start >/dev/null 2>&1
    sleep 1
    if pidof linkease-lite >/dev/null 2>&1; then
        http_response "LinkEase Lite starting"
    else
        http_response "LinkEase Lite stopped"
    fi
else
    http_response "LinkEase Lite stopped"
fi
