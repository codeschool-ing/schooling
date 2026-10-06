#!/usr/bin/env bash
# The terminal sessions quoted in lesson 38 of go, as a script that produces them.
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
#   - ~/mods-cache is emptied first. Block `tidy` runs `go mod tidy` with
#     GOMODCACHE pointing at it, written out in the command, so the download
#     shows as it does on a machine that never fetched golang.org/x/text. Every
#     other command uses the lab's ordinary module cache, ~/go/pkg/mod.
#   - `go mod download` is run quietly for the two versions of golang.org/x/text
#     the lesson uses, so that no transcript depends on whether another lesson
#     had already fetched them into ~/go/pkg/mod.
#   - ~/mods-unused and ~/mods-vendor start as copies of the module in
#     ~/mods-accents after its `go mod tidy`; the copies are made quietly.
# Real network traffic: the module proxy (proxy.golang.org) and the checksum
# database (sum.golang.org) answer every lookup below. The version numbers are
# the latest on the day the lab ran, and a later run may print newer ones.
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

lab fresh mods-cache
lab fresh mods-accents
put mods-accents/main.go <<'EOF'
// Command accents compares two spellings of one word.
package main

import (
	"fmt"

	"golang.org/x/text/unicode/norm"
)

func main() {
	typed := "cafe\u0301" // e, then a combining accent
	stored := "caf\u00e9" // one precomposed letter
	fmt.Printf("%+q is %d bytes\n", typed, len(typed))
	fmt.Printf("%+q is %d bytes\n", stored, len(stored))
	fmt.Println("equal as typed:  ", typed == stored)
	fmt.Println("equal after NFC: ", norm.NFC.String(typed) == stored)
}
EOF
quiet mods-accents 'go mod download golang.org/x/text@v0.42.0 golang.org/x/text@v0.41.0'

# ---------------------------------------------------------------- init
block init-noarg
on mods-accents 'go mod init'
on mods-accents 'go mod init "my accents"'

block init
on mods-accents 'go mod init example.com/accents'
on mods-accents 'cat go.mod'

lab fresh mods-dotless
put mods-dotless/main.go <<'EOF'
package main

import "hello/greet"

func main() {
	greet.Hi()
}
EOF
quiet mods-dotless 'go mod init example.com/dotless'

block dotless
on mods-dotless 'go build'

block versions
on mods-accents 'go list -m -json github.com/docker/docker@v28.5.2+incompatible'
on mods-accents 'cat ~/go/pkg/mod/cache/download/github.com/docker/docker/@v/v28.5.2+incompatible.mod'

# ---------------------------------------------------------------- tidy
block missing
on mods-accents 'go run .; echo $?'

block tidy
on mods-accents 'GOMODCACHE=~/mods-cache go mod tidy'
on mods-accents 'cat go.mod'
on mods-accents 'cat go.sum'
on mods-accents 'go run .'

block cache
on mods-accents 'ls ~/mods-cache/golang.org/x'
on mods-accents 'ls ~/mods-cache/golang.org/x/text@v0.42.0 | head -5'
on mods-accents 'stat -c "%A %n" ~/mods-cache/golang.org/x/text@v0.42.0/unicode/norm/normalize.go'
on mods-accents 'echo "// mine" >> ~/mods-cache/golang.org/x/text@v0.42.0/unicode/norm/normalize.go'

block sumdb
on mods-accents 'go env GOSUMDB'
on mods-accents 'curl -s https://sum.golang.org/lookup/golang.org/x/text@v0.42.0 | head -3'

block tamper
on mods-accents 'sed -i "s/h1:JbOZ/h1:JbOY/" go.sum'
on mods-accents 'go build; echo $?'
on mods-accents 'sed -i "s/h1:JbOY/h1:JbOZ/" go.sum && go build && echo built'
on mods-accents 'go mod verify'

block graph
on mods-accents 'go list -m all'
on mods-accents 'go mod graph'
on mods-accents 'go list -m golang.org/x/tools@latest'

lab fresh mods-unused
quiet mods-unused 'cp ~/mods-accents/go.mod ~/mods-accents/go.sum .'
put mods-unused/main.go <<'EOF'
// Command accents compares two spellings of one word.
package main

import "fmt"

func main() {
	typed := "cafe\u0301" // e, then a combining accent
	stored := "caf\u00e9" // one precomposed letter
	fmt.Printf("%+q is %d bytes\n", typed, len(typed))
	fmt.Printf("%+q is %d bytes\n", stored, len(stored))
	fmt.Println("equal as typed:  ", typed == stored)
}
EOF

block unused
on mods-unused 'go mod tidy -diff; echo $?'
on mods-unused 'go mod tidy && cat go.mod && wc -c go.sum'
on mods-unused 'go mod tidy -diff; echo $?'

# ---------------------------------------------------------------- vendor
lab fresh mods-vendor
quiet mods-vendor 'cp ~/mods-accents/go.mod ~/mods-accents/go.sum ~/mods-accents/main.go .'

block vendor
on mods-vendor 'go mod vendor'
on mods-vendor 'find vendor -type f | sort'
on mods-vendor 'cat vendor/modules.txt'

block vendor-size
on mods-vendor 'du -sh vendor ~/go/pkg/mod/golang.org/x/text@v0.42.0'
on mods-vendor 'find ~/go/pkg/mod/golang.org/x/text@v0.42.0 -type f | wc -l'
on mods-vendor 'du -k vendor/golang.org/x/text/unicode/norm/tables*'

block vendor-used
on mods-vendor 'go list -f "{{.Dir}}" golang.org/x/text/unicode/norm'
on mods-vendor 'GOPROXY=off GOMODCACHE=/nowhere go build -o accents . && ./accents'
on mods-vendor 'go list -m all'

block vendor-stale
on mods-vendor 'go mod edit -require=golang.org/x/text@v0.41.0'
on mods-vendor 'go build; echo $?'
on mods-vendor 'go mod tidy && go mod vendor && head -2 vendor/modules.txt'
on mods-vendor 'go build && echo built'
