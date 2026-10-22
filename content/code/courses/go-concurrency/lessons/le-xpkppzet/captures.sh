#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of go-concurrency, as a script that
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
# into ~/leaks, and a `go mod init` there. The servers are time.Sleep calls,
# so no network is involved; the counts are the same on every run, and the
# program counters in the profiles depend only on the source and the
# toolchain.
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

lab fresh leaks
show how-they-leak.md leaks first.go
show how-they-leak.md leaks early.go
show finding-them.md leaks find.go
show finding-them.md leaks hidden.go
show avoiding.md leaks buffered.go
show avoiding.md leaks done.go
quiet leaks 'go mod init example.com/leaks'

block first
on leaks 'go run first.go'
block early
on leaks 'go run early.go'
block find
on leaks 'go run find.go'
block leakprofile
on leaks 'go run find.go goroutineleak'
block hidden
on leaks 'go run hidden.go'
block buffered
on leaks 'go run buffered.go'
block done
on leaks 'go run done.go'
