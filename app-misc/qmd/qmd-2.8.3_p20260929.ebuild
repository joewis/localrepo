# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Prebuilt-bundle ebuild rather than a source build, deliberately.
#
# qmd is a TypeScript app with a 13-package runtime dep tree, and the published
# dist is produced by `tsc` plus a shebang/commit stamp. A source ebuild here
# would have to run `npm ci` from the network inside the sandbox (there is no
# npm eclass in ::gentoo and no ::guru overlay on this box), pull ~855 MB of
# registry traffic on every merge, and tolerate the project's `prepare` hook
# running during install - none of which buys reproducibility that the pinned
# distfile hash does not already give us.
#
# The bundle is built from the fork and attached to a release, so SRC_URI still
# points at joewis/qmd. It installs to the same path a global npm install used
# (/usr/lib64/node_modules/@tobilu/qmd), so the existing /usr/local/bin/qmd
# safety wrapper and the qmd-update-*.service units keep working unchanged.
#
# The bundle ships only linux-x64 (glibc) artefacts: the upstream optional deps
# pull CUDA/Vulkan/other-arch/other-OS variants that are 600 MB of dead weight
# on a CPU-only amd64 host.

EAPI=8

DESCRIPTION="Quick Markdown Search - hybrid markdown search/retrieval CLI"
HOMEPAGE="https://github.com/joewis/qmd"
SRC_URI="https://github.com/joewis/qmd/releases/download/v${PV}/qmd-${PV}.tar.xz"
S="${WORKDIR}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# strip: node_modules ships prebuilt native addons (better-sqlite3, sqlite-vec,
#        @node-llama-cpp) that must not be touched.
# mirror: the bundle lives on the fork's release page; it is not distfile-mirrored.
RESTRICT="mirror strip"

# The vendored ggml shared objects are dlopen'd by path rather than linked
# against, so they carry no DT_RUNPATH. Portage's scanelf pass reports that as
# "Security problem NULL DT_RUNPATH" during the build; it is expected here and
# does not fail the build or the merge. Nothing in this package is code we
# compile - dist/ is TypeScript, and the only ELF objects are upstream's.
QA_PREBUILT="*"

RDEPEND=">=net-libs/nodejs-22"

src_unpack() {
	default
}

src_compile() {
	:;
}

src_install() {
	local dest="/usr/$(get_libdir)/node_modules/@tobilu/qmd"

	insinto "${dest}"
	doins -r bin dist node_modules package.json LICENSE CHANGELOG.md README.md skills scripts

	fperms +x "${dest}/bin/qmd"
	fperms +x "${dest}/dist/cli/qmd.js"

	dosym "../$(get_libdir)/node_modules/@tobilu/qmd/bin/qmd" /usr/bin/qmd
}

pkg_postinst() {
	elog "qmd is installed as a fork of upstream 2.8.3 with an optional cloud"
	elog "embedding/re-ranking backend. Configure it in ~/.config/qmd/index.yml:"
	elog ""
	elog "  models:"
	elog "    remote:"
	elog "      embed:"
	elog "        url: https://integrate.api.nvidia.com/v1/embeddings"
	elog "        model: nvidia/nemotron-3-embed-1b"
	elog "        key_env: EMBEDDING_API_KEY   # name of the env var, not the key"
	elog ""
	elog "Run 'qmd status' to see which backend each role resolved to. Changing the"
	elog "embedding model changes the vector width, so an existing index needs"
	elog "'qmd embed' (never --force) to be regenerated."
}
