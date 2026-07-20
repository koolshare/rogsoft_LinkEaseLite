import importlib.util
import json
import shutil
import tarfile
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class BuildScriptContractTest(unittest.TestCase):
    def load_build_module(self):
        build_path = ROOT / "build.py"
        self.assertTrue(build_path.is_file(), "missing build.py")
        spec = importlib.util.spec_from_file_location("linkeaselite_build", build_path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def test_build_script_targets_lite_package_and_binary(self):
        build_path = ROOT / "build.py"
        self.assertTrue(build_path.is_file(), "missing build.py")
        build = build_path.read_text(encoding="utf-8")

        self.assertIn("linkeaselite.tar.gz", build)
        self.assertIn("linkeaselite/bin/linkease-lite", build)
        self.assertNotIn("linkease-full-binary", build)
        self.assertNotIn("full_artifact_url", build)
        self.assertNotIn("linkease-media", build)
        self.assertNotIn("heif-converter", build)
        self.assertNotIn("linkease-plugins", build)

    def test_build_script_does_not_stage_default_or_full_binaries(self):
        module = self.load_build_module()

        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            shutil.copytree(ROOT / "linkeaselite", root / "linkeaselite")
            shutil.copy2(ROOT / "config.json.js", root / "config.json.js")
            bin_dir = root / "linkeaselite" / "bin"
            bin_dir.mkdir(exist_ok=True)
            (bin_dir / "linkease-lite").write_text("#!/bin/sh\n", encoding="utf-8")
            (bin_dir / "linkease-lite").chmod(0o755)

            for forbidden in ("link-ease", "linkease-full", "linkease-media", "heif-converter"):
                (bin_dir / forbidden).write_text("must not be packaged\n", encoding="utf-8")

            conf = module.build_module(root=root)

            self.assertEqual(conf["module"], "linkeaselite")
            package = root / "linkeaselite.tar.gz"
            self.assertTrue(package.is_file())
            with tarfile.open(package, "r:gz") as archive:
                names = set(archive.getnames())

            self.assertIn("linkeaselite/bin/linkease-lite", names)
            for forbidden in (
                "linkeaselite/bin/link-ease",
                "linkeaselite/bin/linkease-full",
                "linkeaselite/bin/linkease-media",
                "linkeaselite/bin/heif-converter",
                "linkeaselite/bin/linkease-plugins/aria2.sh",
            ):
                self.assertNotIn(forbidden, names)

    def test_build_module_rejects_path_traversal_module_name(self):
        module = self.load_build_module()

        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            (root / "config.json.js").write_text(
                json.dumps({"module": "../escape", "version": "1.0.0"}),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "module must be a simple directory name"):
                module.build_module(root=root)


if __name__ == "__main__":
    unittest.main()
