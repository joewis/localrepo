# Copyright 2026-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

DESCRIPTION="Moomoo OpenD — API gateway for moomoo trading platform"
HOMEPAGE="https://openapi.moomoo.com/ https://www.moomoo.com/download/OpenAPI"
SRC_URI="https://softwaredownload.futustatic.com/moomoo_OpenD_${PV}_Ubuntu18.04.tar.gz"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror strip"

BDEPEND=""
RDEPEND="
	sys-fs/fuse
	sys-libs/glibc
	sys-libs/zlib
"

S="${WORKDIR}/moomoo_OpenD_${PV}_Ubuntu18.04"

src_compile() {
	# precompiled binary; nothing to compile
	:
}

src_install() {
	local opendir="${S}/moomoo_OpenD_${PV}_Ubuntu18.04"
	local guidir="${S}/moomoo_OpenD-GUI_${PV}_Ubuntu18.04"

	# Install the CLI daemon
	insinto /opt/moomoo-opend
	doins -r "${opendir}"/*
	fperms 0755 /opt/moomoo-opend/OpenD
	fperms 0755 /opt/moomoo-opend/Update
	fperms 0755 /opt/moomoo-opend/WebSocket

	# Install GUI AppImage
	doins "${guidir}/moomoo_OpenD-GUI_${PV}_Ubuntu18.04.AppImage"
	fperms 0755 "/opt/moomoo-opend/moomoo_OpenD-GUI_${PV}_Ubuntu18.04.AppImage"
	dosym "moomoo_OpenD-GUI_${PV}_Ubuntu18.04.AppImage" \
		/opt/moomoo-opend/moomoo-opend-gui.AppImage

	# Systemd service (runs as openclaw user)
	systemd_dounit "${FILESDIR}/moomoo-opend.service"

	# Docs
	dodoc "${S}/README.txt"

	# Wrapper script for the CLI daemon
	cat > "${T}/moomoo-opend" <<-EOF
	#!/usr/bin/env bash
	set -euo pipefail

	installdir="/opt/moomoo-opend"
	config_dir="\${XDG_CONFIG_HOME:-\${HOME}/.config}/moomoo-opend"
	state_dir="\${XDG_STATE_HOME:-\${HOME}/.local/state}/moomoo-opend"
	config_file="\${config_dir}/OpenD.xml"

	mkdir -p "\${config_dir}" "\${state_dir}/logs"
	if [[ ! -f "\${config_file}" ]]; then
		cp "\${installdir}/OpenD.xml" "\${config_file}"
		chmod 600 "\${config_file}"
	fi

	cd "\${installdir}"
	exec ./OpenD -cfg_file="\${config_file}" -log_path="\${state_dir}/logs" "\${@}"
	EOF
	dobin "${T}/moomoo-opend"

	# Wrapper script for the GUI
	cat > "${T}/moomoo-opend-gui" <<-EOF
	#!/usr/bin/env bash
	exec /opt/moomoo-opend/moomoo-opend-gui.AppImage "\${@}"
	EOF
	dobin "${T}/moomoo-opend-gui"
}

pkg_postinst() {
	systemd_disable -f moomoo-opend.service
	systemd_enable default.target moomoo-opend.service

	elog "Moomoo OpenD ${PV} installed."
	elog ""
	elog "CLI usage:"
	elog "  1. Edit ~/.config/moomoo-opend/OpenD.xml with your login credentials"
	elog "  2. Run: moomoo-opend"
	elog ""
	elog "Systemd service (runs as openclaw user):"
	elog "  Configure: su - openclaw -c 'nano ~/.config/moomoo-opend/OpenD.xml'"
	elog "  Start:     sudo systemctl start moomoo-opend"
	elog "  Enable:    sudo systemctl enable moomoo-opend"
	elog "  Status:    sudo systemctl status moomoo-opend"
	elog ""
	elog "GUI usage:"
	elog "  Run: moomoo-opend-gui"
	elog ""
	elog "See /usr/share/doc/${PF}/README.txt for more information."
}
