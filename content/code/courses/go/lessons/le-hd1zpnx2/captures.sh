#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of go, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and every program the lesson shows is
# written below, byte for byte, by `put`.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1 and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - lab.sh setup itself, which installs Go 1.27.1 in /usr/local/go from the
#     module proxy, because this sandbox cannot reach go.dev. The lesson shows
#     the official archive route and says it was not run here.
#   - ~/.profile is reset to the copy Ubuntu gives every new user
#     (/etc/skel/.profile) before ana adds her two lines, so running this twice
#     does not add them twice. lab.sh already puts both directories on the
#     PATH of every command it runs; the lesson shows the lines that do it for
#     a login, and proves them from a shell whose PATH has neither.
#   - the files of the two modules in ~/setup-work and of ~/setup-new, put below.
#   - `go env -w` writes ~/.config/go/env and `go env -u` removes the entry
#     again in the same block, so no other lesson runs with it.
# Nothing here is a timing. The download in block `proxy` really happens.
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

lab fresh setup
quiet setup 'cp /etc/skel/.profile ~/.profile'

block what-is-there
on setup 'go version'
on setup 'cat /usr/local/go/VERSION'
on setup 'ls /usr/local/go'
on setup 'ls /usr/local/go/bin'
on setup 'du -sh /usr/local/go'

block proxy
on setup 'curl -s https://proxy.golang.org/golang.org/toolchain/@v/v0.0.1-go1.27.1.linux-amd64.info; echo'
on setup 'curl -sL https://proxy.golang.org/golang.org/toolchain/@v/v0.0.1-go1.27.1.linux-amd64.zip | wc -c'

block profile
on setup "echo 'export PATH=\$PATH:/usr/local/go/bin' >> ~/.profile"
on setup "echo 'export PATH=\$PATH:\$HOME/go/bin' >> ~/.profile"
on setup 'tail -2 ~/.profile'
on setup 'PATH=/usr/bin:/bin; . ~/.profile; echo $PATH; command -v go gofmt'

block env
on setup 'go env GOROOT GOPATH GOBIN GOMODCACHE GOCACHE'

block help
on setup 'go help | head -27'

block env-w
on setup 'go env -changed'
on setup 'grep -v "^#" /usr/local/go/go.env'
on setup 'go env -w GOTOOLCHAIN=auto'
on setup 'cat ~/.config/go/env'
on setup 'go env GOTOOLCHAIN'
on setup 'go env -u GOTOOLCHAIN'

lab fresh setup-work
put setup-work/greet/greet.go <<'EOF'
// Package greet builds greetings.
package greet

// Hello returns a greeting for name.
func Hello(name string) string {
	return "Hello, " + name
}
EOF
put setup-work/hello/main.go <<'EOF'
package main

import (
	"fmt"

	"example.com/greet"
)

func main() {
	fmt.Println(greet.Hello("Ana"))
}
EOF
quiet setup-work/greet 'go mod init example.com/greet'
quiet setup-work/hello 'go mod init example.com/hello'

block gopath
on setup 'ls ~/go ~/go/pkg'
on setup "go help gopath | sed -n '21,24p'"
on setup-work/hello 'GO111MODULE=off go run .'

block work-fail
on setup-work 'find . -type f | sort'
on setup-work/hello 'go run .'

block work
on setup-work 'go work init ./hello'
on setup-work 'go work use ./greet'
on setup-work 'cat go.work'
on setup-work 'go run ./hello'
on setup-work/hello 'go run .'
on setup-work 'cat hello/go.mod'

block fail-path
on setup 'PATH=/usr/bin:/bin; go version; echo $?'
on setup 'PATH=/usr/bin:/bin; . ~/.profile; go version'

lab fresh setup-new
put setup-new/go.mod <<'EOF'
module example.com/new

go 1.28
EOF
put setup-new/main.go <<'EOF'
package main

func main() {}
EOF

block fail-toolchain
on setup-new 'go run .; echo $?'

lab fresh setup-proxy
quiet setup-proxy 'go mod init example.com/proxy'

block fail-proxy
on setup-proxy 'GOPROXY=https://proxy.invalid go get golang.org/x/text@latest; echo $?'
on setup-proxy 'go env GOPROXY'
