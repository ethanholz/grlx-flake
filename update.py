#!/usr/bin/env python3
import subprocess
import json
import sys
from pathlib import Path
from collections import OrderedDict


def main():
    outs = {}
    # data = []
    # if (Path.cwd() / "grlx.json").exists():
    #     with open("grlx.json", "r") as f:
    #         data = json.load(f)
    #         print(data)
    #         exit()
    # outs = []
    if len(sys.argv) < 2:
        raise ValueError("No version provided")
    version = sys.argv[1]
    data = {}
    if (Path.cwd() / "grlx.json").exists():
        with open("grlx.json", "r") as f:
            data = json.load(f)
            if version in data:
                print(f"Version {version} already exists")
                exit()

    systems = {
        "linux-amd64": "x86_64-linux",
        "linux-386": "i686-linux",
        "linux-arm64": "aarch64-linux",
        "darwin-amd64": "x86_64-darwin",
        "darwin-arm64": "aarch64-darwin",
    }
    item = {}
    for system in systems:
        url = f"https://github.com/gogrlx/grlx/releases/download/{version}/grlx-{version}-{system}"
        prefetch_hash_output = subprocess.run(
            ["nix-prefetch-url", f"{url}"], capture_output=True
        )
        prefetch_hash = prefetch_hash_output.stdout.decode("utf-8").strip("\n")
        print(f"Hash {prefetch_hash} for system {system}")
        res = {}
        res["hash"] = prefetch_hash
        res["url"] = url
        item[systems[system]] = res
    outs[version] = item

    with open("grlx.json", "w") as f:
        if data != {}:
            data.update(outs)
            ordered_data = OrderedDict(sorted(data.items(), reverse=True))
            json.dump(ordered_data, f, indent=2)
        else:
            json.dump(outs, f, indent=2)


if __name__ == "__main__":
    main()
