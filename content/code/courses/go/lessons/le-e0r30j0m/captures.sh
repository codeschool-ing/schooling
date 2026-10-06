#!/usr/bin/env bash
# The terminal sessions quoted in lesson 40 of go, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and every program the lesson shows is
# written below, byte for byte, by `put`.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1 and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the files ana wrote, put below, whose contents the lesson shows.
#   - every third-party version the lesson uses is downloaded quietly first
#     (`go mod download`, and one throwaway `go get` of gin in ~/thirdparty-warm),
#     so that no transcript depends on whether the module cache already had it.
#     Lesson 38 shows what a first download prints.
#   - GOVULNCHECK. vuln.go.dev, the database govulncheck reads by default, is
#     not reachable from this sandbox. The lab builds a copy of the same
#     database from the golang.org/x/vulndb module (its data/osv directory, the
#     revision of 5 October 2026), with that module's own cmd/indexdb, into
#     ~/thirdparty-vulndb, and every scan names it with `-db file://...`. On a
#     machine with a network the flag is left out. govulncheck v1.8.0 itself is
#     built as ana into ~/thirdparty-tools and copied to /usr/local/bin, so that
#     it runs by name without adding anything to ~/go/bin, which lesson 4 lists.
#     It is run against ana's own module only, ~/thirdparty-locale, whose
#     golang.org/x/text is deliberately old.
#   - PUBLISHING. There is no code host here. ~/thirdparty-greet is an ordinary
#     git repository; its commits are made quietly with fixed dates, so their
#     hashes and the versions' times are the same on every run, and only the
#     `git tag` commands are shown. The part a host and proxy.golang.org would
#     play is played by ~/thirdparty-tools/publish, a small program written
#     below: given the repository and a tag, it writes the tag's go.mod, a zip
#     made by golang.org/x/mod/zip.CreateFromVCS and an .info file into
#     ~/thirdparty-proxy, laid out as the GOPROXY protocol asks
#     (<module>/@v/list, .info, .mod, .zip), and adds the tag to `list`. Every
#     command that reads the published module says GOPROXY=file:///home/ana/thirdparty-proxy
#     on its own line, and GONOSUMDB=example.com, because the public checksum
#     database has never seen it (block `sumdb` shows that refusal).
#   - ~/thirdparty-gin is a scratch module that exists only to be measured.
# Real network traffic: the module proxy (proxy.golang.org), the checksum
# database (sum.golang.org) and, in block `pkgsite`, which the lesson quotes in
# prose, pkg.go.dev. The "latest" versions are the latest on the day the lab ran,
# and a later run may print newer ones.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, TZ=America/Sao_Paulo.

set -uo pipefail
LAB_SH=${LAB_SH:-$(dirname "$0")/../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on DIR 'command': what ana typed in ~/DIR, and what it printed.
on() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "$*" 2>&1 || true; }
put() { lab put "$1"; }
quiet() { lab exec "$1" "$2" >/dev/null 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

VULNDB=v0.0.0-20261005191246-02052bb39a2e
P='GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com'

# ---------------------------------------------------------------- staging
# Versions of the lab's own module left in the module cache by an earlier run
# would change what `go get` prints; they are removed (they are read-only there).
for d in /home/ana/go/pkg/mod/example.com/ana /home/ana/go/pkg/mod/cache/download/example.com/ana; do
  [ -d "$d" ] && chmod -R u+w "$d" && rm -rf "$d"
done
lab fresh thirdparty-warm
quiet thirdparty-warm 'go mod init example.com/warm'
quiet thirdparty-warm 'go mod download github.com/mattn/go-runewidth@v0.0.16 github.com/mattn/go-runewidth@latest github.com/rivo/uniseg@v0.2.0 github.com/rivo/uniseg@latest github.com/clipperhouse/uax29/v2@v2.2.0 github.com/clipperhouse/uax29/v2@latest golang.org/x/text@v0.3.6 golang.org/x/text@latest'
quiet thirdparty-warm 'go get github.com/gin-gonic/gin@v1.12.0'

lab fresh thirdparty-tools
quiet thirdparty-tools 'GOBIN=$HOME/thirdparty-tools go install golang.org/x/vuln/cmd/govulncheck@v1.8.0'
install -m 0755 /home/ana/thirdparty-tools/govulncheck /usr/local/bin/govulncheck
lab fresh thirdparty-vulndb
quiet thirdparty-tools "go mod download golang.org/x/vulndb@$VULNDB"
quiet thirdparty-tools "go run golang.org/x/vulndb/cmd/indexdb@$VULNDB -vulns \$(go env GOMODCACHE)/golang.org/x/vulndb@$VULNDB/data/osv -out \$HOME/thirdparty-vulndb"

put thirdparty-tools/publish/main.go <<'EOF'
// Command publish copies one tag of a git repository into a directory laid
// out as a module proxy: what proxy.golang.org does the first time somebody
// asks it for a version. It is the lab's stand-in for a code host.
package main

import (
	"bytes"
	"encoding/json"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"

	"golang.org/x/mod/modfile"
	"golang.org/x/mod/module"
	"golang.org/x/mod/zip"
)

func git(repo string, args ...string) []byte {
	out, err := exec.Command("git", append([]string{"-C", repo}, args...)...).Output()
	if err != nil {
		log.Fatalf("git %v: %v", args, err)
	}
	return out
}

func main() {
	repo, tag, proxy := os.Args[1], os.Args[2], os.Args[3]
	gomod := git(repo, "show", tag+":go.mod")
	path := modfile.ModulePath(gomod)
	esc, err := module.EscapePath(path)
	if err != nil {
		log.Fatal(err)
	}
	dir := filepath.Join(proxy, esc, "@v")
	if err := os.MkdirAll(dir, 0o755); err != nil {
		log.Fatal(err)
	}
	var z bytes.Buffer
	if err := zip.CreateFromVCS(&z, module.Version{Path: path, Version: tag}, repo, tag, ""); err != nil {
		log.Fatal(err)
	}
	when := strings.TrimSpace(string(git(repo, "log", "-1", "--format=%cI", tag)))
	info, _ := json.Marshal(map[string]string{"Version": tag, "Time": when})
	write := func(name string, b []byte) {
		if err := os.WriteFile(filepath.Join(dir, name), b, 0o644); err != nil {
			log.Fatal(err)
		}
	}
	write(tag+".info", info)
	write(tag+".mod", gomod)
	write(tag+".zip", z.Bytes())
	list, _ := os.ReadFile(filepath.Join(dir, "list"))
	versions := strings.Fields(string(list))
	if !slices.Contains(versions, tag) {
		versions = append(versions, tag)
	}
	write("list", []byte(strings.Join(versions, "\n")+"\n"))
}
EOF
quiet thirdparty-tools/publish 'go mod init example.com/publish && go get golang.org/x/mod@v0.41.0 && go build -o ../publish-bin .'
publish() { quiet thirdparty-greet "~/thirdparty-tools/publish-bin ~/thirdparty-greet $1 ~/thirdparty-proxy"; }
commit() { quiet thirdparty-greet "git add -A && GIT_AUTHOR_DATE='$2' GIT_COMMITTER_DATE='$2' git commit -q -m '$1'"; }

# ---------------------------------------------------------------- using
lab fresh thirdparty-width
put thirdparty-width/main.go <<'EOF'
// Command width measures strings the way a terminal draws them.
package main

import (
	"fmt"
	"unicode/utf8"

	"github.com/mattn/go-runewidth"
)

func main() {
	words := []string{
		"Ana",
		"cafe\u0301",           // e and a combining accent
		"\u65e5\u672c",         // Japan, in Japanese
		"\U0001F1E7\U0001F1F7", // the flag of Brazil
		"\U0001FAE9",           // a recent emoji
	}
	for _, w := range words {
		fmt.Printf("%-+24q bytes %d  runes %d  columns %d\n",
			w, len(w), utf8.RuneCountInString(w), runewidth.StringWidth(w))
	}
}
EOF
quiet thirdparty-width 'go mod init example.com/width'

block get-old
on thirdparty-width 'go get github.com/mattn/go-runewidth@v0.0.16'
on thirdparty-width 'go mod tidy && cat go.mod'
on thirdparty-width 'go run .'

block list-u
on thirdparty-width 'go list -m -u all'

block upgrade
on thirdparty-width 'go get github.com/mattn/go-runewidth@latest'
on thirdparty-width 'go run .'

block tidy-after
on thirdparty-width 'go mod tidy && cat go.mod'

block why
on thirdparty-width 'go mod why -m github.com/clipperhouse/uax29/v2'
on thirdparty-width 'go mod why -m github.com/rivo/uniseg'

block list-u-after
on thirdparty-width 'go list -m -u all'

block downgrade
on thirdparty-width 'go get github.com/mattn/go-runewidth@v0.0.16'
on thirdparty-width 'go get github.com/mattn/go-runewidth@none'
quiet thirdparty-width 'go get github.com/mattn/go-runewidth@latest && go mod tidy'

# ---------------------------------------------------------------- choosing
block candidates
on thirdparty-width 'go list -m -f "{{.Path}} {{.Version}} {{.Time}}" github.com/rivo/uniseg@latest github.com/clipperhouse/uax29/v2@latest'

block candidates-look
on thirdparty-width 'cd $(go env GOMODCACHE)/github.com/rivo/uniseg@v0.4.7 && head -1 LICENSE.txt && grep -n "Unicode version" graphemerules.go && cat go.mod'
on thirdparty-width 'cd $(go env GOMODCACHE)/github.com/clipperhouse/uax29/v2@v2.7.0 && head -1 LICENSE && grep -n "Public/" graphemes/trie.go && cat go.mod'

block switch
on thirdparty-width 'curl -s https://proxy.golang.org/github.com/mattn/go-runewidth/@v/v0.0.17.mod'
on thirdparty-width 'curl -s https://proxy.golang.org/github.com/mattn/go-runewidth/@v/v0.0.18.mod'

block pkgsite
# Read in prose, not shown as a transcript: the header of the page.
for m in github.com/rivo/uniseg github.com/clipperhouse/uax29/v2/graphemes github.com/mattn/go-runewidth; do
  echo "== $m"
  curl -s --max-time 30 "https://pkg.go.dev/$m" \
    | tr -s '\n' ' ' | sed -e 's/<[^>]*>/ /g' | tr -s ' ' \
    | grep -o -E '(Version|Published|License|Imports|Imported by): [^ ]+( [^ ]+ [0-9]+)?' | sort -u
done

lab fresh thirdparty-gin
quiet thirdparty-gin 'go mod init example.com/gin'
block graph
on thirdparty-gin 'go get github.com/gin-gonic/gin@v1.12.0 2>&1 | grep -c "^go: added"'
on thirdparty-gin 'go list -m all | wc -l'
on thirdparty-gin 'go list -m all | grep golang.org/x/'

lab fresh thirdparty-locale
put thirdparty-locale/main.go <<'EOF'
// Command locale reads a language tag such as pt-BR.
package main

import (
	"fmt"
	"os"

	"golang.org/x/text/language"
)

func main() {
	tag, err := language.Parse(os.Args[1])
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	base, _ := tag.Base()
	region, _ := tag.Region()
	fmt.Println(tag, base, region)
}
EOF
quiet thirdparty-locale 'go mod init example.com/locale'

block vuln-old
on thirdparty-locale 'go get golang.org/x/text@v0.3.6'
on thirdparty-locale 'go run . pt-BR'

block vuln-scan
on thirdparty-locale 'govulncheck -db file:///home/ana/thirdparty-vulndb ./...; echo $?'

block vuln-verbose
on thirdparty-locale 'govulncheck -db file:///home/ana/thirdparty-vulndb -show verbose ./... | head -9'
on thirdparty-locale 'govulncheck -db file:///home/ana/thirdparty-vulndb -show verbose ./... | sed -n "/Package Results/,\$p"'

block vuln-fix
on thirdparty-locale 'go get golang.org/x/text@latest'
on thirdparty-locale 'govulncheck -db file:///home/ana/thirdparty-vulndb ./...; echo $?'
on thirdparty-locale 'go run . pt-BR'

# ---------------------------------------------------------------- publishing
block real-proxy
on thirdparty-width 'curl -s https://proxy.golang.org/github.com/mattn/go-runewidth/@v/v0.0.16.info; echo'

lab fresh thirdparty-proxy
lab fresh thirdparty-greet
put thirdparty-greet/go.mod <<'EOF'
module example.com/ana/greet

go 1.27
EOF
put thirdparty-greet/greet.go <<'EOF'
// Package greet says hello.
package greet

// Hello returns a greeting for name.
func Hello(name string) string {
	return "Hello, " + name
}
EOF
quiet thirdparty-greet 'git init -q -b main && git config user.name Ana && git config user.email ana@example.com'
commit 'greet: Hello' '2026-10-01T10:00:00-03:00'

block tag-first
on thirdparty-greet 'git tag v0.1.0'
on thirdparty-greet 'git log --oneline --decorate'
publish v0.1.0

block proxy-layout
on thirdparty-greet 'find ~/thirdparty-proxy -type f | sort'
on thirdparty-greet 'cat ~/thirdparty-proxy/example.com/ana/greet/@v/v0.1.0.info; echo'

lab fresh thirdparty-app
put thirdparty-app/main.go <<'EOF'
package main

import (
	"fmt"

	"example.com/ana/greet"
)

func main() {
	fmt.Println(greet.Hello("Ana"))
}
EOF
quiet thirdparty-app 'go mod init example.com/app'

block sumdb
on thirdparty-app 'GOPROXY=file:///home/ana/thirdparty-proxy go get example.com/ana/greet@v0.1.0'

block first-get
on thirdparty-app "$P go get example.com/ana/greet@v0.1.0"
on thirdparty-app 'go mod tidy && go run .'
on thirdparty-app 'cat go.sum'

# The tag moved: a different commit is tagged v0.1.0 and published again, and
# the cached copy of v0.1.0 is removed so that the go command downloads it anew.
# Afterwards the tag is put back and the original published again.
put thirdparty-greet/greet.go <<'EOF2'
// Package greet says hello.
package greet

// Hello returns a greeting for name.
func Hello(name string) string {
	return "HELLO, " + name
}
EOF2
commit 'greet: louder' '2026-10-01T11:00:00-03:00'
block moved-tag
on thirdparty-greet 'git tag -f v0.1.0'
publish v0.1.0
for d in /home/ana/go/pkg/mod/example.com/ana /home/ana/go/pkg/mod/cache/download/example.com/ana; do
  chmod -R u+w "$d" && rm -rf "$d"
done
on thirdparty-app "$P go mod download example.com/ana/greet@v0.1.0"
quiet thirdparty-greet 'git reset -q --hard HEAD~1 && git tag -f v0.1.0'
publish v0.1.0
quiet thirdparty-app "$P go mod download example.com/ana/greet@v0.1.0"

# v1.0.0: nothing changes but the promise.
put thirdparty-greet/greet.go <<'EOF'
// Package greet says hello. From v1.0.0 on, its API only grows.
package greet

// Hello returns a greeting for name.
func Hello(name string) string {
	return "Hello, " + name
}
EOF
commit 'greet: declare the API stable' '2026-10-02T10:00:00-03:00'
quiet thirdparty-greet 'git tag v1.0.0'
publish v1.0.0

# v1.1.0: a new function, with a bug.
put thirdparty-greet/greet.go <<'EOF'
// Package greet says hello. From v1.0.0 on, its API only grows.
package greet

import "strings"

// Hello returns a greeting for name.
func Hello(name string) string {
	return "Hello, " + name
}

// HelloAll greets several people at once.
func HelloAll(names ...string) string {
	return "Hello, " + strings.Join(names, "")
}
EOF
commit 'greet: HelloAll' '2026-10-03T10:00:00-03:00'

block tag-minor
on thirdparty-greet 'git tag v1.1.0'
on thirdparty-greet 'git tag'
publish v1.1.0

block versions
on thirdparty-app "$P go list -m -versions example.com/ana/greet"
on thirdparty-app "$P go list -m -u all"

block upgrade-minor
on thirdparty-app "$P go get example.com/ana/greet@latest"
put thirdparty-app/main.go <<'EOF2'
package main

import (
	"fmt"

	"example.com/ana/greet"
)

func main() {
	fmt.Println(greet.Hello("Ana"))
	fmt.Println(greet.HelloAll("Ana", "Bia"))
}
EOF2
on thirdparty-app 'go run .'

# v1.1.1: the fix, and the retraction.
put thirdparty-greet/greet.go <<'EOF'
// Package greet says hello. From v1.0.0 on, its API only grows.
package greet

import "strings"

// Hello returns a greeting for name.
func Hello(name string) string {
	return "Hello, " + name
}

// HelloAll greets several people at once.
func HelloAll(names ...string) string {
	return "Hello, " + strings.Join(names, " and ")
}
EOF
block retract-edit
on thirdparty-greet 'go mod edit -retract=v1.1.0 && cat go.mod'
# The reason is a comment ana adds by hand at the end of the line.
put thirdparty-greet/go.mod <<'EOF'
module example.com/ana/greet

go 1.27

retract v1.1.0 // HelloAll runs the names together.
EOF
commit 'greet: fix HelloAll, retract v1.1.0' '2026-10-04T10:00:00-03:00'

block retract
on thirdparty-greet 'cat go.mod'
on thirdparty-greet 'git tag v1.1.1'
publish v1.1.1
on thirdparty-app "$P go list -m -u all"
on thirdparty-app "$P go list -m -versions example.com/ana/greet"
on thirdparty-app "$P go list -m -retracted -versions example.com/ana/greet"

block retract-get
on thirdparty-app "$P go get example.com/ana/greet@latest"
on thirdparty-app 'go run .'
on thirdparty-app "$P go get example.com/ana/greet@v1.1.0"
quiet thirdparty-app "$P go get example.com/ana/greet@v1.1.1"

block uax29-retract
on thirdparty-width 'go list -m -versions github.com/clipperhouse/uax29/v2'
on thirdparty-width 'go list -m -retracted -versions github.com/clipperhouse/uax29/v2'

# v2.0.0: Hello changes its signature, so the module path changes too.
put thirdparty-greet/greet.go <<'EOF'
// Package greet says hello.
package greet

import (
	"errors"
	"strings"
)

// Hello returns a greeting for name, and an error if name is empty.
func Hello(name string) (string, error) {
	if name == "" {
		return "", errors.New("greet: empty name")
	}
	return "Hello, " + name, nil
}

// HelloAll greets several people at once.
func HelloAll(names ...string) string {
	return "Hello, " + strings.Join(names, " and ")
}
EOF

block major
on thirdparty-greet 'go mod edit -module example.com/ana/greet/v2 -dropretract=v1.1.0 && cat go.mod'
commit 'greet: Hello reports an empty name (v2)' '2026-10-05T10:00:00-03:00'
on thirdparty-greet 'git tag v2.0.0'
publish v2.0.0
on thirdparty-greet 'find ~/thirdparty-proxy -name list | sort'

block major-wrong
on thirdparty-width 'go list -m -versions github.com/clipperhouse/uax29'
on thirdparty-width 'go get github.com/clipperhouse/uax29@v2.7.0'

put thirdparty-app/main.go <<'EOF'
package main

import (
	"fmt"

	"example.com/ana/greet"
	greetv2 "example.com/ana/greet/v2"
)

func main() {
	fmt.Println(greet.HelloAll("Ana", "Bia"))
	if _, err := greetv2.Hello(""); err != nil {
		fmt.Println(err)
	}
}
EOF

block major-both
on thirdparty-app "$P go get example.com/ana/greet/v2@v2.0.0"
on thirdparty-app 'go mod tidy && go run .'
on thirdparty-app 'go list -m all'

block major-noupgrade
on thirdparty-app "$P go list -m -u all"

lab fresh thirdparty-v1
block v1-suffix
on thirdparty-v1 'go mod init example.com/ana/greet/v1'

# ---------------------------------------------------------------- tidy up
lab fresh thirdparty-warm
rm -rf /home/ana/thirdparty-warm
