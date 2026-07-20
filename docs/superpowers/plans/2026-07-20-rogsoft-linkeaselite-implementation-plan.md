# LinkEaseLite Asuswrt Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone `rogsoft_LinkEaseLite` Asuswrt/Koolshare plugin that packages the `cmd/client` lite binary as `linkease-lite`, can coexist with default LinkEase installation, and enforces single active runtime on shared port `8897`.

**Architecture:** Start from the existing `rogsoft_LinkEase` plugin contract but rename the module to `linkeaselite` and remove full/standard assets. Lite has independent dbus keys, scripts, app directory, and binary, while both Lite and default LinkEase stop each other before startup to avoid port conflicts.

**Tech Stack:** Shell scripts for Koolshare install/runtime, Python package builder, static contract tests, `apptunnel/cmd/client` lite build script, SSH smoke on Asuswrt target.

## Global Constraints

- Lite plugin repo: `/projects/workspace-linkease-ubuntu/linkease-github/rogsoft/rogsoft_LinkEaseLite`
- Default plugin repo: `/projects/workspace-linkease-ubuntu/linkease-github/rogsoft/rogsoft_LinkEase`
- Apptunnel repo: `/var/tmp/agentflow-dev/apptunnel-icms/6f69-linkease-lite/apptunnel`
- Module id: `linkeaselite`
- Binary name: `linkease-lite`
- Package name: `linkeaselite.tar.gz`
- Shared port: `8897`
- Target router: `ssh -p 2222 admin@192.168.3.247`
- Target architecture: `linux/arm/5` 32-bit ARM. The ARM32 binary is used intentionally so one package can run on legacy ARM32 routers and ARM64 Asuswrt routers, while keeping the Go runtime virtual address footprint lower than the ARM64 build.
- Lite package must not include `link-ease`, `linkease-full`, `linkease-media`, `heif-converter`, or `linkease-plugins`.
- Lite install/uninstall must not remove default LinkEase files or `linkease_*` dbus keys, except Lite startup may set `linkease_enable=0` as runtime mutual exclusion.

---

## Task 1: Add Lite Plugin Contract Tests

**Files:**

- Create: `tests/test_linkeaselite_contract.py`
- Create: `tests/test_build_script.py`

**Steps:**

- [ ] Add tests that assert `config.json.js` uses module `linkeaselite`, home page `Module_linkeaselite.asp`, and package `linkeaselite.tar.gz`.
- [ ] Add tests that assert install/uninstall scripts use `linkeaselite_*` dbus keys and do not remove default LinkEase files or keys.
- [ ] Add tests that assert runtime script starts `/koolshare/bin/linkease-lite`, stops `link-ease` and `linkease-full`, disables `linkease_enable`, and checks `pidof linkease-lite`.
- [ ] Add tests that assert package output contains `linkeaselite/bin/linkease-lite` and excludes full/default binaries.
- [ ] Run:

  ```sh
  python3 -m unittest discover -s tests
  ```

  Expected before implementation: tests fail because the plugin skeleton does not exist yet.

---

## Task 2: Create Lite Plugin Skeleton

**Files:**

- Create: `config.json.js`
- Create: `build.py`
- Create: `build_hnd.sh`
- Create: `linkeaselite/install.sh`
- Create: `linkeaselite/uninstall.sh`
- Create: `linkeaselite/scripts/linkeaselite_config.sh`
- Create: `linkeaselite/scripts/linkeaselite_status.sh`
- Create: `linkeaselite/webs/Module_linkeaselite.asp`
- Copy: `linkeaselite/res/icon-linkease.png`
- Create: `linkeaselite/version`

**Steps:**

- [ ] Implement a Lite-only package builder that stages no full artifact and writes `linkeaselite.tar.gz`.
- [ ] Implement installer using `module=${DIR##*/}` so package extraction under `/tmp/linkeaselite` works.
- [ ] Copy only Lite files to `/koolshare`: binary, icon, scripts, web page, uninstall script.
- [ ] Register only `softcenter_module_linkeaselite_*` and `linkeaselite_version`.
- [ ] Run contract tests until Task 1 package/config assertions pass.
- [ ] Commit.

---

## Task 3: Implement Runtime Mutual Exclusion

**Files:**

- Modify: `linkeaselite/scripts/linkeaselite_config.sh`
- Modify: `linkeaselite/scripts/linkeaselite_status.sh`
- Modify default plugin: `/projects/workspace-linkease-ubuntu/linkease-github/rogsoft/rogsoft_LinkEase/linkease/scripts/linkease_config.sh`

**Steps:**

- [ ] In Lite startup, stop `link-ease`, `linkease-full`, and `linkease-lite`.
- [ ] In Lite startup, set `dbus set linkease_enable=0`.
- [ ] Start `/koolshare/bin/linkease-lite` with `LINKEASE_SIMPLE=1`.
- [ ] In default LinkEase startup, stop `linkease-lite` and set `dbus set linkeaselite_enable=0`.
- [ ] Keep stop/uninstall scoped so Lite does not delete default LinkEase files.
- [ ] Run contract tests for both plugin repos.
- [ ] Commit Lite repo changes and default plugin compatibility change separately.

---

## Task 4: Build And Stage ARM32 Lite Binary

**Files:**

- Modify: `linkeaselite/bin/linkease-lite`
- Use: `/var/tmp/agentflow-dev/apptunnel-icms/6f69-linkease-lite/apptunnel/cmd/client/scripts/build-client.sh`
- Modify: `linkeaselite/scripts/linkeaselite_config.sh`

**Steps:**

- [ ] Run:

  ```sh
  PATH=/config/.local/share/mise/installs/go/1.25.12/bin:$PATH \
    BUILD_MODE=lite TARGETS="linux/arm/5" OUT_DIR=/tmp/linkeaselite-build \
    bash cmd/client/scripts/build-client.sh
  ```

- [ ] Install artifact:

  ```sh
  install -m 0755 /tmp/linkeaselite-build/link-ease /projects/workspace-linkease-ubuntu/linkease-github/rogsoft/rogsoft_LinkEaseLite/linkeaselite/bin/linkease-lite
  ```

- [ ] Verify:

  ```sh
  file linkeaselite/bin/linkease-lite
  du -h linkeaselite/bin/linkease-lite
  ```

- [ ] Add runtime memory defaults for small routers:

  ```text
  MemTotal <= 512M:  GOMEMLIMIT=128MiB
  MemTotal <= 1024M: GOMEMLIMIT=192MiB
  Larger routers:    GOMEMLIMIT=384MiB
  GOGC default:      50
  Virtual memory:    ulimit -v unlimited 2>/dev/null || true
  ```

- [ ] Run package tests and build package.
- [ ] Commit.

---

## Task 5: Router Install And Smoke Test

**Files:**

- Use generated `linkeaselite.tar.gz`

**Steps:**

- [ ] Copy package to router:

  ```sh
  scp -P 2222 linkeaselite.tar.gz admin@192.168.3.247:/tmp/
  ```

- [ ] Install:

  ```sh
  ssh -p 2222 admin@192.168.3.247 'cd /tmp && tar -xzf linkeaselite.tar.gz && sh /tmp/linkeaselite/install.sh'
  ```

- [ ] Start Lite:

  ```sh
  ssh -p 2222 admin@192.168.3.247 'dbus set linkeaselite_enable=1; sh /koolshare/scripts/linkeaselite_config.sh start'
  ```

- [ ] Verify process and port:

  ```sh
  ssh -p 2222 admin@192.168.3.247 'pidof linkease-lite; netstat -lntp 2>/dev/null | grep 8897 || true'
  ```

- [ ] Verify binary commands and HTTP:

  ```sh
  ssh -p 2222 admin@192.168.3.247 '
    /koolshare/bin/linkease-lite showVersion
    /koolshare/bin/linkease-lite simplifyInfo
    curl -sS http://127.0.0.1:8897/api/version
    curl -sS http://127.0.0.1:8897/api/device/list
    curl -sS http://127.0.0.1:8897/api/task/status/
    curl -sS -X POST http://127.0.0.1:8897/api/device/virtual/sftp/verify/ -d "{}"
    curl -sS -X POST http://127.0.0.1:8897/api/device/virtual/webdav/verify/ -d "{}"
  '
  ```

- [ ] Record smoke result.

---

## Self-Review Checklist

- [ ] No Lite script uses `linkease_` keys for its own state.
- [ ] No Lite uninstall command removes default LinkEase files.
- [ ] Lite and default startup scripts stop the opposite runtime.
- [ ] Package excludes default/full binaries.
- [ ] Router smoke uses `192.168.3.247`.
