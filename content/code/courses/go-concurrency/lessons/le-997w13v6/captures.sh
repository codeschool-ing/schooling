#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of go-concurrency, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1, gcc and the student, ana
#   sudo bash captures.sh
#
# THE PROGRAMS ARE THE LESSON'S OWN. Each file below is taken out of the
# section that shows it, by `lab.sh fence`, so the program that ran is the one
# the student reads. What is STAGED rather than typed: those files, written
# into ~/races (a second version over the first where the lesson edits a
# file), a `go mod init` there, and a `go clean -testcache` so that the
# first `go test` runs rather than reporting an earlier run of the same
# files. Timings, addresses, goroutine numbers, the counts `collect` keeps and
# the order of the race reports differ on every run; the lesson quotes one
# run of this script.
#
# Recorded on Ubuntu 24.04, four processors, with go1.27.1 linux/amd64 and
# gcc 13.3.0, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
LAB=$HERE/../../lab.sh
lab() { bash "$LAB" "$@"; }
on() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "$*" 2>&1 || true; }
quiet() { lab exec "$1" "$2" >/dev/null 2>&1 || true; }
show() { lab fence "$HERE/$1" "$3" ${4:-} | lab put "$2/$3" || exit 1; }
block() { printf '##### %s\n' "$1"; }

lab fresh races
show running-it.md races cost.go
show reading-the-output.md races stats.go
show reading-the-output.md races tally.go
show fixing.md races collect.go 1
show in-tests.md races cache/cache.go 1
show in-tests.md races cache/cache_test.go
quiet races 'go mod init example.com/races'
quiet races 'go clean -testcache'

block cost
on races 'go build -o cost cost.go'
on races 'go build -race -o cost-race cost.go'
on races 'ls -l cost cost-race'
on races 'time ./cost'
on races 'time ./cost-race'

block stats
on races 'go run stats.go'
on races 'go run -race stats.go'

block tally
on races 'for i in 1 2 3; do go run tally.go; done'
on races 'GORACE=halt_on_error=1 go run -race tally.go; echo "exit: $?"'

show fixing.md races stats.go
block stats-fixed
on races 'go run -race stats.go'

show fixing.md races tally.go
block tally-fixed
on races 'go run -race tally.go'

block collect
on races 'for i in 1 2 3; do go run collect.go; done'
on races 'go run -race collect.go 2>&1 | tail -3'

show fixing.md races collect.go 2
block collect-fixed
on races 'go run -race collect.go'

block cache
on races 'go test ./cache'
on races 'go test -count=5 ./cache'

block cache-race
on races 'go test -race ./cache > race.log 2>&1; echo $?'
on races 'head -17 race.log'

block cache-verdict
on races 'tail -5 race.log'

show in-tests.md races cache/cache.go 2
block cache-fixed
on races 'go test -race -count=20 ./cache'
