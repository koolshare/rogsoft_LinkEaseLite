import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class BuildScriptContractTest(unittest.TestCase):
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
        build_path = ROOT / "build.py"
        self.assertTrue(build_path.is_file(), "missing build.py")
        build = build_path.read_text(encoding="utf-8")

        forbidden_stage_patterns = (
            r"(?:copy|stage|extract).*link-ease",
            r"(?:copy|stage|extract).*linkease-full",
            r"(?:copy|stage|extract).*linkease-media",
            r"(?:copy|stage|extract).*heif-converter",
        )
        for pattern in forbidden_stage_patterns:
            self.assertIsNone(re.search(pattern, build, re.IGNORECASE | re.DOTALL))


if __name__ == "__main__":
    unittest.main()
