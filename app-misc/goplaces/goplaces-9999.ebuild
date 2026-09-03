# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module git-r3

DESCRIPTION="Modern Google Places CLI and Go client for the Places API (New) and Routes API"
HOMEPAGE="https://github.com/openclaw/goplaces"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

BDEPEND=">=dev-lang/go-1.25.0"

EGIT_REPO_URI="https://github.com/openclaw/goplaces.git"

src_unpack() {
	git-r3_src_unpack
	go-module_live_vendor
}

src_compile() {
	export GOPROXY="https://proxy.golang.org,direct"
	export GONOSUMCHECK=*
	export GONOSUMDB=*
	ego build -mod=vendor -o "${PN}" ./cmd/goplaces
}

src_install() {
	dobin goplaces
	dodoc README.md
}
