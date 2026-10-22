#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of go-production, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it. Every program it runs is placed from
# the lesson's own .md by `lab.sh place`, so nothing here is a second copy.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1, gcc and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - `go mod init example.com/cgo` in ~/cgo, and `mkdir` of each program's
#     directory, which the lesson says in words.
#   - tools/genlog/main.go, placed from lesson 1's `arguments` section, as
#     lesson 1 prints it.
#   - zlib's development files (Ubuntu's zlib1g-dev), already installed on the
#     lab machine; the lesson names the package to install.
#   - `go mod tidy` after `go get`, so that go.mod lists go-sqlite3 as direct.
#   - the private build cache /tmp/cgo-cold, emptied before each command that
#     uses it and removed afterwards, so that a build can be timed cold without
#     touching ana's own cache. The lesson says so where it is visible.
# The timings in blocks cost and give-up are real and vary between runs; the
# lesson quotes the run it pasted and says which ratios are stable.
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
cold() { quiet cgo 'rm -rf /tmp/cgo-cold'; }

block first
lab fresh cgo
quiet cgo 'go mod init example.com/cgo && mkdir -p first gzlines rules pinned each cost threads gzgo sq lookup crash'
on cgo 'go env CC CXX CGO_ENABLED'
place calling-c first/main.go cgo
cold
on cgo 'GOCACHE=/tmp/cgo-cold go build -x -o bin/ ./first 2> build.log && bin/first'
on cgo 'wc -l < build.log'
on cgo "grep b001 build.log | grep -v '#' | grep -E '^([A-Z_]+=[^ ]* )*(gcc|[^ ]*/(cgo|compile|link)) ' | sed -E 's/^([A-Z_]+=[^ ]* )+//' | awk '{print \$1, \$(NF-1), \$NF}'"
cold

block mistakes
on cgo "mkdir -p noconv && sed 's/C.long(total), C.int(n)/total, n/' first/main.go > noconv/main.go && go build -o bin/ ./noconv"
on cgo 'mkdir -p nolm && grep -v LDFLAGS first/main.go > nolm/main.go && go build -o bin/ ./nolm 2>&1 | grep -E "running gcc|undefined"'
quiet cgo 'rm -rf noconv nolm'

block gzlines
lab place le-03nqvqms arguments tools/genlog/main.go cgo
place memory-across-the-line gzlines/main.go cgo
on cgo 'go run ./tools/genlog -n 20000 > access.log && gzip -k access.log && head -c 3000 access.log.gz > cut.gz'
on cgo 'go build -o bin/ ./gzlines && bin/gzlines access.log.gz'
on cgo 'bin/gzlines cut.gz; echo $?'
on cgo 'bin/gzlines nope.gz; echo $?'
on cgo 'bin/gzlines access.log'

block rules
place memory-across-the-line rules/main.go cgo
on cgo 'go vet ./rules && go build -o bin/ ./rules && bin/rules; echo $?'
on cgo 'GODEBUG=cgocheck=0 bin/rules; echo $?'
place memory-across-the-line pinned/main.go cgo
on cgo 'go build -o bin/ ./pinned && bin/pinned'

block each
place memory-across-the-line each/each.h cgo
place memory-across-the-line each/each.c cgo
place memory-across-the-line each/main.go cgo
on cgo 'ls each && go build -o bin/ ./each && bin/each access.log'

block cost
place the-cost-per-call cost/cost.go cgo
place the-cost-per-call cost/cost_test.go cgo
on cgo 'go test -run=^$ -bench=. -count=1 ./cost'

block threads
place the-cost-per-call threads/main.go cgo
on cgo 'go build -o bin/ ./threads && bin/threads && bin/threads c'

block give-up
place what-you-give-up gzgo/main.go cgo
on cgo 'go build -o bin/ ./gzgo && file bin/gzlines bin/gzgo | cut -d, -f1,4'
on cgo "ldd bin/gzlines | awk '{print \$1}'"
on cgo 'bin/gzgo access.log.gz cut.gz; echo $?'

block cross
on cgo 'GOARCH=arm64 go build -o bin/gzlines-arm64 ./gzlines; echo $?'
on cgo 'CGO_ENABLED=1 GOARCH=arm64 CC=aarch64-linux-gnu-gcc go build -o bin/gzlines-arm64 ./gzlines; echo $?'
on cgo 'GOARCH=arm64 go build -o bin/gzgo-arm64 ./gzgo && qemu-aarch64-static bin/gzgo-arm64 access.log.gz'

block static
on cgo 'go build -ldflags=-extldflags=-static -o bin/gzlines-static ./gzlines && file bin/gzlines-static | cut -d, -f1,4 && bin/gzlines-static access.log.gz'
on cgo 'stat -c "%s bytes  %n" bin/gzlines bin/gzlines-static bin/gzgo'

block sqlite
place what-you-give-up sq/main.go cgo
on cgo 'go get github.com/mattn/go-sqlite3@v1.14.52'
quiet cgo 'go mod tidy'
on cgo 'cd $(go env GOMODCACHE)/github.com/mattn/go-sqlite3@v1.14.52 && wc -l sqlite3-binding.c && head -4 sqlite3-binding.c | tail -2'
cold
on cgo 'TIMEFORMAT="%R s"; time GOCACHE=/tmp/cgo-cold go build -o /dev/null ./gzgo; time GOCACHE=/tmp/cgo-cold go build -o bin/ ./sq; time GOCACHE=/tmp/cgo-cold go build -o /dev/null ./sq'
cold
on cgo 'bin/sq; ldd bin/sq | awk "{print \$1}"'
on cgo 'CGO_ENABLED=0 go build -o bin/sq-nocgo ./sq && bin/sq-nocgo; echo $?'

block tags
place when-it-is-worth-it lookup/main.go cgo
on cgo 'go build -o bin/ ./lookup && file bin/lookup | cut -d, -f1,4 && bin/lookup'
on cgo 'go build -tags netgo,osusergo -o bin/lookup-pure ./lookup && file bin/lookup-pure | cut -d, -f1,4 && bin/lookup-pure'
on cgo 'go list -f "{{.ImportPath}} {{.CgoFiles}}" net os/user'
on cgo 'go list -tags netgo,osusergo -f "{{.ImportPath}} {{.CgoFiles}}" net os/user'

block crash
place when-it-is-worth-it crash/main.go cgo
on cgo 'go build -o bin/ ./crash && bin/crash 2>&1 | head -4; echo ${PIPESTATUS[0]}'
