# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

DESCRIPTION="Ollama LLM runner - version-pinned upstream installation"
HOMEPAGE="https://github.com/ollama/ollama"
SRC_URI="https://github.com/ollama/ollama/releases/download/v${PV}/install.sh -> ${P}-install.sh"
S="${WORKDIR}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror strip"

RDEPEND="
	app-arch/zstd
	net-misc/curl
	sys-apps/systemd
"

src_unpack() {
	mkdir -p "${S}" || die
}

src_compile() {
	:
}

src_install() {
	exeinto /usr/libexec
	doexe "${FILESDIR}/ollama-update"

	systemd_dounit "${FILESDIR}/ollama.service"
}

pkg_postinst() {
	# WHY a runner and not a normal ebuild: Ollama ships a precompiled bundle
	# whose own installer defines the on-disk layout (binary plus a large
	# lib/ollama tree of ggml/llama shared objects). Reproducing that inside
	# src_install would mean re-implementing upstream's bundling and drifting
	# from it, so the package owns the two files Portage can own -- this runner
	# and the systemd unit -- and delegates the payload to upstream's installer.
	#
	# The version is PINNED to ${PV}. The previous live (9999) ebuild curled the
	# rolling ollama.com/install.sh with no version argument, so every re-emerge
	# installed whatever was published that day. That is not reproducible: a bad
	# release could not be avoided or reverted by re-emerging, which is exactly
	# the failure mode that made past Ollama updates unreliable. Passing
	# OLLAMA_VERSION makes a version bump a real bump and makes re-emerging the
	# same version reinstall the same release.
	# No `die` here: by pkg_postinst the package's own files are already merged,
	# so aborting would report a failure that did not happen and leave no hint
	# how to recover. A failed payload fetch is recoverable by re-running the
	# runner, so say that instead.
	if ! OLLAMA_VERSION=${PV} /usr/libexec/ollama-update; then
		ewarn "ollama-update failed -- Ollama may not be installed at v${PV}."
		ewarn "Re-run it with:  OLLAMA_VERSION=${PV} /usr/libexec/ollama-update"
	fi

	if ! systemctl is-enabled ollama.service &>/dev/null; then
		elog ""
		elog "To enable Ollama on boot:"
		elog "  sudo systemctl enable --now ollama.service"
	fi
}
