import json
import re
import tarfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


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

    def test_install_and_uninstall_use_only_lite_state(self):
        install = self.read("linkeaselite/install.sh")
        uninstall = self.read("linkeaselite/uninstall.sh")
        combined = install + "\n" + uninstall

        self.assertRegex(install, r"module\s*=\s*\$\{DIR##\*/\}")
        for key in (
            "linkeaselite_enable",
            "linkeaselite_version",
            "linkeaselite_data_disk",
            "linkeaselite_data_root_parent",
            "linkeaselite_data_root",
            "softcenter_module_linkeaselite_",
        ):
            self.assertIn(key, combined)

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
        for forbidden_text in forbidden:
            self.assertNotIn(forbidden_text, combined)

    def test_lite_runtime_enforces_mutual_exclusion(self):
        runtime = self.read("linkeaselite/scripts/linkeaselite_config.sh")
        status = self.read("linkeaselite/scripts/linkeaselite_status.sh")

        self.assertIn("killall link-ease", runtime)
        self.assertIn("killall linkease-full", runtime)
        self.assertIn("killall linkease-lite", runtime)
        self.assertRegex(runtime, r"dbus\s+set\s+linkease_enable=0")
        self.assertIn("/koolshare/bin/linkease-lite", runtime)
        self.assertIn("LINKEASE_SIMPLE=1", runtime)
        self.assertRegex(status, r"pidof\s+linkease-lite")

    def test_package_contains_only_lite_runtime(self):
        package = ROOT / "linkeaselite.tar.gz"
        self.assertTrue(package.is_file(), "missing linkeaselite.tar.gz")

        with tarfile.open(package, "r:gz") as archive:
            names = set(archive.getnames())

        self.assertIn("linkeaselite/bin/linkease-lite", names)
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


if __name__ == "__main__":
    unittest.main()
