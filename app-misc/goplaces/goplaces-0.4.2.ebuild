# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="Modern Google Places CLI and Go client for the Places API (New) and Routes API"
HOMEPAGE="https://github.com/openclaw/goplaces"
SRC_URI="file:///var/cache/distfiles/${P}-vendored.tar.xz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

BDEPEND=">=dev-lang/go-1.25.10"

src_compile() {
	ego build -mod=vendor -o goplaces ./cmd/goplaces
}

src_install() {
	dobin goplaces
	dodoc README.md
}
