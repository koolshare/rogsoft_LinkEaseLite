# LinkEaseLite Router Smoke

Date: 2026-07-20

## Target

- Router: `ssh -p 2222 admin@192.168.3.247`
- Model/OS: `RT-AX86U-0240`, `aarch64`, `ASUSWRT-Merlin-KoolShare`
- Package: `linkeaselite.tar.gz`
- Binary: `/koolshare/bin/linkease-lite`
- Port: `8897`

## Package

The lite binary was built from `apptunnel/cmd/client` as 32-bit ARM:

```sh
BUILD_MODE=lite TARGETS="linux/arm/5" OUT_DIR=/tmp/linkeaselite-arm32-build bash cmd/client/scripts/build-client.sh
```

Staged artifact:

```text
linkeaselite/bin/linkease-lite: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), statically linked, stripped
linkeaselite/bin/linkease-lite: 20M
linkeaselite.tar.gz: 6.7M
linkeaselite/bin/linkease-lite sha256: 3e378a716901049c3947265897806ebb00327b2109e2eeafd9d36804e5f9a74c
linkeaselite.tar.gz sha256: e8010ad8dde24a2e42b8ada0fef6569818d548fa0f6a564c6c7697f07d02a640
```

The ARM32 binary is intentional: it matches the legacy LinkEaseLite compatibility model, runs on the ARM64 Asuswrt target, remains compatible with ARM32 routers, and reduced idle virtual memory on the test router from about `1243152 kB` for the ARM64 build to about `549168 kB` for the ARM32 build. Idle RSS was about `15 MB`.

Lite startup exports Go memory defaults before launching `linkease-lite`:

```text
MemTotal <= 512M:  GOMEMLIMIT=128MiB
MemTotal <= 1024M: GOMEMLIMIT=192MiB
Larger routers:    GOMEMLIMIT=384MiB
GOGC default:      50
Virtual memory:    ulimit -v unlimited 2>/dev/null || true
```

`GOMEMLIMIT` and `GOGC` reduce heap/RSS growth risk under pressure; they do not significantly reduce Go's initial virtual address reservation.

## Install

`scp` was not usable because the router lacks `/opt/libexec/sftp-server`, so the package was uploaded over SSH stdin:

```sh
ssh -p 2222 admin@192.168.3.247 'cat > /tmp/linkeaselite.tar.gz' < linkeaselite.tar.gz
ssh -p 2222 admin@192.168.3.247 'cd /tmp && rm -rf /tmp/linkeaselite && tar -xzf /tmp/linkeaselite.tar.gz && sh /tmp/linkeaselite/install.sh'
```

Install registered:

```text
softcenter_module_linkeaselite_install=1
softcenter_module_linkeaselite_version=0.1.0
```

## Lite Startup

Starting Lite:

```sh
dbus set linkeaselite_enable=1
sh /koolshare/scripts/linkeaselite_config.sh start
```

Result:

```text
linkease_enable=0
linkeaselite_enable=1
link-ease-pid=
linkease-full-pid=
linkease-lite-pid=21268
tcp        0      0 :::8897                 :::*                    LISTEN      21268/linkease-lite
GOMEMLIMIT=192MiB
GOGC=50
VmPeak: 553916 kB
VmSize: 553916 kB
VmRSS:  16088 kB
VmData: 533788 kB
```

Reinstall while an older `linkease-lite` process was still running also worked: `before_pid=8432`, `after_pid=8654`.

The installed web page `/koolshare/webs/Module_linkeaselite.asp` includes the Softcenter page shell markers required for the left navigation:

```text
id="mainMenu"
id="subMenu"
id="tabMenu"
show_menu(menu_hook)
Module_linkeaselite.asp
```

The installed web page points the configuration entry at the local embedded guide:

```text
http://<router>:8897/guide/?source=linkeaselite
```

The Lite binary embeds `linkease-client-js/build/linkease-bind.zip`, and router smoke verified local guide assets without remote static requests:

```text
GET /guide/index.html?source=linkeaselite -> HTTP/1.1 200 OK, 783 bytes
GET /guide/js/app.js -> HTTP/1.1 200 OK, 139346 bytes
```

The page submit path was smoke-tested by invoking the same explicit web action used by `Module_linkeaselite.asp`:

```text
sh /koolshare/scripts/linkeaselite_config.sh web 1
linkeaselite_enable=1
pid_after_enable=18011
tcp        0      0 :::8897                 :::*                    LISTEN      18011/linkease-lite
GET /api/version -> {"version":"1.6.9","webVersion":"0.3.5"}

sh /koolshare/scripts/linkeaselite_config.sh web 0
linkeaselite_enable=0
pid_after_disable=

dbus set linkeaselite_enable=1
killall linkease-lite
sh /koolshare/scripts/linkeaselite_status.sh
pid_after_status=18123
tcp        0      0 :::8897                 :::*                    LISTEN      18123/linkease-lite
```

## HTTP Smoke

Command responses:

```text
/koolshare/bin/linkease-lite showVersion
1.6.9

/koolshare/bin/linkease-lite simplifyInfo
simplfy: YES
memory: 933
version: 1.6.9
```

HTTP responses:

```text
GET /api/version
HTTP/1.1 200 OK
{"version":"1.6.9","webVersion":"0.3.5"}

POST /api/file/basic/list/
HTTP/1.1 200 OK
{"error":"forbidden","scope":"filebasic","success":-1004}

POST /api/task/status/
HTTP/1.1 200 OK
{"error":"empty jobs","scope":"filebasic","success":-10000}

POST /api/device/virtual/sftp/verify/
HTTP/1.1 501 Not Implemented
{"error":"not supported","scope":"device","success":-1005}

POST /api/device/virtual/webdav/verify/
HTTP/1.1 501 Not Implemented
{"error":"not supported","scope":"device","success":-1005}
```

The file list endpoint returned an authentication failure rather than 404, which confirms the runtime route is active. The virtual SFTP/WebDAV endpoints returned the expected lite not-supported response.

## Mutual Exclusion

Default LinkEase startup was updated on the router by replacing `/koolshare/scripts/linkease_config.sh` with the version from `rogsoft_LinkEase` commit `4ac481c`.

Starting default LinkEase produced:

```text
linkease_enable=1
linkeaselite_enable=0
link-ease-pid=
linkease-full-pid=1087
linkease-lite-pid=
```

Starting Lite again stopped default LinkEase and restored Lite on port `8897`:

```text
linkease_enable=0
linkeaselite_enable=1
link-ease-pid=
linkease-full-pid=
linkease-lite-pid=1162
tcp        0      0 :::8897                 :::*                    LISTEN      1162/linkease-lite
```
