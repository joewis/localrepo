# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12,13,14} )
inherit python-single-r1

DESCRIPTION="Easy-to-Use Speech MOS predictors — UTMOS22 for TTS quality evaluation"
HOMEPAGE="https://github.com/tarepan/SpeechMOS"
SRC_URI="https://github.com/tarepan/SpeechMOS/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}/SpeechMOS-${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

# torchaudio is bundled with sci-ml/pytorch
RDEPEND="
	${PYTHON_DEPS}
	>=sci-ml/pytorch-2.0[${PYTHON_SINGLE_USEDEP}]
"
BDEPEND="
	${PYTHON_DEPS}
"

# Pure Python package, no compilation
src_compile() {
	:
}

src_install() {
	python_domodule speechmos
	dodoc README.md
}

pkg_postinst() {
	elog "SpeechMOS ${PV} installed."
	elog ""
	elog "Usage:"
	elog "  import torch"
	elog "  predictor = torch.hub.load('tarepan/SpeechMOS:v1.2.0', 'utmos22_strong', trust_repo=True)"
	elog "  score = predictor(wave_tensor, sr)"
	elog ""
	elog "The model weights (~392 MB) are downloaded on first use via torch.hub."
	elog "Alternatively, import directly:"
	elog "  from speechmos.utmos22.strong.model import UTMOS22Strong"
	elog "  model = UTMOS22Strong()"
	elog "  state = torch.load('/path/to/utmos22_strong_step7459_v1.pt', map_location='cpu')"
	elog "  model.load_state_dict(state)"
}
