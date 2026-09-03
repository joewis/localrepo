# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_14 )
inherit distutils-r1

DESCRIPTION="Radically simplified static file serving for WSGI applications"
HOMEPAGE="https://whitenoise.readthedocs.io/"
SRC_URI="https://github.com/evansd/whitenoise/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="test"

RDEPEND=""
BDEPEND=""
