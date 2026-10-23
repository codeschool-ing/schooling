#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of go-production, as a script that
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
#   - lesson 1's internal/tally/tally.go and tools/genlog/main.go, placed from
#     le-03nqvqms into ~/unsafe, and `go mod init example.com/hits` there. The
#     lesson says it works on copies of those two files.
#   - this lesson's own files, placed from its sections.
#   - the cleanup at the end: the binaries in ~/unsafe/bin and the 20,000-line log.
# Timings and the numbers the broken programs print vary from run to run; the
# prose quotes the run pasted.
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
place1() { lab place le-03nqvqms "$1" "$2" "$3"; }
block() { printf '##### %s\n' "$1"; }

lab fresh unsafe
place1 subcommands internal/tally/tally.go unsafe >/dev/null
place1 arguments tools/genlog/main.go unsafe >/dev/null
quiet unsafe 'go mod init example.com/hits'

block layout
place sizes-and-alignment layout/main.go unsafe >/dev/null
on unsafe 'go run ./layout'

block fa
on unsafe 'go install golang.org/x/tools/go/analysis/passes/fieldalignment/cmd/fieldalignment@v0.52.0'
on unsafe 'fieldalignment ./...; echo $?'

block alive
place the-pointer-rules alive/main.go unsafe >/dev/null
on unsafe 'go run ./alive'
on unsafe 'go run ./alive'

block field
place the-pointer-rules field/main.go unsafe >/dev/null
on unsafe 'go run ./field'
on unsafe 'go vet ./field; echo $?'

block cast
place the-pointer-rules cast/main.go unsafe >/dev/null
on unsafe 'go build -o bin/cast ./cast && bin/cast 2>&1 | head -4; echo ${PIPESTATUS[0]}'
on unsafe 'go vet ./cast; echo $?'

block checkptr
on unsafe 'go build -gcflags=all=-d=checkptr -o bin/cast ./cast && bin/cast 2>&1 | head -3; echo ${PIPESTATUS[0]}'
on unsafe 'go build -race -o bin/cast ./cast && bin/cast 2>&1 | head -3; echo ${PIPESTATUS[0]}'

block zctest
place zero-copy-strings internal/zc/zc.go unsafe >/dev/null
place zero-copy-strings internal/zc/zc_test.go unsafe >/dev/null
on unsafe 'go test -race -count=1 ./internal/zc'

block bench
on unsafe 'go test -run "^$" -bench . -benchmem ./internal/zc'

block mutate
place zero-copy-strings mutate/main.go unsafe >/dev/null
on unsafe 'go build -o bin/mutate ./mutate && bin/mutate 2>&1 | head -5; echo ${PIPESTATUS[0]}'

block paths
place zero-copy-strings paths/main.go unsafe >/dev/null
on unsafe 'go run ./tools/genlog -n 20000 > access.log && go run ./paths access.log'

block paths-race
on unsafe 'go vet ./paths ./internal/zc && go run -race ./paths access.log'

block shame
on unsafe 'grep -r "hall of shame" "$(go env GOROOT)/src" --include=*.go | wc -l'
on unsafe 'grep -B7 "^func checkptrBase" "$(go env GOROOT)/src/runtime/checkptr.go"'

block arch
on unsafe 'GOARCH=386 go run ./layout'

block builder
on unsafe 'go doc -src strings.Builder.String'
on unsafe "go list -f '{{join .Imports \" \"}}' std | grep -cw unsafe; go list std | wc -l"

block end
quiet unsafe 'rm -rf bin access.log'
