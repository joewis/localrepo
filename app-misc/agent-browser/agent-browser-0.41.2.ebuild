# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Browser automation CLI for AI agents (prebuilt native binary)"
HOMEPAGE="https://github.com/vercel-labs/agent-browser"
SRC_URI="https://github.com/vercel-labs/agent-browser/releases/download/v${PV}/agent-browser-linux-x64 -> ${P}-linux-x64"
S="${WORKDIR}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="-* ~amd64"
RESTRICT="mirror strip"
QA_PREBUILT="*"

# Upstream ships a self-contained ELF built from cli/ (Rust); it links only
# against glibc, so there is no RDEPEND beyond @system. A Chrome/Chromium
# browser is required at runtime but is deliberately not a hard dependency:
# the CLI reuses any installed Chrome and otherwise fetches Chrome for
# Testing into ~/.agent-browser (see pkg_postinst).

src_unpack() {
	mkdir -p "${S}" || die
	cp "${DISTDIR}/${P}-linux-x64" "${S}/${PN}" || die
	chmod 0755 "${S}/${PN}" || die
}

src_compile() {
	: # prebuilt binary, nothing to compile
}

src_install() {
	dobin "${S}/${PN}"
}

pkg_postinst() {
	elog "${PN} ${PV} installed."
	elog ""
	elog "A Chrome or Chromium browser is required at runtime. The CLI detects"
	elog "existing installations; if none is found, fetch Google's Chrome for"
	elog "Testing build (this is a runtime download, not package-managed):"
	elog "    agent-browser install"
	elog ""
	elog "That downloads into \${HOME}/.agent-browser and is roughly 390 MB."
	elog ""
	elog "Sessions and browser state also live under \${HOME}/.agent-browser."
}
