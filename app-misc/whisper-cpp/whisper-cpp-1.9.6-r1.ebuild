# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="Whisper speech-to-text inference engine (C++ port of OpenAI's Whisper)"
HOMEPAGE="https://github.com/ggml-org/whisper.cpp"
SRC_URI="https://github.com/ggml-org/whisper.cpp/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/whisper.cpp-${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="openmp tests"

# ggml has exactly one provider on this box: sci-misc/llama-cpp installs
# libggml*.so.1 and the ggml CMake package config. whisper links against that
# instead of shipping a second copy - two owners of /usr/lib64/libggml*.so.1
# cannot merge (file collision), and a privately bundled ggml would drift from
# the provider's ABI on every llama-cpp bump.
DEPEND="
	sci-misc/llama-cpp"
RDEPEND="${DEPEND}"

src_configure() {
	local mycmakeargs=(
		-DGGML_NATIVE=OFF
		-DCMAKE_SKIP_BUILD_RPATH=ON
		-DWHISPER_BUILD_EXAMPLES=ON
		-DWHISPER_BUILD_TESTS=$(usex tests ON OFF)
		-DWHISPER_USE_SYSTEM_GGML=ON
		-DBUILD_SHARED_LIBS=ON
		-DGGML_OPENMP=$(usex openmp ON OFF)
	)
	cmake_src_configure
}

src_install() {
	cmake_src_install
	# Defensive: with WHISPER_USE_SYSTEM_GGML the upstream tree should no
	# longer install ggml's CMake config, but if that regresses we must not
	# create a second owner of the path llama-cpp provides.
	rm -rf "${ED}/usr/$(get_libdir)/cmake/ggml" || die
	# CMake install() rules already place libwhisper, libparakeet,
	# whisper-cli, whisper-server and quantize helpers into standard
	# locations. Nothing extra needed beyond docs.
	dodoc README.md
	# Install the shared transcription wrapper (routes to the whisper-server
	# daemon for the resident model, or one-shot whisper-cli otherwise).
	newbin "${FILESDIR}/whisper" whisper
}
