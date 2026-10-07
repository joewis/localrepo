# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_14 )
inherit python-single-r1

DESCRIPTION="Local control, cloud map retrieval and MCP tools for Xiaomi robot vacuums"
HOMEPAGE="https://github.com/joewis/xiaomi-devices"
SRC_URI="
	https://github.com/joewis/xiaomi-devices/archive/refs/tags/v${PV}.tar.gz
		-> ${P}.tar.gz
	https://github.com/joewis/xiaomi-devices/releases/download/v${PV}/xiaomi-devices-deps-${PV}.tar.gz
"

# S is explicit and BOTH archives are extracted by hand in src_unpack: the dependency
# bundle has no single top-level directory, so relying on Portage's unpack heuristics
# for it would make the wheel location depend on the tarball's shape.
S="${WORKDIR}/src/xiaomi-devices-${PV}"

# The package's own code is MIT. The bundled wheels it installs carry their own licences
# (including GPL-3.0-only for python-miio) and are redistributed unmodified as downloaded
# from PyPI; the bundle ships a licenses.txt naming every one of them.
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="${PYTHON_DEPS}"
BDEPEND="${PYTHON_DEPS}"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

src_unpack() {
	mkdir -p "${WORKDIR}/src" "${WORKDIR}/wheels" || die
	tar xzf "${DISTDIR}/${P}.tar.gz" -C "${WORKDIR}/src" || die
	tar xzf "${DISTDIR}/xiaomi-devices-deps-${PV}.tar.gz" -C "${WORKDIR}/wheels" || die
}

src_compile() {
	:
}

src_install() {
	local venv="${ED}/opt/xiaomi-devices"

	# An isolated venv rather than site-packages: two runtime dependencies (python-miio,
	# mcp) are not in ::gentoo and their transitive tree is ~54 packages deep, so the
	# wheels are bundled and installed offline from a pinned bundle instead of being
	# packaged one by one.
	"${EPYTHON}" -m venv "${venv}" || die "could not create the venv"

	# Build tooling first, so the package's own source build can run with build isolation
	# off and never reach the network.
	"${venv}"/bin/pip install --no-index --no-build-isolation \
		--find-links "${WORKDIR}/wheels" \
		"${WORKDIR}"/wheels/setuptools-*.whl "${WORKDIR}"/wheels/wheel-*.whl \
		|| die "could not install build tooling into the venv"

	# [all] pulls the cloud extra (colorama, Pillow) and the mcp extra as well as the
	# local set, so all three commands work. Installing without it would leave
	# xiaomi-map and xiaomi-vacuum-mcp unable to start.
	"${venv}"/bin/pip install --no-index --no-build-isolation \
		--find-links "${WORKDIR}/wheels" "${S}[all]" \
		|| die "could not install xiaomi-devices into the venv"

	# Keep the licence manifest visible alongside the install: it names every bundled
	# component and its terms.
	if [[ -f "${WORKDIR}/wheels/licenses.txt" ]]; then
		insinto /opt/xiaomi-devices
		doins "${WORKDIR}/wheels/licenses.txt"
	fi

	# pip writes shebangs pointing at the path the venv had during the install, which is
	# the image directory. Repoint them at the live path or every console script fails
	# with "bad interpreter: /var/tmp/portage/...". The whole venv PREFIX is rewritten,
	# not just the interpreter path, so the activate scripts are corrected too -- the
	# narrower substitution leaves them pointing at the image dir, which breaks
	# `source .../bin/activate` after the merge.
	local img_prefix="${ED}/opt/xiaomi-devices"
	local live_prefix="/opt/xiaomi-devices"
	find "${venv}" -type f \( -name "*.py" -o -name "activate" -o -name "activate.*" \
		-o -path "*/bin/*" \) -exec sed -i \
		"s|${img_prefix}|${live_prefix}|g" {} + || die "path rewrite failed"

	# Prove the rewrite before the image is merged: a leftover image path in bin/ means a
	# console script will fail on the live system, and it is cheaper to catch here.
	if grep -rql "var/tmp/portage" "${venv}/bin/" 2>/dev/null; then
		eerror "image paths survive in ${venv}/bin/:"
		grep -rl "var/tmp/portage" "${venv}/bin/" 2>/dev/null | while read -r f; do
			eerror "  ${f}"
		done
		die "venv still refers to the build image directory"
	fi

	fowners -R root:root /opt/xiaomi-devices
	fperms -R a+rX /opt/xiaomi-devices

	# Real wrapper files, not symlinks into the venv: a wrapper survives the venv being
	# relocated or rebuilt, and is what another user's shell will actually execute.
	# The heredoc bodies start at column 0 deliberately -- '<<-' strips leading TABS only,
	# so indenting them would put whitespace before the shebang and break the script.
	newbin - xiaomi-ctl <<-'EOF'
#!/usr/bin/env bash
exec /opt/xiaomi-devices/bin/xiaomi-ctl "${@}"
EOF

	newbin - xiaomi-map <<-'EOF'
#!/usr/bin/env bash
exec /opt/xiaomi-devices/bin/xiaomi-map "${@}"
EOF

	newbin - xiaomi-vacuum-mcp <<-'EOF'
#!/usr/bin/env bash
exec /opt/xiaomi-devices/bin/xiaomi-vacuum-mcp "${@}"
EOF

	dodoc README.md
}

pkg_postinst() {
	elog "xiaomi-devices ${PV} installed. Three commands are available:"
	elog ""
	elog "  xiaomi-ctl         local device control, non-interactive"
	elog "  xiaomi-map         cloud login and map retrieval, interactive"
	elog "  xiaomi-vacuum-mcp  MCP server over stdio (local device only)"
	elog ""
	elog "Nothing is configured yet. Credentials and the room map live outside the"
	elog "package, in \${XDG_CONFIG_HOME:-~/.config}/xiaomi-devices/ :"
	elog ""
	elog "  secrets.env   XIAOMI_USER / XIAOMI_PASS / XIAOMI_DEVICE_TOKEN (chmod 600)"
	elog "  device.json   the device's address"
	elog "  rooms.json    spoken room name -> segment id, from your own map"
	elog ""
	elog "The device token comes from logging in, which needs a human:"
	elog ""
	elog "  xiaomi-map devices --login qr"
	elog ""
	elog "QR login is the reliable route -- it skips the captcha and the emailed code."
	elog "The session is then cached for about 48 hours, so a second run needs no human."
}
