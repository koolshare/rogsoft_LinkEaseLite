#!/bin/sh
source /koolshare/scripts/base.sh

module=linkeaselite
APP_DIR=/koolshare/${module}

killall linkease-lite >/dev/null 2>&1
rm -f /koolshare/init.d/S99linkeaselite.sh /koolshare/init.d/N99linkeaselite.sh
rm -f /koolshare/bin/linkease-lite
rm -f /koolshare/res/icon-linkeaselite.png
rm -f /koolshare/scripts/linkeaselite_config.sh
rm -f /koolshare/scripts/linkeaselite_status.sh
rm -f /koolshare/scripts/uninstall_linkeaselite.sh
rm -f /koolshare/webs/Module_linkeaselite.asp
rm -rf "$APP_DIR"
rm -rf /tmp/linkeaselite*

dbus remove linkeaselite_enable
dbus remove linkeaselite_version
dbus remove linkeaselite_data_disk
dbus remove linkeaselite_data_root_parent
dbus remove linkeaselite_data_root
dbus remove softcenter_module_linkeaselite_install
dbus remove softcenter_module_linkeaselite_version
dbus remove softcenter_module_linkeaselite_name
dbus remove softcenter_module_linkeaselite_title
dbus remove softcenter_module_linkeaselite_description
