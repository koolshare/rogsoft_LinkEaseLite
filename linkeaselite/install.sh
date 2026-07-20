#!/bin/sh
source /koolshare/scripts/base.sh

DIR=$(cd "$(dirname "$0")"; pwd)
module=${DIR##*/}
APP_DIR=/koolshare/${module}

mkdir -p /koolshare/bin /koolshare/res /koolshare/scripts /koolshare/webs "$APP_DIR"
cp -f "$DIR/bin/linkease-lite" /koolshare/bin/linkease-lite
cp -f "$DIR/res/icon-linkease.png" /koolshare/res/icon-linkeaselite.png
cp -f "$DIR/scripts/linkeaselite_config.sh" /koolshare/scripts/linkeaselite_config.sh
cp -f "$DIR/scripts/linkeaselite_status.sh" /koolshare/scripts/linkeaselite_status.sh
cp -f "$DIR/webs/Module_linkeaselite.asp" /koolshare/webs/Module_linkeaselite.asp
cp -f "$DIR/uninstall.sh" /koolshare/scripts/uninstall_linkeaselite.sh
chmod 755 /koolshare/bin/linkease-lite /koolshare/scripts/linkeaselite_config.sh \
    /koolshare/scripts/linkeaselite_status.sh /koolshare/scripts/uninstall_linkeaselite.sh

dbus set linkeaselite_enable=0
dbus set linkeaselite_version="$(cat "$DIR/version")"
dbus set linkeaselite_data_disk=""
dbus set linkeaselite_data_root_parent=""
dbus set linkeaselite_data_root="${APP_DIR}/data/bootstrap"
dbus set linkeaselite_gomemlimit=""
dbus set linkeaselite_gogc=""
dbus set softcenter_module_linkeaselite_install=1
dbus set softcenter_module_linkeaselite_version="$(cat "$DIR/version")"
dbus set softcenter_module_linkeaselite_name=linkeaselite
dbus set softcenter_module_linkeaselite_title="LinkEase Lite"
dbus set softcenter_module_linkeaselite_description="LinkEase Lite remote file access"

ln -sf /koolshare/scripts/linkeaselite_config.sh /koolshare/init.d/S99linkeaselite.sh
ln -sf /koolshare/scripts/linkeaselite_config.sh /koolshare/init.d/N99linkeaselite.sh
