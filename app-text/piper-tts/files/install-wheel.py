#!/usr/bin/env python3
"""Install a manylinux abi3 wheel into a Gentoo image dir, bypassing pip.

pip's --root handling of .data/data files (e.g. a COPYING that pip installs
to the real /usr/COPYING, ignoring --root) trips the portage sandbox. This
script unzips the wheel manually into the image dir instead.

Usage: install-wheel.py <wheel> <image-dir> <site-packages-dir>
"""
import os
import shutil
import sys
import zipfile

whl, dest, sitepkg = sys.argv[1], sys.argv[2], sys.argv[3]

with zipfile.ZipFile(whl) as z:
    for item in z.infolist():
        name = item.filename
        # Skip the .data/data/COPYING that would land at the prefix root.
        if name == "piper_tts-1.8.0.data/data/COPYING":
            continue
        # Map .data/data/* to the prefix root (usr/), everything else as-is.
        if name.startswith("piper_tts-1.8.0.data/data/"):
            rel = name[len("piper_tts-1.8.0.data/data/"):]
            target = os.path.join(dest, "usr", rel)
        elif name.startswith("piper_tts-1.8.0.data/"):
            continue  # scripts/headers dirs not needed for this wheel
        elif name.startswith("piper/") or name.startswith("piper_tts-1.8.0.dist-info/"):
            # Pure-python package + dist-info go into site-packages.
            target = os.path.join(sitepkg, name)
        else:
            target = os.path.join(dest, name)
        if item.is_dir():
            os.makedirs(target, exist_ok=True)
            continue
        os.makedirs(os.path.dirname(target), exist_ok=True)
        with z.open(item) as src, open(target, "wb") as out:
            shutil.copyfileobj(src, out)
        os.chmod(target, item.external_attr >> 16 & 0o777 or 0o644)

# Generate the console-script wrapper (pip normally creates this from
# entry_points.txt; we bypass pip so create it manually).
bindir = os.path.join(dest, "usr", "bin")
os.makedirs(bindir, exist_ok=True)
wrapper = os.path.join(bindir, "piper")
with open(wrapper, "w") as f:
    f.write("#!/usr/bin/env python3\n")
    f.write("from piper.__main__ import main\n")
    f.write('if __name__ == "__main__":\n')
    f.write("\tmain()\n")
os.chmod(wrapper, 0o755)
