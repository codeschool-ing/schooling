#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of go-concurrency, as a script that
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
# into ~/waitonce, and a `go mod init` there. oncevalues.go writes token.txt
# itself, so it is removed before that run. The order of the downloads in
# "wait", the goroutine numbers and addresses in the two crashes, and the
# first visitor of each page in "syncmap" vary from run to run; the lesson
# quotes one run of this script.
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

lab fresh waitonce
show waitgroup.md waitonce wait.go
show waitgroup.md waitonce late.go
show waitgroup.md waitonce negative.go
show once.md waitonce once.go
show once.md waitonce oncevalues.go
show sync-map.md waitonce crash.go
show sync-map.md waitonce syncmap.go
quiet waitonce 'go mod init example.com/waitonce'

block wait
on waitonce 'go run wait.go'
block late
on waitonce 'go run late.go'
on waitonce 'go vet late.go'
block negative
on waitonce 'go run negative.go'
block once
on waitonce 'go run once.go'
block oncevalues
quiet waitonce 'rm -f token.txt'
on waitonce 'go run oncevalues.go'
block crash
on waitonce 'go run crash.go'
block syncmap
on waitonce 'go run syncmap.go'
