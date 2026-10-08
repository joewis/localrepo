# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_14 )
inherit python-single-r1

DESCRIPTION="Agent-driven API discovery: a local catalog with keyword and semantic search"
HOMEPAGE="https://github.com/joewis/apinav"
SRC_URI="
	https://github.com/joewis/apinav/archive/refs/tags/v${PV}.tar.gz
		-> ${P}.tar.gz
	https://github.com/joewis/apinav/releases/download/v${PV}/apinav-deps-${PV}.tar.gz
"

# S is explicit and BOTH archives are extracted by hand in src_unpack: the
# dependency bundle has no single top-level directory, so relying on Portage's
# unpack heuristics for it would make the wheel location depend on the
# tarball's shape. The code tarball extracts to the upstream repo name.
S="${WORKDIR}/src/apinav-${PV}"

# apinav's own code is MIT. The bundled wheels it installs carry their own
# licences (numpy alone is BSD-3-Clause AND 0BSD AND MIT AND Zlib AND CC0-1.0)
# and are redistributed unmodified as downloaded from PyPI; the bundle ships a
# licenses.txt naming every one of them.
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="${PYTHON_DEPS}"
BDEPEND="${PYTHON_DEPS}"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

src_unpack() {
	mkdir -p "${WORKDIR}/src" "${WORKDIR}/wheels" || die
	tar xzf "${DISTDIR}/${P}.tar.gz" -C "${WORKDIR}/src" || die
	# --strip-components: the dependency bundle is packed with a single
	# top-level directory, so the wheels land one level down and pip's
	# --find-links would not see them. Flatten it into ${WORKDIR}/wheels.
	tar xzf "${DISTDIR}/apinav-deps-${PV}.tar.gz" -C "${WORKDIR}/wheels" \
		--strip-components=1 || die
}

src_compile() {
	:
}

src_install() {
	local venv="${ED}/opt/mcp/apinav-venv"

	# An isolated venv rather than site-packages: apinav's runtime dependency
	# `mcp` is not in ::gentoo and its transitive tree is 29 wheels deep, so the
	# wheels are bundled and installed offline from a pinned bundle instead of
	# being packaged one by one. Same shape as app-misc/xiaomi-devices.
	# The bundle holds wheels only, so no build tooling is needed: nothing here
	# compiles from an sdist.
	"${EPYTHON}" -m venv "${venv}" || die "could not create the venv"

	"${venv}"/bin/pip install --no-index --no-build-isolation \
		--find-links "${WORKDIR}/wheels" \
		mcp numpy pyyaml \
		|| die "could not install the dependency wheels into the venv"

	# Keep the licence manifest visible: it names every bundled component.
	if [[ -f "${WORKDIR}/wheels/licenses.txt" ]]; then
		insinto /opt/mcp/apinav
		doins "${WORKDIR}/wheels/licenses.txt"
	fi

	# The code directory is root-owned and read-only at runtime. State (the
	# catalog and the embedding cache) is deliberately NOT installed here: it is
	# written by whichever account runs the tool, pointed at a writable tree via
	# APINAV_STATE_DIR. A writable code directory would let the account that runs
	# the tool rewrite the tool.
	insinto /opt/mcp/apinav
	doins apinav.py apinav_mcp_server.py config.py config.yaml \
		embed_matrix.py ingest.py schema.py sources.py spam.py \
		requirements.txt README.md LICENSE
	insinto /opt/mcp/apinav/plugins
	doins plugins/__init__.py plugins/base.py plugins/plugins.yaml \
		plugins/api_ninjas.py plugins/apify.py plugins/apisguru.py \
		plugins/apisio.py plugins/googledisc.py plugins/hfspace.py \
		plugins/publicapi.py plugins/rapidapi.py plugins/smithery.py

	# pip writes the venv's internal paths pointing at the build image; repoint
	# them at the live path or every console script fails with "bad interpreter:
	# /var/tmp/portage/...". The whole PREFIX is rewritten, not just the
	# interpreter, so the activate scripts are corrected too.
	local img_prefix="${ED}/opt/mcp/apinav-venv"
	local live_prefix="/opt/mcp/apinav-venv"
	find "${venv}" -type f \( -name "*.py" -o -name "activate" -o -name "activate.*" \
		-o -path "*/bin/*" \) -exec sed -i \
		"s|${img_prefix}|${live_prefix}|g" {} + || die "path rewrite failed"

	# Prove the rewrite before the image is merged: a leftover image path in bin/
	# means a console script will fail on the live system.
	if grep -rql "var/tmp/portage" "${venv}/bin/" 2>/dev/null; then
		egrep -rl "var/tmp/portage" "${venv}/bin/" 2>/dev/null | while read -r f; do
			eerror "  ${f}"
		done
		die "venv still refers to the build image directory"
	fi

	fowners -R root:root /opt/mcp/apinav /opt/mcp/apinav-venv
	fperms -R a+rX /opt/mcp/apinav /opt/mcp/apinav-venv

	# A real wrapper file, not a symlink into the venv: a wrapper survives the
	# venv being relocated or rebuilt. The heredoc body starts at column 0
	# deliberately -- '<<-' strips leading TABS only, so indenting it would put
	# whitespace before the shebang and break the script.
	newbin - apinav <<-'EOF'
#!/usr/bin/env bash
exec /opt/mcp/apinav-venv/bin/python /opt/mcp/apinav/apinav.py "${@}"
EOF
}

pkg_postinst() {
	elog "apinav ${PV} installed. The CLI is:"
	elog ""
	elog "  apinav search <query>"
	elog "  apinav stats"
	elog ""
	elog "State (the catalog and the embedding cache) is NOT part of the package —"
	elog "it is written at runtime by whichever account runs the tool. Point it at a"
	elog "writable directory; for the gateway's service account that is set on the"
	elog "backend already:"
	elog ""
	elog "  APINAV_STATE_DIR=/var/lib/mcp-gateway/apinav"
	elog ""
	elog "The catalog starts empty and grows as searches run; a pre-built catalog can"
	elog "be copied in from a previous install."
	elog ""
	elog "Credentials are read from the environment first (the MCP gateway injects"
	elog "them for the apinav backend), with /opt/mcp/apinav/.env as a fallback:"
	elog ""
	elog "  NVIDIA_API_KEY      (embeddings; alias EMBEDDING_API_KEY)"
	elog "  OPENROUTER_API_KEY  (rerank;   alias RERANK_API_KEY)"
	elog "  API_NINJAS_API_KEY, TYPESAFE_API_KEY"
}
