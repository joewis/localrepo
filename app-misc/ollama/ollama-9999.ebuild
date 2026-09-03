# Copyright 2026-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit systemd

DESCRIPTION="Ollama LLM runner — latest version (live ebuild)"
HOMEPAGE="https://ollama.com"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
S="${WORKDIR}"
RESTRICT="mirror"
RDEPEND="net-misc/curl sys-apps/systemd"

src_unpack() {
	mkdir -p "${S}"
}

src_compile() { :; }

src_install() {
	exeinto /usr/libexec
	doexe "${FILESDIR}/ollama-update"
	systemd_dounit "${FILESDIR}/ollama.service"
}

pkg_postinst() {
	/usr/libexec/ollama-update
	if ! systemctl is-enabled ollama.service &>/dev/null; then
		elog ""
		elog "To enable Ollama on boot:"
		elog "  sudo systemctl enable --now ollama.service"
	fi
}
