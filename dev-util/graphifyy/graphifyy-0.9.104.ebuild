# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_14 )
inherit python-single-r1

DESCRIPTION="Turn any folder into a queryable knowledge graph"
HOMEPAGE="https://github.com/Graphify-Labs/graphify"
SRC_URI="
https://files.pythonhosted.org/packages/source/g/graphifyy/graphifyy-${PV}.tar.gz
graphifyy-deps-${PV}.tar.gz
"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="${PYTHON_DEPS}"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

src_compile() {
    :
}

src_install() {
    local venv="${ED}/opt/graphifyy"
    ${EPYTHON} -m venv "${venv}" || die
    "${venv}/bin/pip" install --no-index --find-links "${S}/.." "${S}/../graphifyy-${PV}-py3-none-any.whl" || die

    # Fix shebangs to use live path instead of image path
    local img_path="${ED}/opt/graphifyy/bin/python3.14"
    local live_path="/opt/graphifyy/bin/python3.14"
    find "${venv}/bin" -type f -exec sed -i "s|${img_path}|${live_path}|g" {} + 2>/dev/null || true

    fowners -R root:root /opt/graphifyy
    fperms -R a+rX /opt/graphifyy
    fperms a+x /opt/graphifyy/bin/graphify
    fperms a+x /opt/graphifyy/bin/graphify-mcp

    newbin - graphify << 'WRAPPER'
#!/usr/bin/env bash
exec /opt/graphifyy/bin/graphify "${@}"
WRAPPER
}

pkg_postinst() {
    elog "graphifyy ${PV} installed."
    elog "Usage: graphify <command> [options]"
}
