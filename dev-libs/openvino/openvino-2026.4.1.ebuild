# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# OpenVINO ships no source release we can build in a sandbox (it needs a full
# oneDNN/TBB/Clang toolchain and hours of compile time). The PyPI wheel is the
# vendor's own binary distribution and - unlike the 700 MB Intel toolkit - is
# exactly what the C++ API needs: runtime libraries, headers and the CMake
# package config, in one 59 MB archive.
#
# Layout: the wheel's openvino/ tree is installed whole to ${EPREFIX}/usr/$(get_libdir)/openvino.
# OpenVINOConfig.cmake derives its prefix as CMAKE_CURRENT_LIST_DIR/../../ and then
# appends /openvino/{libs,include}, so this layout resolves correctly at the new
# prefix without patching a single generated file.
#
# Consumers: pass -DOpenVINO_DIR=${EPREFIX}/usr/$(get_libdir)/openvino/cmake.

DESCRIPTION="OpenVINO inference runtime (binary: C++ libs, headers, CMake config)"
HOMEPAGE="https://github.com/openvinotoolkit/openvino"
SRC_URI="https://files.pythonhosted.org/packages/77/cf/830aff97404d73b8ada3ba3f02a626089a384299322cb94b52c37eaebd18/openvino-${PV}-22982-cp314-cp314-manylinux_2_28_x86_64.whl -> ${P}.whl"
S="${WORKDIR}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

# strip: these are vendor-built shared libraries; touching them is how you get
# a plugin that loads but cannot find its own symbols.
RESTRICT="mirror strip"
QA_PREBUILT="*"

BDEPEND="app-arch/unzip"

src_unpack() {
	unzip -q "${DISTDIR}/${P}.whl" -d "${WORKDIR}/whl" || die
}

src_install() {
	local ovdir="/usr/$(get_libdir)/openvino"

	insinto "${ovdir}"
	doins -r "${WORKDIR}/whl/openvino/libs" || die
	doins -r "${WORKDIR}/whl/openvino/include" || die
	doins -r "${WORKDIR}/whl/openvino/cmake" || die

	# libwhisper (and any other consumer) gets DT_NEEDED=libopenvino.so.2641.
	# Because the library lives in .../openvino/libs rather than a default
	# search path, both the link-time linker and the runtime loader need the
	# soname visible in <prefix>/usr/$(get_libdir). Symlink the OpenVINO
	# libraries only - hwloc and TBB stay inside the private tree so they
	# cannot shadow a system copy.
	local lib
	for lib in "${D}${ovdir}"/libs/libopenvino*.so*; do
		[[ -e ${lib} ]] || continue
		dosym "${ovdir}/libs/${lib##*/}" "/usr/$(get_libdir)/${lib##*/}"
	done

	# The wheel carries versioned SONAMEs only (libopenvino.so.2641). CMake
	# targets reference the full filenames, but anything linking the
	# conventional way (-lopenvino) needs the unversioned link.
	local so soname
	for so in "${D}${ovdir}"/libs/*.so.*; do
		soname=${so##*/}
		case ${soname} in
			*.so.*) ;;
			*) continue ;;
		esac
		local base=${soname%%.so.*}
		[[ -e "${D}${ovdir}/libs/${base}.so" ]] || dosym "${soname}" "${ovdir}/libs/${base}.so"
	done
}

pkg_postinst() {
	elog "OpenVINO ${PV} installed at ${EPREFIX}/usr/$(get_libdir)/openvino"
	elog "For CMake consumers: -DOpenVINO_DIR=${EPREFIX}/usr/$(get_libdir)/openvino/cmake"
	elog
	elog "Only the C++ runtime is installed (libs, headers, CMake config)."
	elog "The wheel's Python bindings are intentionally not installed; use a venv"
	elog "with 'pip install openvino' if a Python consumer needs them."
}
