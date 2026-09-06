#!/usr/bin/env python3
"""Install a manylinux abi3 wheel into a Gentoo image dir, bypassing pip.

pip's --root handling of .data/data files and console-script wrappers can
write to real system paths (e.g. /usr/COPYING, /usr/bin/<script>) instead of
the image dir, tripping the portage sandbox. This script unzips the wheel
manually into the image dir and generates console-script wrappers.

Usage: install-wheel.py <wheel> <image-dir> <site-packages-dir>
"""
import configparser
import os
import shutil
import sys
import zipfile

whl, dest, sitepkg = sys.argv[1], sys.argv[2], sys.argv[3]

# Derive the dist-info name (e.g. "piper_tts-1.8.0.dist-info") and the
# data dir (e.g. "piper_tts-1.8.0.data") from the wheel.
distinfo = None
for n in zipfile.ZipFile(whl).namelist():
    if n.endswith(".dist-info/"):
        distinfo = n.rstrip("/")
        break
if distinfo is None:
    sys.exit("no .dist-info dir found in wheel")
datadir = distinfo.replace(".dist-info", ".data") + "/"

with zipfile.ZipFile(whl) as z:
    for item in z.infolist():
        name = item.filename
        # Map .data/data/* to the prefix root (usr/), everything else as-is.
        if name.startswith(datadir + "data/"):
            rel = name[len(datadir + "data/"):]
            target = os.path.join(dest, "usr", rel)
        elif name.startswith(datadir):
            continue  # scripts/headers dirs not needed for these wheels
        elif name.startswith(distinfo + "/") or not name.startswith(distinfo):
            # dist-info and the package itself go into site-packages.
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

# Generate console-script wrappers from entry_points.txt.
ep = os.path.join(sitepkg, distinfo, "entry_points.txt")
if os.path.exists(ep):
    cfg = configparser.ConfigParser()
    cfg.read(ep)
    if cfg.has_section("console_scripts"):
        bindir = os.path.join(dest, "usr", "bin")
        os.makedirs(bindir, exist_ok=True)
        for script, target in cfg.items("console_scripts"):
            # target is like "module:func" or "module:func [extra]"
            modfunc = target.split()[0]
            mod, _, func = modfunc.partition(":")
            wrapper = os.path.join(bindir, script)
            with open(wrapper, "w") as f:
                f.write("#!/usr/bin/env python3\n")
                f.write("from %s import %s\n" % (mod, func))
                f.write('if __name__ == "__main__":\n')
                f.write("\t%s()\n" % func)
            os.chmod(wrapper, 0o755)
