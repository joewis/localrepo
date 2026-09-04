# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Single-port MCP multiplexing gateway with on-demand tool discovery"
HOMEPAGE="https://github.com/MikkoParkkola/mcp-gateway"
SRC_URI="https://github.com/MikkoParkkola/mcp-gateway/releases/download/v${PV}/${PN}-linux-x86_64"
S="${WORKDIR}"

LICENSE="PolyForm-Noncommercial-1.0.0"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror strip bindist"

src_unpack() {
	mkdir -p "${S}"
}

src_compile() {
	: # precompiled binary; nothing to compile
}

src_install() {
	newbin "${DISTDIR}/${PN}-linux-x86_64" "${PN}"
}
