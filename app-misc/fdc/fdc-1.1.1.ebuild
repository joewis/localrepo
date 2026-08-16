# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="CLI wrapper for the USDA Food Data Central (FDC) API"
HOMEPAGE="https://fdc.nal.usda.gov/"
S="${WORKDIR}"

LICENSE="CC0-1.0"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror"

src_unpack() {
	mkdir -p "${S}"
}

src_compile() {
	:
}

src_install() {
	newbin "${FILESDIR}/fdc.py" fdc

	insinto /etc/fdc
	newins "${FILESDIR}/api_key" api_key
}

pkg_postinst() {
	elog "Food Data Central CLI installed."
	elog ""
	elog "Usage:"
	elog "  fdc search <query>"
	elog "  fdc get <fdc-id>"
	elog "  fdc get-multi <fdc-id> [<fdc-id> ...]"
	elog "  fdc list"
	elog "  fdc nutrients <fdc-id>   # nutrients per 100g table"
	elog ""
	elog "The default API key is DEMO_KEY (rate-limited)."
	elog "To use your own key, edit /etc/fdc/api_key"
	elog ""
	elog "Get a free API key at: https://fdc.nal.usda.gov/api-key-signup.html"
}
