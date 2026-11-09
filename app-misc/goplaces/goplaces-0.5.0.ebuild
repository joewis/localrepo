# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="Modern Google Places CLI and Go client for the Places API (New) and Routes API"
HOMEPAGE="https://github.com/openclaw/goplaces"
SRC_URI="https://github.com/openclaw/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

# Generated from go.sum (v${PV})
EGO_SUM=(
	"github.com/alecthomas/assert/v2 v2.11.0"
	"github.com/alecthomas/assert/v2 v2.11.0/go.mod"
	"github.com/alecthomas/kong v1.17.0"
	"github.com/alecthomas/kong v1.17.0/go.mod"
	"github.com/alecthomas/repr v0.5.2"
	"github.com/alecthomas/repr v0.5.2/go.mod"
	"github.com/hexops/gotextdiff v1.0.3"
	"github.com/hexops/gotextdiff v1.0.3/go.mod"
)

go-module_set_globals

SRC_URI+=" ${EGO_SUM_SRC_URI}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

BDEPEND=">=dev-lang/go-1.26"

src_compile() {
	# Upstream stamps Version via GoReleaser ldflags; without this the CLI
	# reports "dev" even when built from a release tarball.
	ego build -ldflags "-s -w -X github.com/steipete/goplaces/internal/cli.Version=${PV}" \
		-o "${PN}" ./cmd/goplaces
}

src_install() {
	dobin "${PN}"
	dodoc README.md
}
