#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of go-concurrency, as a script that
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
# into ~/buffers, and a `go mod init` there. stuck-fixed.go is made in the
# transcript itself, by the sed the lesson shows. The times printed by "meet"
# and "buffered" are rounded to ten milliseconds and can differ by one step
# between runs, and the order of two lines printed at the same instant can
# swap; the lesson quotes one run of this script.
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

lab fresh buffers
show rendezvous.md buffers meet.go
show buffers.md buffers buffered.go
show deadlock.md buffers stuck.go
show deadlock.md buffers partial.go
quiet buffers 'go mod init example.com/buffers'

block meet
on buffers 'go run meet.go'

block buffered
on buffers 'go run buffered.go'

block stuck
on buffers 'go run stuck.go'
on buffers 'go vet stuck.go && echo "vet: no complaint"'
on buffers "sed 's/make(chan int)/make(chan int, 1)/' stuck.go > stuck-fixed.go"
on buffers 'go run stuck-fixed.go'

block partial
on buffers 'go run partial.go; echo "exit status: $?"'
