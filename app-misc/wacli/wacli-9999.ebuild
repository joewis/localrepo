# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module git-r3

DESCRIPTION="WhatsApp CLI: sync, search, send"
HOMEPAGE="https://github.com/openclaw/wacli"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

BDEPEND=">=dev-lang/go-1.25.0"

EGIT_REPO_URI="https://github.com/openclaw/wacli.git"

src_unpack() {
	git-r3_src_unpack
	go-module_live_vendor
}

src_compile() {
	# Override the Portage GOPROXY to fetch directly from upstream
	export GOPROXY="https://proxy.golang.org,direct"
	export GONOSUMCHECK=*
	export GONOSUMDB=*
	ego build -mod=vendor -o "${PN}" ./cmd/wacli
}

src_install() {
	dobin wacli
	dodoc README.md
}
