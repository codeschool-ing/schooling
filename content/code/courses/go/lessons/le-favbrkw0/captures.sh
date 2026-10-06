#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of go, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and every program the lesson shows is
# written below, byte for byte, by `put`.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1 and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana wrote, put below, whose
# contents the lesson shows, and a `go mod init` in each directory. Before the
# block `force`, the go1.25.0 and go1.26.0 toolchains are deleted from ana's
# module cache, so that the go command has to download each again and says
# so; nothing else in the cache is touched. GOTOOLCHAIN=go1.24.0+auto makes the
# go command start from 1.24.0, as an older installation would; go1.24.0
# itself is never downloaded, because the go.mod asks for more.
#
# What comes from the network: the `.info` files and the toolchains come from
# the module proxy, proxy.golang.org, as they are on the day of the run. A new
# minor release of 1.26 or 1.27 would not change any line quoted here; a
# go1.25.15 would, and the Go release policy says there will not be one.
#
# The dates of go1, go1.5, go1.11 and go1.18 in section 01 are not in any
# transcript. They were read from the Go project's release history, which is
# the module golang.org/x/website: the block `dates-source` at the end fetches
# that module from the proxy (about 170 MB) and prints the lines they come
# from. The lesson does not quote it.
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
P=https://proxy.golang.org/golang.org/toolchain/@v

lab fresh history

block version
on history 'go version'
on history 'cat /usr/local/go/VERSION'
on history "go list -f '{{context.ReleaseTags}}' runtime"
on history 'sed -n 3,4p /usr/local/go/src/cmd/dist/README'

lab fresh history-loop
put history-loop/main.go <<'EOF'
// Command loop keeps a function from each turn of a loop and calls them afterwards.
package main

import "fmt"

func main() {
	var funcs []func() int
	for i := 0; i < 3; i++ {
		funcs = append(funcs, func() int { return i })
	}
	var got []int
	for _, f := range funcs {
		got = append(got, f())
	}
	fmt.Println(got)
}
EOF
quiet history-loop 'go mod init example.com/loop'

block loop
on history-loop 'go mod edit -go=1.21 && cat go.mod'
on history-loop 'go run .'
on history-loop 'go mod edit -go=1.22 && go run .'

block godebug
on history-loop "go mod edit -go=1.21 && go list -f '{{.DefaultGODEBUG}}' . | tr , '\\n' | grep http"
on history-loop "go mod edit -go=1.27.1 && go list -f '[{{.DefaultGODEBUG}}]' ."
on history-loop 'grep httpmuxgo121 /usr/local/go/src/internal/godebugs/table.go'

lab fresh history-generic
put history-generic/main.go <<'EOF'
// Command biggest uses a generic function.
package main

import "fmt"

func Biggest[T int | float64](a, b T) T {
	if a > b {
		return a
	}
	return b
}

func main() {
	fmt.Println(Biggest(3, 7), Biggest(2.5, 1.5))
}
EOF
quiet history-generic 'go mod init example.com/biggest'

block generic
on history-generic 'go mod edit -go=1.17 && go build; echo $?'
on history-generic 'go mod edit -go=1.18 && go run .'

block dates
on history "for v in 21 22 23 24 25 26 27; do curl -s $P/v0.0.1-go1.\$v.0.linux-amd64.info; echo; done"

block support
on history 'sed -n 3,5p /usr/local/go/SECURITY.md'

block minors
on history "for v in 1.25.14 1.26.7 1.27.0 1.26.8 1.27.1; do curl -s $P/v0.0.1-go\$v.linux-amd64.info; echo; done"
on history "curl -s $P/v0.0.1-go1.25.15.linux-amd64.info; echo"

lab fresh history-auto
put history-auto/main.go <<'EOF'
// Command which prints the release of Go that compiled it.
package main

import (
	"fmt"
	"runtime"
)

func main() {
	fmt.Println("compiled by", runtime.Version())
}
EOF
quiet history-auto 'go mod init example.com/which && go mod edit -go=1.25.0'
for V in v0.0.1-go1.25.0.linux-amd64 v0.0.1-go1.26.0.linux-amd64; do
  quiet history-auto "T=golang.org/toolchain; chmod -R u+w ~/go/pkg/mod/\$T@$V; rm -rf ~/go/pkg/mod/\$T@$V ~/go/pkg/mod/cache/download/\$T/@v/$V.*"
done

block force
on history-auto 'go env GOTOOLCHAIN'
on history-auto 'grep GOTOOLCHAIN /usr/local/go/go.env'
on history-auto 'GOTOOLCHAIN=go1.26.0 go version'
on history-auto 'GOTOOLCHAIN=go1.26.0 go version'

block auto
on history-auto 'cat go.mod'
on history-auto 'go run .'
on history-auto 'GOTOOLCHAIN=go1.24.0+auto go run .'

block toolchain-line
on history-auto 'go mod edit -go=1.22 -toolchain=go1.26.0 && cat go.mod'
on history-auto 'GOTOOLCHAIN=go1.24.0+auto go run .'
on history-auto 'go run .'

block dates-source
W=golang.org/x/website@v0.0.0-20261002204541-32881aa55f0d
on history "D=\$(go mod download -json $W | sed -n 's/.*\"Dir\": \"\\(.*\\)\",/\\1/p'); grep -E 'id=\"go1(\\.5)?\">' \$D/_content/doc/devel/release.html; grep -E 'Version\\{1, (11|18|21|22|27), 0\\}' \$D/internal/history/release.go"
