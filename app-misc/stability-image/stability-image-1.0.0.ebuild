# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Text-to-image CLI for the Stability AI API"
HOMEPAGE="https://platform.stability.ai/"
S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror"

# No build step: a single stdlib-only Python script installed from files/, run
# through the system interpreter (/usr/bin/env python3) — hence no RDEPEND,
# matching app-misc/fdc on this box. The credential is NOT baked in —
# STABILITY_API_KEY arrives in the environment, which is how the MCP gateway
# injects it for the stability-image backend. sys.path also reaches the shared
# secret_source helper the gateway's backend servers use, so an interactive
# shell keeps the dotenv fallback without a second copy of the lookup contract
# living here.

src_unpack() {
	mkdir -p "${S}"
}

src_compile() {
	:
}

src_install() {
	newbin "${FILESDIR}/stability-image.py" stability-image
}

pkg_postinst() {
	elog "stability-image ${PV} installed. Usage:"
	elog ""
	elog "  stability-image \"a red fox in snow\" --model core --size 1024x1024"
	elog "  stability-image \"...\" --out /path/to/file.png --seed 42"
	elog ""
	elog "STABILITY_API_KEY is read from the environment. The MCP gateway injects"
	elog "it for the stability-image backend; an interactive shell needs it"
	elog "exported, or present in the shared ~/.hermes/.env fallback."
	elog ""
	elog "With no --out, output goes to /var/lib/mcp-gateway/output/ (the gateway's"
	elog "own writable directory) rather than the caller's working directory."
}
