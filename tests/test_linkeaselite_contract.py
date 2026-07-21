import json
import re
import tarfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PLUGIN = ROOT.parent / "rogsoft_LinkEase"


class LinkEaseLiteContractTest(unittest.TestCase):
    def read(self, relative_path):
        path = ROOT / relative_path
        self.assertTrue(path.is_file(), f"missing contract file: {relative_path}")
        return path.read_text(encoding="utf-8")

    def test_config_uses_lite_module_identity(self):
        config = json.loads(self.read("config.json.js"))

        self.assertEqual(config["module"], "linkeaselite")
        self.assertEqual(config["home_url"], "Module_linkeaselite.asp")
        self.assertEqual(config["package"], "linkeaselite.tar.gz")

    def test_lite_version_matches_default_linkease_version(self):
        lite_config = json.loads(self.read("config.json.js"))
        default_config = json.loads((DEFAULT_PLUGIN / "config.json.js").read_text(encoding="utf-8"))
        lite_version = self.read("linkeaselite/version").strip()

        self.assertEqual(lite_config["version"], default_config["version"])
        self.assertEqual(lite_version, default_config["version"])

    def test_web_ui_uses_softcenter_page_shell(self):
        page = self.read("linkeaselite/webs/Module_linkeaselite.asp")

        for required in (
            'onload="init();"',
            'id="TopBanner"',
            'id="mainMenu"',
            'id="subMenu"',
            'id="tabMenu"',
            'class="FormTitle"',
            'id="footer"',
            "show_menu(menu_hook)",
            "function menu_hook",
            "Module_linkeaselite.asp",
            "/_api/linkeaselite",
            "linkeaselite_config.sh",
            "linkeaselite_status.sh",
            "linkeaselite_enable",
            'params": ["web", dbus["linkeaselite_enable"]]',
            '"/guide/index.html?t=" + Math.random()',
        ):
            self.assertIn(required, page)
        self.assertNotIn("source=linkeaselite", page)

    def test_install_and_uninstall_use_only_lite_state(self):
        install = self.read("linkeaselite/install.sh")
        uninstall = self.read("linkeaselite/uninstall.sh")

        self.assertRegex(install, r"module\s*=\s*\$\{DIR##\*/\}")
        for key in (
            "linkeaselite_enable",
            "linkeaselite_version",
            "linkeaselite_data_disk",
            "linkeaselite_data_root_parent",
            "linkeaselite_data_root",
            "softcenter_module_linkeaselite_",
        ):
            self.assertIn(key, install)

        for key in (
            "dbus remove linkeaselite_enable",
            "dbus remove linkeaselite_version",
            "dbus remove linkeaselite_data_disk",
            "dbus remove linkeaselite_data_root_parent",
            "dbus remove linkeaselite_data_root",
            "dbus remove softcenter_module_linkeaselite_",
        ):
            self.assertIn(key, uninstall)

        forbidden = (
            "/koolshare/bin/link-ease",
            "/koolshare/bin/linkease-full",
            "/koolshare/bin/linkease-media",
            "/koolshare/bin/heif-converter",
            "/koolshare/bin/linkease-plugins",
            "/koolshare/linkease",
            "/koolshare/scripts/linkease*.sh",
            "dbus remove linkease_enable",
            "dbus remove linkease_version",
            "dbus remove softcenter_module_linkease_",
        )
        for script in (install, uninstall):
            for forbidden_text in forbidden:
                self.assertNotIn(forbidden_text, script)

        destructive_default_patterns = (
            r"rm\s+-rf\s+[^;\n]*(?:/koolshare/(?:bin/link-ease|bin/linkease-full|linkease|scripts/linkease|webs/Module_linkease))",
            r"dbus\s+remove\s+(?:linkease_|softcenter_module_linkease_)",
        )
        for pattern in destructive_default_patterns:
            self.assertIsNone(re.search(pattern, uninstall))

    def test_lite_runtime_enforces_mutual_exclusion(self):
        runtime = self.read("linkeaselite/scripts/linkeaselite_config.sh")
        status = self.read("linkeaselite/scripts/linkeaselite_status.sh")

        start = re.search(r"start_lite\(\)\{([\s\S]*?)\n\}", runtime)
        self.assertIsNotNone(start)
        start_block = start.group(1)

        for marker in ("killall link-ease", "killall linkease-full", "killall linkease-lite"):
            self.assertIn(marker, start_block)
        self.assertRegex(runtime, r"dbus\s+set\s+linkease_enable=0")
        self.assertIn("/koolshare/bin/linkease-lite", start_block)
        self.assertIn("LINKEASE_SIMPLE=1", start_block)
        self.assertIn("--rootDir", start_block)
        self.assertIn('"$LINKEASE_DATA_ROOT"', start_block)
        self.assertIn("--deviceAddr", start_block)
        self.assertIn(":8897", start_block)
        self.assertNotIn(" -q ", start_block)
        self.assertLess(start_block.index("killall link-ease"), start_block.index("/koolshare/bin/linkease-lite"))
        self.assertLess(start_block.index("killall linkease-full"), start_block.index("/koolshare/bin/linkease-lite"))
        self.assertLess(start_block.index("killall linkease-lite"), start_block.index("/koolshare/bin/linkease-lite"))
        self.assertIn("wait_lite_stopped", runtime)
        self.assertLess(start_block.index("wait_lite_stopped"), start_block.index("/koolshare/bin/linkease-lite"))
        self.assertRegex(status, r"pidof\s+linkease-lite")

    def test_lite_runtime_handles_explicit_web_submit_state(self):
        runtime = self.read("linkeaselite/scripts/linkeaselite_config.sh")

        self.assertIn("web)", runtime)
        self.assertIn('"$2" = "1"', runtime)
        self.assertIn("dbus set linkeaselite_enable=1", runtime)
        self.assertIn("dbus set linkeaselite_enable=0", runtime)

    def test_lite_status_self_heals_enabled_stopped_runtime(self):
        status = self.read("linkeaselite/scripts/linkeaselite_status.sh")

        self.assertIn('if [ "$linkeaselite_enable" = "1" ]', status)
        self.assertIn("/koolshare/scripts/linkeaselite_config.sh start", status)
        self.assertIn("LinkEase Lite starting", status)

    def test_lite_runtime_sets_go_memory_limits(self):
        runtime = self.read("linkeaselite/scripts/linkeaselite_config.sh")

        self.assertIn("default_gomemlimit()", runtime)
        self.assertIn("/proc/meminfo", runtime)
        self.assertIn("MemTotal", runtime)
        self.assertIn("128MiB", runtime)
        self.assertIn("192MiB", runtime)
        self.assertIn("ulimit -v unlimited", runtime)
        self.assertIn("export GOMEMLIMIT=", runtime)
        self.assertIn("export GOGC=", runtime)
        self.assertIn("linkeaselite_gomemlimit", runtime)
        self.assertIn("linkeaselite_gogc", runtime)
        self.assertLess(runtime.index("ulimit -v unlimited"), runtime.index("start-stop-daemon"))

    def test_default_linkease_runtime_stops_lite_before_starting(self):
        default_runtime = (DEFAULT_PLUGIN / "linkease/scripts/linkease_config.sh").read_text(encoding="utf-8")

        self.assertIn("killall linkease-lite", default_runtime)
        self.assertRegex(default_runtime, r"dbus\s+set\s+linkeaselite_enable=0")

        for starter_name, started_binary in (
            ("start_standard", "start_standard_binary"),
            ("start_full", "start_full_binary"),
        ):
            starter = re.search(rf"{starter_name}\(\)\{{([\s\S]*?)\n\}}", default_runtime)
            self.assertIsNotNone(starter)
            block = starter.group(1)
            self.assertIn("stop_linkeaselite_runtime", block)
            self.assertLess(block.index("stop_linkeaselite_runtime"), block.index(started_binary))

    def test_package_contains_only_lite_runtime(self):
        package = ROOT / "linkeaselite.tar.gz"
        self.assertTrue(package.is_file(), "missing linkeaselite.tar.gz")

        with tarfile.open(package, "r:gz") as archive:
            names = set(archive.getnames())

        expected = {
            "linkeaselite/bin/linkease-lite",
            "linkeaselite/install.sh",
            "linkeaselite/uninstall.sh",
            "linkeaselite/scripts/linkeaselite_config.sh",
            "linkeaselite/scripts/linkeaselite_status.sh",
            "linkeaselite/webs/Module_linkeaselite.asp",
            "linkeaselite/res/icon-linkease.png",
            "linkeaselite/version",
        }
        self.assertTrue(expected.issubset(names))
        for forbidden_name in (
            "link-ease",
            "linkease-full",
            "linkease-media",
            "heif-converter",
            "linkease-plugins/aria2.sh",
        ):
            self.assertFalse(
                any(Path(name).name == forbidden_name or forbidden_name in name for name in names),
                f"default/full artifact included: {forbidden_name}",
            )

    def test_packaged_lite_binary_is_arm32_for_arm64_compatibility(self):
        binary = ROOT / "linkeaselite/bin/linkease-lite"
        data = binary.read_bytes()

        self.assertGreaterEqual(len(data), 20)
        self.assertEqual(data[:4], b"\x7fELF")
        self.assertEqual(data[4], 1, "linkease-lite should be ELF32")
        self.assertEqual(data[5], 1, "linkease-lite should be little-endian")
        machine = int.from_bytes(data[18:20], "little")
        self.assertEqual(machine, 40, "linkease-lite should target ARM")


if __name__ == "__main__":
    unittest.main()
