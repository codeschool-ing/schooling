#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of go-production, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it. Every program it runs is placed from
# a lesson's own .md by `lab.sh place`, so nothing here is a second copy.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1, gcc and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the four files of hits, placed from lesson 1 (le-03nqvqms) into ~/cross,
#     with `go mod init example.com/hits` and access.log written by genlog
#     -n 20000, exactly as lesson 1 shows them.
#   - who/main.go, twice/main.go and release.sh, placed from this lesson's
#     what-breaks and many-targets sections, and `go mod init` in ~/cross/who
#     and ~/cross/twice, which the lesson names.
#   - qemu-user-static, installed on the lab machine from Ubuntu's archive
#     before this script runs. The lesson shows the apt line and says it was
#     not run here. binfmt_misc is not registered on this machine, which is
#     why `./hits-arm64` fails and qemu is called by name.
# The one timing is `go test`'s own line under emulation.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
LAB_SH=${LAB_SH:-$HERE/../../lab.sh}
LESSON=$(basename "$HERE")
lab() { bash "$LAB_SH" "$@"; }
on() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "$*" 2>&1 || true; }
quiet() { lab exec "$1" "$2" >/dev/null 2>&1 || true; }
place() { lab place "$LESSON" "$1" "$2" "$3"; }
block() { printf '##### %s\n' "$1"; }

block setup
lab fresh cross
lab place le-03nqvqms arguments tools/genlog/main.go cross
lab place le-03nqvqms subcommands internal/tally/tally.go cross
lab place le-03nqvqms subcommands main.go cross
lab place le-03nqvqms output-and-exit-codes main_test.go cross
quiet cross 'go mod init example.com/hits'
quiet cross 'go run ./tools/genlog -n 20000 > access.log'

block targets
on cross 'go env GOOS GOARCH'
on cross 'go tool dist list | wc -l'
on cross 'go tool dist list | grep -E "^(linux|darwin|windows)/"'
on cross "go tool dist list -json | grep -c '\"FirstClass\": true'"

block build
on cross 'go build -o hits .'
on cross 'GOOS=linux GOARCH=arm64 go build -o hits-arm64 .'
on cross 'GOOS=darwin GOARCH=arm64 go build -o hits-mac .'
on cross 'GOOS=windows GOARCH=amd64 go build .'
on cross 'ls'
on cross 'file hits hits-arm64 hits-mac hits.exe | cut -d, -f1,2,4'
on cross 'stat -c "%s bytes  %n" hits hits-arm64 hits-mac hits.exe'
on cross 'strings hits-mac | grep libSystem'

block arm
on cross './hits-arm64 count access.log; echo $?'
on cross 'qemu-aarch64-static ./hits-arm64 count access.log'
on cross 'diff <(./hits top -n 8 access.log) <(qemu-aarch64-static ./hits-arm64 top -n 8 access.log) && echo identical'
on cross 'go version -m hits-arm64'
on cross 'GOARCH=arm64 go test -count=1 .'
on cross 'GOARCH=arm64 go test -count=1 -exec qemu-aarch64-static .'

block cgo
on cross 'go env CGO_ENABLED; GOARCH=arm64 go env CGO_ENABLED; GOOS=windows go env CGO_ENABLED'
place what-breaks who/main.go cross
quiet cross/who 'go mod init example.com/who'
on cross/who 'go build -o who . && GOARCH=arm64 go build -o who-arm64 .'
on cross/who 'file who who-arm64 | cut -d, -f1,2,4'
on cross/who './who; qemu-aarch64-static ./who-arm64'
on cross/who "go list -f '{{.CgoFiles}}' os/user; GOARCH=arm64 go list -f '{{.CgoFiles}}' os/user"
place what-breaks twice/main.go cross
quiet cross/twice 'go mod init example.com/twice'
on cross/twice 'go build -o twice . && ./twice'
on cross/twice 'GOARCH=arm64 go build -o twice-arm64 .; echo $?'
on cross/twice 'CGO_ENABLED=1 GOARCH=arm64 go build -o twice-arm64 . 2>&1 | head -4'

block levels
on cross 'GOARCH=arm go env GOARM'
on cross 'GOARCH=arm GOARM=6 go build -o hits-armv6 . && file hits-armv6 | cut -d, -f1,2'
on cross 'qemu-arm-static ./hits-armv6 top -n 2 access.log'
on cross 'go env GOAMD64'
on cross 'GOAMD64=v3 go build -o hits-v3 . && go version -m hits-v3 | grep GOAMD64'
on cross './hits-v3 top -n 2 access.log'
on cross 'qemu-x86_64-static -cpu Nehalem ./hits-v3 top -n 2 access.log; echo $?'
on cross 'qemu-x86_64-static -cpu Nehalem ./hits top -n 2 access.log; echo $?'

block release
place many-targets release.sh cross
on cross 'sh release.sh'
on cross 'stat -c "%s bytes  %n" release/*'
on cross 'file release/* | cut -d, -f1,2'
on cross 'go version -m hits | grep CGO_ENABLED; go version -m release/hits-linux-amd64 | grep CGO_ENABLED'
on cross 'du -sb release'
on cross 'qemu-aarch64-static release/hits-linux-arm64 top -n 1 access.log'
