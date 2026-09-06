# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="ONNX Runtime — performance-focused scoring engine for ONNX models"
HOMEPAGE="https://onnxruntime.ai https://github.com/microsoft/onnxruntime"
SRC_URI="
	https://files.pythonhosted.org/packages/65/54/9f197c578d3d3d7bea16971e233e5483981228eec73748585cf7b5933403/onnxruntime-${PV}-cp314-cp314-manylinux_2_28_x86_64.whl
"
S="${WORKDIR}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="test mirror strip"

RDEPEND="dev-python/numpy"

src_unpack() {
	mkdir -p "${S}" || die
	cp "${DISTDIR}/onnxruntime-${PV}-cp314-cp314-manylinux_2_28_x86_64.whl" \
		"${S}/" || die
}

src_compile() {
	:
}

src_install() {
	# Bypass pip: the wheel's console-script wrapper (onnxruntime_test) would
	# be written to the real /usr/bin, tripping the sandbox. The helper unzips
	# the wheel into site-packages and generates the wrapper.
	local whl="${S}/onnxruntime-${PV}-cp314-cp314-manylinux_2_28_x86_64.whl"
	local sitepkg="${D}/usr/lib/python3.14/site-packages"
	python3 "${FILESDIR}/install-wheel.py" "${whl}" "${D}" "${sitepkg}" || die "wheel install failed"
}
