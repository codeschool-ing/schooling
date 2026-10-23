#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of go-production, as a script that
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
#   - the files of ~/cli-hits, ~/std-hits and ~/cobra-cmp: tools/genlog and
#     internal/tally placed from lesson 1, the rest from this lesson.
#   - `go mod init` in ~/std-hits and ~/cobra-cmp, which the lesson shows once,
#     in ~/cli-hits.
#   - access.log in ~/cli-hits, written by genlog as lesson 1 shows, and copied
#     into the other two directories.
#   - GOMODCACHE pointing at an empty directory of this lesson's own for the
#     two `go get` lines and the `go mod tidy`, so that their "downloading"
#     lines appear on every run and not only on the first. The builds use ana's ordinary cache
#     in ~/go/pkg/mod, because a binary records the paths of the files it was
#     compiled from and its size moves with them. The ordinary cache already
#     holds both modules from an earlier run; on a first run each build would
#     print its own "downloading" line.
#   - after the run with the ExitErrHandler line deleted, main.go placed again,
#     which the lesson tells the student to do by putting the line back.
#   - `go clean -testcache` before `go test`, so the run is a run and not a
#     line from the cache.
# The only timings are the ones `go test` prints after `ok`.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
LAB_SH=${LAB_SH:-$HERE/../../lab.sh}
LESSON=$(basename "$HERE")
MODCACHE='$HOME/.cache/le-jnxddvfk-mod'
# A lab call that fails stops the script.
lab() { bash "$LAB_SH" "$@" || { echo "captures.sh: lab $* failed" >&2; exit 1; }; }
# `lab.sh place` exits 0 even when it finds no block, and leaves an empty file:
# every transcript after it would then record the wrong program. So the block
# is looked up with `show` first, and a miss stops the script.
placefrom() {
  bash "$LAB_SH" show "$1" "$2" "$3" >/dev/null || { echo "captures.sh: no block for $3 in $1/$2" >&2; exit 1; }
  lab place "$@"
}
on() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; bash "$LAB_SH" exec "$d" "$*" 2>&1 || true; }
# fetch prints the command as typed and runs it against a fresh module cache.
fetch() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; bash "$LAB_SH" exec "$d" "export GOMODCACHE=$MODCACHE; $*" 2>&1 || true; }
quiet() { bash "$LAB_SH" exec "$1" "$2" >/dev/null 2>&1 || true; }
place() { placefrom "$LESSON" "$1" "$2" "$3"; }
block() { printf '##### %s\n' "$1"; }

quiet . "chmod -R u+w $MODCACHE 2>/dev/null; rm -rf $MODCACHE"

block shape
lab fresh cli-hits
placefrom le-03nqvqms arguments tools/genlog/main.go cli-hits
placefrom le-03nqvqms subcommands internal/tally/tally.go cli-hits
on cli-hits 'go mod init example.com/hits'
place the-shape main.go cli-hits
place the-shape report.go cli-hits
fetch cli-hits 'go get github.com/urfave/cli/v3@v3.14.0'
fetch cli-hits 'go mod tidy && cat go.mod'
quiet cli-hits 'go run ./tools/genlog -n 20000 > access.log'
on cli-hits 'find . -name "*.go" | sort'
on cli-hits 'go build -o hits . && stat -c "%s bytes  %n" hits'
on cli-hits './hits count access.log'
on cli-hits './hits top -n 5 access.log'

block flags
on cli-hits './hits top access.log -n 2'
on cli-hits './hits top --limit 2 -json access.log'
on cli-hits 'HITS_TOP=4 ./hits top access.log'
on cli-hits 'HITS_TOP=4 ./hits top -n 2 access.log'
on cli-hits './hits top -n 0 access.log 2>&1 | head -1'
on cli-hits './hits top -h'
on cli-hits 'go run ./tools/genlog -n 1000 -seed 3 | ./hits top -n 2 -'
on cli-hits './hits top -- -n'
on cli-hits './hits top help | head -2'

block errors-v1
on cli-hits './hits top -n five access.log; echo $?'
on cli-hits './hits top -n five access.log 2>/dev/null | head -3'
on cli-hits './hits cont access.log; echo $?'
on cli-hits './hits >/dev/null; echo $?'
on cli-hits './hits top a.log b.log; echo $?'

block errors-v2
place help-errors-and-exit main.go cli-hits
on cli-hits 'go build -o hits .'
on cli-hits './hits top -n five access.log; echo $?'
on cli-hits './hits top -n five access.log 2>/dev/null | wc -c'
on cli-hits './hits cont access.log; echo $?'
on cli-hits './hits; echo $?'
on cli-hits './hits top a.log b.log; echo $?'
on cli-hits './hits count nope.log; echo $?'
on cli-hits './hits --help'
on cli-hits './hits help nope; echo $?'
on cli-hits 'HITS_TOP=x ./hits top access.log; echo $?'
on cli-hits './hits completion bash | head -1'
on cli-hits './hits --generate-shell-completion'

block test
place help-errors-and-exit main_test.go cli-hits
quiet cli-hits 'go clean -testcache'
on cli-hits 'go test -v .'
on cli-hits "sed -i '/ExitErrHandler/d' main.go; go test ."
place help-errors-and-exit main.go cli-hits
quiet cli-hits 'go clean -testcache'
on cli-hits 'go test .'

block choosing
lab fresh std-hits
placefrom le-03nqvqms subcommands internal/tally/tally.go std-hits
placefrom le-03nqvqms subcommands main.go std-hits
quiet std-hits 'go mod init example.com/hits'
quiet std-hits 'cp ../cli-hits/access.log .'
lab fresh cobra-cmp
placefrom le-03nqvqms subcommands internal/tally/tally.go cobra-cmp
place choosing main.go cobra-cmp
quiet cobra-cmp 'go mod init example.com/hits'
quiet cobra-cmp 'cp ../cli-hits/access.log .'
fetch cobra-cmp 'go get github.com/spf13/cobra@v1.10.2'
on cobra-cmp 'go build -o hits . && ./hits top -n 2 access.log'
on cobra-cmp './hits tpo; echo $?'
on cobra-cmp './hits completion bash | head -1'
on std-hits 'go build -o hits . && stat -c "%s bytes  %n" hits ../cli-hits/hits ../cobra-cmp/hits'
on std-hits 'go list -m all'
on cli-hits 'go list -m all'
on cobra-cmp 'go list -m all'
on cli-hits 'go list -deps . | grep "\."'
on cobra-cmp 'go list -deps . | grep "\."'
on std-hits 'wc -l main.go ../cli-hits/main.go ../cli-hits/report.go ../cobra-cmp/main.go'
on std-hits './hits top access.log -n 2; echo $?'

quiet . "chmod -R u+w $MODCACHE 2>/dev/null; rm -rf $MODCACHE"
