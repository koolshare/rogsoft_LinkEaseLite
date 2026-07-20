# LinkEaseLite Router Smoke

Date: 2026-07-20

## Target

- Router: `ssh -p 2222 admin@192.168.3.247`
- Model/OS: `RT-AX86U-0240`, `aarch64`, `ASUSWRT-Merlin-KoolShare`
- Package: `linkeaselite.tar.gz`
- Binary: `/koolshare/bin/linkease-lite`
- Port: `8897`

## Package

The ARM64 lite binary was built from `apptunnel/cmd/client` with:

```sh
BUILD_MODE=lite TARGETS="linux/arm64" OUT_DIR=/tmp/linkeaselite-build bash cmd/client/scripts/build-client.sh
```

Staged artifact:

```text
linkeaselite/bin/linkease-lite: ELF 64-bit LSB executable, ARM aarch64, statically linked, stripped
linkeaselite/bin/linkease-lite: 16M
linkeaselite.tar.gz: 5.6M
```

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
linkease-lite-pid=1162
tcp        0      0 :::8897                 :::*                    LISTEN      1162/linkease-lite
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
