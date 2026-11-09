EAPI=8

inherit go-module

DESCRIPTION="Like the macOS say command, but with a modern voice — ElevenLabs TTS CLI"
HOMEPAGE="https://github.com/steipete/sag"
SRC_URI="https://github.com/steipete/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

# Generated from go.sum (v0.4.5)
EGO_SUM=(
	"github.com/cpuguy83/go-md2man/v2 v2.0.6/go.mod"
	"github.com/ebitengine/oto/v3 v3.4.1"
	"github.com/ebitengine/oto/v3 v3.4.1/go.mod"
	"github.com/ebitengine/purego v0.11.0"
	"github.com/ebitengine/purego v0.11.0/go.mod"
	"github.com/hajimehoshi/go-mp3 v0.3.4"
	"github.com/hajimehoshi/go-mp3 v0.3.4/go.mod"
	"github.com/hajimehoshi/oto/v2 v2.3.1/go.mod"
	"github.com/inconshreveable/mousetrap v1.1.0"
	"github.com/inconshreveable/mousetrap v1.1.0/go.mod"
	"github.com/russross/blackfriday/v2 v2.1.0/go.mod"
	"github.com/spf13/cobra v1.10.2"
	"github.com/spf13/cobra v1.10.2/go.mod"
	"github.com/spf13/pflag v1.0.9/go.mod"
	"github.com/spf13/pflag v1.0.10"
	"github.com/spf13/pflag v1.0.10/go.mod"
	"go.yaml.in/yaml/v3 v3.0.4/go.mod"
	"golang.org/x/sys v0.0.0-20220712014510-0a85c31ab51e/go.mod"
	"golang.org/x/sys v0.47.0"
	"golang.org/x/sys v0.47.0/go.mod"
	"gopkg.in/check.v1 v0.0.0-20161208181325-20d25e280405/go.mod"
)

go-module_set_globals

SRC_URI+=" ${EGO_SUM_SRC_URI}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND=">=dev-lang/go-1.25.0"

src_compile() {
	ego build -o "${PN}" ./cmd/sag
}

src_install() {
	dobin sag
	dodoc README.md
}
