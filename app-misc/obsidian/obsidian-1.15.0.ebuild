# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop

DESCRIPTION="Obsidian — powerful knowledge base on top of local plain text Markdown files"
HOMEPAGE="https://obsidian.md/"
SRC_URI="https://github.com/obsidianmd/obsidian-releases/releases/download/v${PV}/Obsidian-${PV}.AppImage"

S="${WORKDIR}"
LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror strip"

RDEPEND="
	sys-fs/fuse
	sys-libs/glibc
"

src_unpack() {
	cp "${DISTDIR}/Obsidian-${PV}.AppImage" "${S}/" || die
}

src_compile() {
	chmod +x "${S}/Obsidian-${PV}.AppImage" || die
	"${S}/Obsidian-${PV}.AppImage" --appimage-extract >/dev/null 2>&1 || die "extraction failed"
}

src_install() {
	insinto /opt/obsidian
	doins -r "${S}/squashfs-root/"* || die
	fperms 0755 /opt/obsidian/obsidian
	fperms 0755 /opt/obsidian/obsidian-cli

	cat > "${T}/obsidian" <<- 'WRAPPER' || die
	#!/usr/bin/env bash
	exec /opt/obsidian/obsidian "${@}"
	WRAPPER
	dobin "${T}/obsidian"

	if [[ -f "${S}/squashfs-root/obsidian.desktop" ]]; then
		domenu "${S}/squashfs-root/obsidian.desktop"
	fi

	local icon
	for icon in "${S}/squashfs-root/usr/share/icons/hicolor/512x512/apps/obsidian.png"; do
		if [[ -f "${icon}" ]]; then
			newicon -s 512 "${icon}" obsidian.png
			break
		fi
	done
}

pkg_postinst() {
	elog "Obsidian ${PV} installed."
	elog ""
	elog "To use the CLI, open Obsidian and enable:"
	elog "  Settings → General → Command line interface"
	elog ""
	elog "This creates a symlink at /usr/local/bin/obsidian."
	elog "The ebuild already provides /usr/bin/obsidian for convenience."
}
