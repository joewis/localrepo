# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="CLI tool to manage GPU pods and serverless endpoints on RunPod"
HOMEPAGE="https://github.com/runpod/runpodctl"
SRC_URI="https://github.com/runpod/runpodctl/releases/download/v${PV}/runpodctl-linux-amd64.tar.gz"
S="${WORKDIR}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror strip"

src_unpack() {
	default
	# Upstream archive extracts a flat runpodctl binary at top level; rename so
	# the install phase is unambiguous and einstalldocs doesn't try to install it.
	mv runpodctl runpodctl-bin 2>/dev/null || die "runpodctl binary not found in archive"
}

src_install() {
	newbin runpodctl-bin runpodctl
	dodoc LICENSE README.md CHANGELOG.md
}

pkg_postinst() {
	elog "runpodctl ${PV} installed."
	elog ""
	elog "Quick start:"
	elog "  1. Get a RunPod API key:    https://www.runpod.io/console/user/settings"
	elog "  2. Configure:               runpodctl config --apiKey=<YOUR_KEY>"
	elog "  3. List pods:               runpodctl pod list"
	elog ""
	elog "Commands follow a noun-verb pattern: runpodctl <noun> <verb>"
	elog "File transfer (no API key) uses 'send' / 'receive'."
}
