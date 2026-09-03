# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="ONNX Runtime — performance-focused scoring engine for ONNX models"
HOMEPAGE="https://onnxruntime.ai https://github.com/microsoft/onnxruntime"
SRC_URI="
	https://files.pythonhosted.org/packages/f9/b1/ea9ee80c0bdaa4efb13f29f8c236f3740f6655e8c092a2d119515a5a652c/onnxruntime-${PV}-cp314-cp314-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl
"
S="${WORKDIR}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="test mirror strip"

RDEPEND="dev-python/numpy"
BDEPEND="dev-python/pip"

src_unpack() {
	mkdir -p "${S}" || die
	cp "${DISTDIR}/onnxruntime-${PV}-cp314-cp314-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl" \
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
		"${S}/onnxruntime-${PV}-cp314-cp314-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl" \
		2>&1 || die "pip install failed"
}
