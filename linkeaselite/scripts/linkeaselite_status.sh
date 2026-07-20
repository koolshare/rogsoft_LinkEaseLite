#!/bin/sh
eval "$(dbus export linkeaselite)"
source /koolshare/scripts/base.sh

if pidof linkease-lite >/dev/null 2>&1; then
    http_response "LinkEase Lite running"
else
    http_response "LinkEase Lite stopped"
fi
