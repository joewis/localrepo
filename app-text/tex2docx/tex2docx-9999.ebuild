# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="LaTeX to DOCX conversion workflow using pandoc + pandoc-xnos"
HOMEPAGE="https://github.com/jay-dennis/tex2docx"
SRC_URI="https://github.com/jay-dennis/tex2docx/archive/refs/heads/main.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"  # no license in repo; assume GPL
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	app-text/pandoc-bin[pandoc-symlink]
"

BDEPEND=""

S="${WORKDIR}/tex2docx-main"

src_install() {
	dobin tex2docx.py

	insinto /usr/share/${PN}/pandoc
	doins pandoc/*.csl

	insinto /usr/share/${PN}
	doins pandoc/pandoc_command.txt
	doins Example.tex refs.bib
}

pkg_postinst() {
	einfo ""
	einfo "tex2docx also requires the pandoc-xnos filter:"
	einfo "  pip install pandoc-xnos"
	einfo ""
	einfo "Example usage:"
	einfo "  tex2docx.py yourfile.tex"
	einfo ""
}
