#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of go-concurrency, as a script that
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
# into ~/clock (and ~/clock/mismatch), and a `go mod init` in each. The dates
# printed are fixed in the programs; the timings and the monotonic reading
# differ on every run, and the lesson quotes one run of this script. The size
# of the zone file and its date are Ubuntu 24.04's tzdata package as installed
# on the recording machine.
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

lab fresh clock
show durations.md clock dur.go
show durations.md clock/mismatch main.go
show durations.md clock mono.go
show timers-and-tickers.md clock timer.go
show timers-and-tickers.md clock slow.go
show zones.md clock zones.go
show zones.md clock layout.go
quiet clock 'go mod init example.com/clock'
quiet clock/mismatch 'go mod init example.com/clock/mismatch'

block durations
on clock 'go run dur.go'
on clock/mismatch 'go build .'
on clock 'go run mono.go'

block timers
on clock 'go run timer.go'
on clock 'go run slow.go'

block zones
on clock 'go run zones.go'
on clock 'ls -l /usr/share/zoneinfo/America/Sao_Paulo'
on clock 'dpkg -S /usr/share/zoneinfo/America/Sao_Paulo'
on clock 'go build -o z1 zones.go'
on clock 'go build -tags timetzdata -o z2 zones.go'
on clock 'wc -c z1 z2'
on clock 'go run layout.go'
