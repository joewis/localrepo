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

BDEPEND="dev-python/pip"

src_unpack() {
	mkdir -p "${S}" || die
	cp "${DISTDIR}/piper_tts-${PV}-cp39-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.manylinux_2_28_x86_64.whl" \
		"${S}/" || die
}

src_compile() {
	:
}

src_install() {
	pip install \
		--no-build-isolation \
		--no-deps \
		--no-index \
		--progress-bar off \
		--root="${D}" \
		--prefix="${EPREFIX}/usr" \
		"${S}/piper_tts-${PV}-cp39-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.manylinux_2_28_x86_64.whl" \
		2>&1 || die "pip install failed"
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
