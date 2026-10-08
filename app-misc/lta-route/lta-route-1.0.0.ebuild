# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Plan Singapore bus routes via the LTA DataMall API"
HOMEPAGE="https://datamall.lta.gov.sg/"
S="${WORKDIR}"

LICENSE="CC0-1.0"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror"

# No build step: this is a single stdlib-only Python script installed from
# files/, run through the system interpreter (/usr/bin/env python3) — hence no
# RDEPEND, matching app-misc/fdc on this box. The credential is NOT baked in —
# LTA_DATAMALL_API_KEY arrives in the environment, which is how the MCP gateway
# injects it for the lta-route backend. sys.path also reaches the shared
# secret_source helper that the gateway's backend servers use, so an
# interactive shell keeps the dotenv fallback without a second copy of the
# lookup contract living here.

src_unpack() {
	mkdir -p "${S}"
}

src_compile() {
	:
}

src_install() {
	newbin "${FILESDIR}/lta-route.py" lta-route
}

pkg_postinst() {
	elog "lta-route ${PV} installed. Usage:"
	elog ""
	elog "  lta-route --from \"1.370485,103.967141\" --to \"68 Bedok South Avenue 3\""
	elog "  lta-route --from work --to home"
	elog ""
	elog "LTA_DATAMALL_API_KEY is read from the environment. The MCP gateway"
	elog "injects it for the lta-route backend; an interactive shell needs it"
	elog "exported, or present in the shared ~/.hermes/.env fallback."
	elog ""
	elog "Named locations (work, home) are read from"
	elog "\${XDG_CONFIG_HOME:-~/.config}/lta-route/locations.json."
}
