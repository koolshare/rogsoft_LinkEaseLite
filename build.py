#!/usr/bin/env python3

import hashlib
import json
import tarfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent
PACKAGE_FILES = (
    "linkeaselite/bin/linkease-lite",
    "linkeaselite/install.sh",
    "linkeaselite/uninstall.sh",
    "linkeaselite/scripts/linkeaselite_config.sh",
    "linkeaselite/scripts/linkeaselite_status.sh",
    "linkeaselite/webs/Module_linkeaselite.asp",
    "linkeaselite/res/icon-linkease.png",
    "linkeaselite/version",
)


def validate_module_name(module):
    module = str(module or "").strip()
    if not module or module in (".", "..") or "/" in module or "\\" in module:
        raise ValueError("module must be a simple directory name")
    return module


def read_config(root):
    with (root / "config.json.js").open(encoding="utf-8") as config_file:
        config = json.load(config_file)
    config["module"] = validate_module_name(config.get("module"))
    return config


def md5sum(path):
    return hashlib.md5(path.read_bytes()).hexdigest()


def build_module(root=None):
    root = Path(root or ROOT)
    config = read_config(root)
    module = config["module"]
    if module != "linkeaselite":
        raise ValueError("module must be linkeaselite")

    for relative_path in PACKAGE_FILES:
        source = root / relative_path
        if not source.is_file():
            raise FileNotFoundError("missing package file: %s" % source)

    package = root / "linkeaselite.tar.gz"
    if package.exists():
        package.unlink()
    with tarfile.open(package, "w:gz") as archive:
        for relative_path in PACKAGE_FILES:
            archive.add(root / relative_path, arcname=relative_path)

    config["package"] = package.name
    config["md5"] = md5sum(package)
    with (root / "config.json.js").open("w", encoding="utf-8") as config_file:
        json.dump(config, config_file, ensure_ascii=False, indent=4, sort_keys=True)
        config_file.write("\n")
    return config


if __name__ == "__main__":
    build_module()
