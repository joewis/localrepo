# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Google CLI for Gmail, Calendar, Drive, Docs, Sheets and more"
HOMEPAGE="https://gogcli.sh/ https://github.com/openclaw/gogcli"
SRC_URI="https://github.com/openclaw/gogcli/releases/download/v${PV}/gogcli_${PV}_linux_amd64.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="-* ~amd64"

S="${WORKDIR}"

src_install() {
	dobin gog
	einstalldocs
}
