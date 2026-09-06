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
	# Bypass pip: the 1.8.0 wheel ships a .data/data/COPYING that pip installs
	# to the real /usr/COPYING (ignoring --root), tripping the sandbox. The
	# helper unzips the wheel into site-packages and generates the wrapper.
	local whl="${S}/piper_tts-${PV}-cp39-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.manylinux_2_28_x86_64.whl"
	local sitepkg="${D}/usr/lib/python3.14/site-packages"
	python3 "${FILESDIR}/install-wheel.py" "${whl}" "${D}" "${sitepkg}" || die "wheel install failed"
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
