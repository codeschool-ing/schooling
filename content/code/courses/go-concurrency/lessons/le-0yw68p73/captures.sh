#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of go-concurrency, as a script that
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
# into ~/fanin, and a `go mod init` there. The interleaving of the merged
# readings, the timings, the count of zero values in "spin" and the goroutine
# numbers in the crash reports differ from run to run; the lesson quotes one
# run of this script.
#
# Recorded on Ubuntu 24.04, four processors, with go1.27.1 linux/amd64,
# TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
LAB=$HERE/../../lab.sh
lab() { bash "$LAB" "$@"; }
on() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "$*" 2>&1 || true; }
quiet() { lab exec "$1" "$2" >/dev/null 2>&1 || true; }
show() { lab fence "$HERE/$1" "$3" ${4:-} | lab put "$2/$3" || exit 1; }
block() { printf '##### %s\n' "$1"; }

lab fresh fanin
show merge.md fanin/merge merge.go
show select-merge.md fanin/spin spin.go
show select-merge.md fanin/pair pair.go
show closing.md fanin/early early.go
show closing.md fanin/never never.go
quiet fanin 'go mod init example.com/fanin'
quiet fanin 'go build ./...'

block merge
on fanin 'go run ./merge'

block spin
on fanin 'go run ./spin'

block pair
on fanin 'go run ./pair'

block early
on fanin 'go run ./early'

block never
on fanin 'go run ./never'
