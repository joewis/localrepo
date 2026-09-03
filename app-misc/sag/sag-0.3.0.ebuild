EAPI=8

inherit go-module

DESCRIPTION="Like the macOS say command, but with a modern voice — ElevenLabs TTS CLI"
HOMEPAGE="https://github.com/steipete/sag"
SRC_URI="https://github.com/steipete/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

BDEPEND=">=dev-lang/go-1.25.0"

# Generated from go.sum
EGO_SUM=(
	"github.com/ebitengine/oto/v3 v3.4.0"
	"github.com/ebitengine/oto/v3 v3.4.0/go.mod"
	"github.com/ebitengine/purego v0.10.0"
	"github.com/ebitengine/purego v0.10.0/go.mod"
	"github.com/hajimehoshi/go-mp3 v0.3.4"
	"github.com/hajimehoshi/go-mp3 v0.3.4/go.mod"
	"github.com/inconshreveable/mousetrap v1.1.0"
	"github.com/inconshreveable/mousetrap v1.1.0/go.mod"
	"github.com/spf13/cobra v1.10.2"
	"github.com/spf13/cobra v1.10.2/go.mod"
	"github.com/spf13/pflag v1.0.10"
	"github.com/spf13/pflag v1.0.10/go.mod"
	"golang.org/x/sys v0.43.0"
	"golang.org/x/sys v0.43.0/go.mod"
)

go-module_set_globals

SRC_URI+=" ${EGO_SUM_SRC_URI}"

src_compile() {
	ego build -o "${PN}" ./cmd/sag
}

src_install() {
	dobin sag
	dodoc README.md
}
