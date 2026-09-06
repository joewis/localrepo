# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Fast and local neural text-to-speech engine"
HOMEPAGE="https://github.com/OHF-Voice/piper1-gpl"
SRC_URI="
	https://files.pythonhosted.org/packages/84/81/0112a7d510911f33018dc24023d1655bb772f84a4e95fe7f0180f66bbd17/piper_tts-${PV}-cp39-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.manylinux_2_28_x86_64.whl
"
S="${WORKDIR}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="test mirror strip"

RDEPEND="
	dev-python/pathvalidate
	sci-libs/onnxruntime
"

src_unpack() {
	mkdir -p "${S}" || die
	cp "${DISTDIR}/piper_tts-${PV}-cp39-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.manylinux_2_28_x86_64.whl" \
		"${S}/" || die
}

src_compile() {
	:
}

src_install() {
	# Unzip the wheel manually into the image dir. pip's --root handling of
	# .data/data files (the 1.8.0 wheel ships a COPYING that pip installs to
	# the real /usr/COPYING, ignoring --root) trips the sandbox, so we avoid
	# pip entirely. The wheel is a self-contained manylinux abi3 wheel.
	local whl="${S}/piper_tts-${PV}-cp39-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.manylinux_2_28_x86_64.whl"
	local sitepkg="${D}/usr/lib/python3.14/site-packages"
	python3 - "${whl}" "${D}" "${sitepkg}" <<'EOF'
import sys, zipfile, os, shutil
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
EOF
	# Generate the console-script wrapper (pip normally creates this from
	# entry_points.txt; we bypass pip so create it manually).
	mkdir -p "${D}/usr/bin"
	cat > "${D}/usr/bin/piper" <<'WRAP'
#!/usr/bin/env python3
from piper.__main__ import main
if __name__ == "__main__":
    main()
WRAP
	chmod 0755 "${D}/usr/bin/piper"
}

pkg_postinst() {
	elog "Piper TTS ${PV} installed."
	elog ""
	elog "To download voice models:"
	elog "  piper --download-voices"
	elog ""
	elog "Basic usage:"
	elog '  echo "Hello world" | piper --model en_US-lessac-medium --output-file hello.wav'
}
