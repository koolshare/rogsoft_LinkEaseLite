# LinkEaseLite Asuswrt Plugin Design

Date: 2026-07-20

## Goal

Create a separate Asuswrt/Koolshare plugin, `rogsoft_LinkEaseLite`, for routers with limited flash or memory. The plugin installs a small `linkease-lite` binary built from `cmd/client` lite mode and does not include the default LinkEase standard/full runtime binaries.

## Product Boundary

`LinkEaseLite` and the default `LinkEase` plugin may be installed on the same router, but only one may run at a time. They share the same legacy management port, `8897`, so each plugin must stop the other plugin's runtime before starting its own.

The Lite plugin is not an edition inside the default LinkEase plugin. It has its own package, module id, scripts, dbus keys, UI page, install state, and runtime binary.

## Naming

- Repository: `/projects/workspace-linkease-ubuntu/linkease-github/rogsoft/rogsoft_LinkEaseLite`
- Module id: `linkeaselite`
- Package: `linkeaselite.tar.gz`
- Binary: `/koolshare/bin/linkease-lite`
- Runtime process name: `linkease-lite`
- Config script: `/koolshare/scripts/linkeaselite_config.sh`
- Status script: `/koolshare/scripts/linkeaselite_status.sh`
- UI page: `/koolshare/webs/Module_linkeaselite.asp`
- App dir: `/koolshare/linkeaselite`
- Dbus prefix: `linkeaselite_`

The module id intentionally avoids hyphens because shell variables and dbus export output are safer with alphanumeric/underscore identifiers.

## Runtime Behavior

Lite startup:

1. Resolve its own data paths under `linkeaselite` keys.
2. Stop competing runtimes:
   - `link-ease`
   - `linkease-full`
   - `linkease-lite`
3. Disable the default LinkEase enable flag with `dbus set linkease_enable=0`.
4. Start `/koolshare/bin/linkease-lite` with `LINKEASE_SIMPLE=1`.

Default LinkEase startup must also stop `linkease-lite` and set `linkeaselite_enable=0` before it starts `link-ease` or `linkease-full`. Without this compatibility change, starting the default plugin after Lite could leave two plugins competing for port `8897`.

Lite stop only stops `linkease-lite`. It must not delete or alter default LinkEase configuration except for runtime mutual exclusion during start.

## Data And Configuration

Lite configuration is independent from default LinkEase:

- `linkeaselite_enable`
- `linkeaselite_version`
- `linkeaselite_data_disk`
- `linkeaselite_data_root_parent`
- `linkeaselite_data_root`

The default fallback data root is `/koolshare/linkeaselite/data/bootstrap`. If an external disk is selected, Lite uses `.linkease_lite_data` and `.linkease_lite_recycle` under that disk. This avoids conflicts with default LinkEase `.linkease_data` and `.linkease_recycle`.

The first implementation does not migrate default LinkEase account/device identity into Lite. Users may bind Lite independently. This keeps uninstall and recovery behavior simple and prevents two installed plugins from accidentally sharing one mutable runtime state directory.

## Package Contents

The Lite package includes:

- `linkeaselite/install.sh`
- `linkeaselite/uninstall.sh`
- `linkeaselite/scripts/linkeaselite_config.sh`
- `linkeaselite/scripts/linkeaselite_status.sh`
- `linkeaselite/webs/Module_linkeaselite.asp`
- `linkeaselite/res/icon-linkease.png`
- `linkeaselite/bin/linkease-lite`
- `linkeaselite/version`

The Lite package excludes:

- `link-ease`
- `linkease-full`
- `linkease-media`
- `heif-converter`
- `linkease-plugins/aria2.sh`
- full artifact download or staging logic

## Build Source

`linkease-lite` is built from `apptunnel/cmd/client` using lite mode. The package intentionally uses a 32-bit ARM binary because the legacy plugin used an ARM32 binary, it runs on the target ARM64 Asuswrt router, and it keeps the Go runtime virtual address footprint lower than the ARM64 build.

```sh
BUILD_MODE=lite TARGETS="linux/arm/5" OUT_DIR=/tmp/linkeaselite-build bash cmd/client/scripts/build-client.sh
```

The target router is `aarch64`, verified through:

```sh
ssh -p 2222 admin@192.168.3.247 'uname -m'
```

The generated `link-ease` artifact is renamed to `linkease-lite` when staged into the plugin package.

## Memory Policy

The Lite startup script exports Go runtime memory controls before starting `linkease-lite`:

- `GOGC=50` by default.
- `GOMEMLIMIT=128MiB` when `/proc/meminfo` reports `MemTotal <= 524288` KB.
- `GOMEMLIMIT=192MiB` when `MemTotal <= 1048576` KB.
- `GOMEMLIMIT=384MiB` on larger routers.
- `ulimit -v unlimited 2>/dev/null || true` before launch, so firmware shell virtual-memory limits do not prevent Go from reserving address space.

Users or support scripts may override these defaults through `linkeaselite_gomemlimit` and `linkeaselite_gogc` dbus keys.

## Test Target

Target router:

```sh
ssh -p 2222 admin@192.168.3.247
```

The router is `RT-AX86U-0240`, `aarch64`, and has about 8 MB free on `/` during initial inspection. Package size and install footprint matter.

## Acceptance Criteria

- `rogsoft_LinkEaseLite` builds `linkeaselite.tar.gz`.
- The package contains `linkeaselite/bin/linkease-lite` and does not contain default/full binaries.
- Installing Lite registers `softcenter_module_linkeaselite_*` keys and does not overwrite `softcenter_module_linkease_*`.
- Starting Lite stops default LinkEase runtimes and starts only `linkease-lite` on port `8897`.
- Starting default LinkEase stops `linkease-lite`.
- Lite status reports `LinkEase Lite` state from `pidof linkease-lite`.
- Lite uninstall removes only Lite files and `linkeaselite_*` dbus keys, not default LinkEase files or keys.
- Router smoke can run `linkease-lite showVersion`, `linkease-lite simplifyInfo`, and basic HTTP probes on `127.0.0.1:8897`.
