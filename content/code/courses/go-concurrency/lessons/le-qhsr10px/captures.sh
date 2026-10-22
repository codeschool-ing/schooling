#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of go-concurrency, as a script that
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
# into ~/ctx, and a `go mod init` there. The order of the two "stopped"
# lines in "cancel", and the step counts, vary from run to run; the lesson
# quotes one run of this script. The lookup's address is from the
# documentation range 192.0.2.0/24 and is never contacted.
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

lab fresh ctx
show cancellation.md ctx cancel.go
show deadlines.md ctx deadline.go
show deadlines.md ctx lost.go
show values.md ctx values.go
quiet ctx 'go mod init example.com/ctx'

block cancel
on ctx 'go run cancel.go'
block deadline
on ctx 'go run deadline.go'
block lost
on ctx 'go vet lost.go'
block values
on ctx 'go run values.go'
