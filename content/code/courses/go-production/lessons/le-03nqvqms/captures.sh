#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of go-production, as a script that
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
#   - lab.sh setup itself, which installs Go 1.27.1 the way the go course's
#     lab does (from the module proxy, since this sandbox cannot reach go.dev)
#     and gcc from Ubuntu's archive. The lesson shows the steps in brief and
#     names the lesson that shows them in full.
#   - the files of ~/args and ~/hits, placed from the lesson's sections.
#   - `go mod init` in ~/hits and ~/args, which the lesson shows once.
#   - `go clean -testcache` before `go test`, so the run is a run and not a
#     line from the cache.
#   - in block fail-gcc, a directory ~/nogcc holding links to everything in
#     /usr/bin except gcc and cc, so that a PATH without a C compiler can be
#     shown on a machine that has one.
# Nothing here is a timing.
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

block check
lab fresh hits
on hits 'go version'
on hits 'command -v go gofmt gcc'
on hits 'gcc --version | head -1'
on hits 'go env GOROOT GOPATH CGO_ENABLED'
on hits 'echo $PATH | tr : "\n" | grep go'

block fail-path
on hits 'PATH=/usr/bin:/bin; go version; echo $?'

block fail-gcc
lab fresh nogcc
quiet nogcc 'for f in /usr/bin/*; do case ${f##*/} in gcc|cc|gcc-1[0-9]|x86_64-linux-gnu-gcc*|c89-gcc|c99-gcc) ;; *) ln -s "$f" .;; esac; done'
lab fresh race
lab put race/main.go <<'EOF'
package main

func main() {}
EOF
quiet race 'go mod init example.com/race'
on race 'PATH=/usr/local/go/bin:$HOME/nogcc; go env CGO_ENABLED; go build -race; echo $?'
on race 'go build -race && echo built'

block args
lab fresh args
place arguments main.go args
quiet args 'go mod init example.com/args'
on args 'go build -o args .'
on args './args -v -n 3 jan.log feb.log'
on args './args -n=3 "two words" feb.log'
on args './args --n 3 jan.log -v'
on args './args -- -v'
on args './args -n three; echo $?'
on args './args -h; echo $?'

block genlog
place arguments tools/genlog/main.go hits
quiet hits 'go mod init example.com/hits'
on hits 'cat go.mod'
on hits 'go run ./tools/genlog -n 5'
on hits 'go run ./tools/genlog -n 3 -seed 7'
on hits 'go run ./tools/genlog -n 20000 > access.log; wc -l access.log'

block build
place subcommands internal/tally/tally.go hits
place subcommands main.go hits
on hits 'find . -name "*.go" | sort'
on hits 'go build -o hits . && stat -c "%s bytes  %n" hits'
on hits './hits count access.log'
on hits './hits top -n 5 access.log'
on hits './hits top -json access.log'

block usage
on hits './hits; echo $?'
on hits './hits cont access.log; echo $?'
on hits './hits top -h; echo $?'
on hits './hits top -n five access.log; echo $?'

block streams
on hits './hits count nope.log; echo $?'
on hits './hits count nope.log 2>/dev/null; echo $?'
on hits './hits top a.log b.log 2>&1 >/dev/null | wc -l'
on hits 'echo "not a log line" | ./hits count; echo $?'
on hits 'go run ./tools/genlog -n 1000 -seed 3 | ./hits top -n 2'
on hits './hits count -json - < access.log'
on hits './hits top -n 8 access.log | head -2; echo ${PIPESTATUS[@]}'
on hits 'go build -o genlog ./tools/genlog && ./genlog -n 1000000 | head -1; echo ${PIPESTATUS[@]}'

block test
place output-and-exit-codes main_test.go hits
quiet hits 'go clean -testcache'
on hits 'go test -v .'
