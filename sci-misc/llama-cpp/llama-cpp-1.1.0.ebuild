# Copyright 2024-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="LLM inference in C/C++ — llama.cpp"
HOMEPAGE="https://github.com/ggml-org/llama.cpp"
SRC_URI="https://github.com/ggml-org/llama.cpp/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/llama.cpp-${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

IUSE="
	cuda
	curl
	examples
	openblas
	opencl
	openmp
	openssl
	rpc
	server
	tests
	tools
	vulkan
"

REQUIRED_USE="
	examples? ( tools )
"

CDEPEND="
	cuda? ( >=dev-util/nvidia-cuda-toolkit-11:= )
	curl? ( net-misc/curl:= )
	openblas? ( >=sci-libs/openblas-0.3.27:= )
	opencl? ( virtual/opencl )
	openmp? ( llvm-core/clang:* )
	openssl? ( dev-libs/openssl:= )
	vulkan? ( media-libs/vulkan-loader )
"

DEPEND="
	${CDEPEND}
	cuda? ( dev-util/nvidia-cuda-toolkit )
	opencl? ( dev-util/opencl-headers )
	vulkan? ( dev-util/vulkan-headers )
"

RDEPEND="
	${CDEPEND}
"

BDEPEND="
	virtual/pkgconfig
"

src_configure() {
	local mycmakeargs=(
		# Build targets
		-DLLAMA_BUILD_SERVER=$(usex server)
		-DLLAMA_BUILD_EXAMPLES=$(usex examples)
		-DLLAMA_BUILD_TOOLS=$(usex tools)
		-DLLAMA_BUILD_TESTS=$(usex tests)
		-DLLAMA_BUILD_COMMON=$(usex examples ON $(usex tools ON $(usex server ON OFF)))

		# CPU features — don't use -march=native (portability)
		-DGGML_NATIVE=OFF

		# OpenMP
		-DGGML_OPENMP=$(usex openmp)

		# GPU backends
		-DGGML_CUDA=$(usex cuda)
		-DGGML_OPENCL=$(usex opencl)
		-DGGML_VULKAN=$(usex vulkan)

		# BLAS
		-DGGML_BLAS=$(usex openblas)
		-DGGML_BLAS_VENDOR=$(usex openblas OpenBLAS)

		# RPC
		-DGGML_RPC=$(usex rpc)

		# Network / crypto
		-DLLAMA_CURL=$(usex curl)
		-DLLAMA_OPENSSL=$(usex openssl)

		# Skip RPATH fiddling for Gentoo
		-DCMAKE_SKIP_BUILD_RPATH=ON
	)

	if use cuda; then
		addpredict /dev/nvidiactl
		addpredict /dev/nvidia-uvm
		addpredict /dev/nvidia-modeset
		addpredict /proc/driver/nvidia/params
	fi

	cmake_src_configure
}

src_install() {
	cmake_src_install

	# Install headers for downstream consumers
	insinto /usr/include/llama.cpp
	doins -r "${S}"/include/.
}

pkg_postinst() {
	if use cuda; then
		elog "CUDA backend enabled. Make sure nvidia-drivers are properly configured."
	fi
	if use vulkan; then
		elog "Vulkan backend enabled. Make sure you have the proper Vulkan drivers installed."
	fi
	elog ""
	elog "llama.cpp provides several tools:"
	elog "  llama-cli       — interactive chat CLI"
	elog "  llama-server    — OpenAI-compatible HTTP server"
	elog "  llama-bench     — benchmark tool"
	elog "  llama-quantize  — model quantization tool"
	elog "  llama-perplexity — perplexity evaluation"
	elog ""
	elog "For quick start:"
	elog "  llama-cli -hf ggml-org/gemma-3-1b-it-GGUF"
	if use server; then
		elog ""
		elog "llama-server was built without the embedded Web UI (the build"
		elog "sandbox has no network access). To add the UI, download the"
		elog "pre-built assets from a llama.cpp release page:"
		elog "  https://github.com/ggml-org/llama.cpp/releases"
		elog ""
		elog "Look for the 'llama-ui-<version>.tar.gz' asset attached to"
		elog "the release matching your installed version (v${PV})."
		elog ""
		elog "Extract it and serve with --path:"
		elog "  mkdir -p /usr/share/llama.cpp/ui"
		elog "  tar xzf llama-ui-*.tar.gz -C /usr/share/llama.cpp/ui"
		elog "  llama-server --path /usr/share/llama.cpp/ui"
	fi
}
