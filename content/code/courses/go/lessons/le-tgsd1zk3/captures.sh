#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of go, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and every program the lesson shows is
# written below, byte for byte, by `put`.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1 and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana wrote, put below, whose
# contents the lesson shows, and a `go mod init` in each directory. The
# `go list -m` lookups ask the module proxy, proxy.golang.org, so the versions
# they print are whatever was latest on the day of the run. The timings differ
# on every run; the lesson quotes one run of this script. The machine has four
# processors and a C compiler, gcc, installed; the second fact decides how the
# program in ~/why-net is linked.
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

lab fresh why
put why/main.go <<'EOF'
// Command why says which system it was compiled for.
package main

import (
	"fmt"
	"runtime"
)

func main() {
	fmt.Println("compiled for", runtime.GOOS+"/"+runtime.GOARCH, "by", runtime.Version())
}
EOF
quiet why 'go mod init example.com/why'

block big-build
on why 'nproc'
on why 'go list -deps cmd/go | wc -l'
on why 'go clean -cache'
on why 'time go build -o /dev/null cmd/go'
on why 'time go build -o /dev/null cmd/go'

block build
on why 'go clean -cache'
on why 'time go build'
on why './why'
on why 'wc -c main.go why'

block static
on why 'file why'
on why 'ldd why'
on why 'readelf -d why'
on why 'readelf -d /bin/ls | grep NEEDED'

block cross
on why 'time GOOS=windows GOARCH=amd64 go build -o why.exe'
on why 'GOOS=darwin GOARCH=arm64 go build -o why-mac'
on why 'GOOS=linux GOARCH=arm64 go build -o why-arm64'
on why 'file why.exe why-mac why-arm64'
on why './why-arm64'

block targets
on why 'go tool dist list | wc -l'
on why 'go tool dist list | grep linux'

lab fresh why-net
put why-net/main.go <<'EOF'
// Command lookup resolves a host name.
package main

import (
	"fmt"
	"net"
)

func main() {
	addrs, err := net.LookupHost("localhost")
	fmt.Println(addrs, err)
}
EOF
quiet why-net 'go mod init example.com/lookup'

block cgo
on why-net 'go env CGO_ENABLED'
on why-net 'go build && ./lookup'
on why-net 'file lookup'
on why-net 'readelf -d lookup | grep NEEDED'
on why-net 'CGO_ENABLED=0 go build && file lookup'

lab fresh why-keywords
put why-keywords/main.go <<'EOF'
// Command keywords lists the keywords of Go, as the standard library's parser knows them.
package main

import (
	"fmt"
	"go/token"
	"strings"
)

func main() {
	var words []string
	for tok := token.ILLEGAL; tok <= token.TILDE; tok++ {
		if tok.IsKeyword() {
			words = append(words, tok.String())
		}
	}
	fmt.Println(strings.Join(words, " "))
	fmt.Println(len(words), "keywords")
}
EOF
quiet why-keywords 'go mod init example.com/keywords'

block keywords
on why-keywords 'go run .'

lab fresh why-mix
put why-mix/main.go <<'EOF'
package main

import "fmt"

func main() {
	items := 3
	price := 2.5
	fmt.Println(items * price)
}
EOF
quiet why-mix 'go mod init example.com/mix'

block mix
on why-mix 'go build; echo $?'

block who
on why 'go list -m k8s.io/kubernetes@latest github.com/hashicorp/terraform@latest'
on why 'go list -m github.com/prometheus/prometheus@latest github.com/docker/docker@latest'
