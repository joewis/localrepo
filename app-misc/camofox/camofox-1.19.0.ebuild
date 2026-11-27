# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Prepared-bundle ebuild rather than a source build, deliberately.
#
# camofox is a Node daemon around @askjo/camofox-browser. There is no npm
# eclass in ::gentoo (and no ::guru overlay on this box), so a source build
# would have to run `npm ci` from the network inside the sandbox on every
# merge and let the project's own postinstall hook run during install. The
# pinned distfile hash gives the same reproducibility without any of that.
# This mirrors app-misc/qmd, packaged the same way for the same reason.
#
# The bundle is assembled from a working install and attached to a release on
# joewis/localrepo, so SRC_URI resolves to a real, hashable artifact. It ships
# only linux-x64 (glibc) artefacts: upstream's optional deps pull CUDA/Vulkan/
# other-arch/other-OS variants that are dead weight on an amd64 CPU host.

EAPI=8

inherit systemd

DESCRIPTION="Anti-detection browser server (Camoufox) with an HTTP control API"
HOMEPAGE="https://github.com/jo-inc/camofox-browser"
SRC_URI="https://github.com/joewis/localrepo/releases/download/v${PV}/${PN}-${PV}.tar.xz"
S="${WORKDIR}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# strip: node_modules carries prebuilt native addons (better-sqlite3) that
#        must not be touched.
# mirror: the bundle lives on the overlay's release page, not distfile-mirrored.
RESTRICT="mirror strip"

# There is no code we compile here: server.js is shipped JS and the only ELF
# objects are upstream's prebuilt addons, dlopen'd by path (so they carry no
# DT_RUNPATH and scanelf reports "Security problem NULL DT_RUNPATH" - expected,
# exit 0, not a defect to chase).
QA_PREBUILT="*"

RDEPEND="
	>=net-libs/nodejs-22
"

src_unpack() {
	default
}

src_compile() {
	:
}

src_install() {
	# Install at the same path a global npm install used, so any existing
	# wrapper or unit keeps resolving it unchanged:
	#   /usr/$(get_libdir)/node_modules/@askjo/camofox-browser
	#   /usr/$(get_libdir)/node_modules/<each runtime dep>
	local nm="/usr/$(get_libdir)/node_modules"

	insinto "${nm}/@askjo"
	doins -r "${S}/node_modules/@askjo/camofox-browser"

	# Every top-level runtime dep, except the scoped @askjo dir already placed
	# above (installing it twice would collide with itself).
	local d
	for d in "${S}"/node_modules/*; do
		[[ -e ${d} ]] || continue
		[[ ${d##*/} == "@askjo" ]] && continue
		insinto "${nm}"
		doins -r "${d}"
	done

	# CLI wrapper, installed as a real file so the command does not depend on
	# the npm layout, plus the systemd unit.
	newbin "${FILESDIR}/camofox" camofox
	systemd_dounit "${FILESDIR}/camofox.service"

	dodoc "${S}/node_modules/@askjo/camofox-browser/README.md"
	dodoc "${S}/node_modules/@askjo/camofox-browser/LICENSE"
}

pkg_postinst() {
	local browser_version

	elog "camofox is installed. It needs a Camoufox browser binary, which is NOT"
	elog "shipped by this package - it is a version-pinned runtime download."
	elog ""
	elog "  * The browser is fetched on first use and cached in"
	elog "    ~/.cache/camoufox (about 1.3 GB). It is deliberately treated as a"
	elog "    cache: upstream bumps it frequently, and camoufox-js pins the"
	elog "    expected build in its own version.json."
	elog "  * If you need the browser pre-fetched, run the daemon once and let it"
	elog "    populate the cache, or consult the camoufox-js docs for its fetch"
	elog "    entry point. Portage cannot fetch it: the build sandbox has no"
	elog "    network access."
	elog ""
	elog "Enable the service with:"
	elog "  systemctl enable --now camofox.service"
	elog ""
	elog "The control API listens on http://127.0.0.1:9377; the 'camofox' CLI"
	elog "wraps it (camofox health|start|stop|tab|nav|snap|...)."
}
