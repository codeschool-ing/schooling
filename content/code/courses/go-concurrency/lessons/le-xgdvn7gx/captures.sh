#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of go-concurrency, as a script that
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
# into ~/goroutines, and a `go mod init` there. The timings, the order of the
# lines in "early" and the scheduler's counters in "schedtrace" differ on every
# run; the lesson quotes one run of this script. In "hog" the program that
# never yields is stopped by `timeout` after three seconds.
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

lab fresh goroutines
show starting-one.md goroutines early.go
show starting-one.md goroutines waited.go
show starting-one.md goroutines crash.go
show the-cost.md goroutines many.go
show the-scheduler.md goroutines busy.go
show the-scheduler.md goroutines hog.go
quiet goroutines 'go mod init example.com/goroutines'

block early
on goroutines 'go build -o early early.go'
on goroutines 'for i in 1 2 3 4 5; do ./early; done'

block waited
on goroutines 'go build -o waited waited.go'
on goroutines 'for i in 1 2 3 4 5; do ./waited; done'

block crash
on goroutines 'go run crash.go; echo "exit status: $?"'

block many
on goroutines 'go build -o many many.go'
on goroutines './many'
on goroutines 'ulimit -s'

block schedtrace
on goroutines 'go build -o busy busy.go'
on goroutines 'GODEBUG=schedtrace=500 ./busy'

block hog
on goroutines 'go build -o hog hog.go'
on goroutines './hog'
on goroutines 'GODEBUG=asyncpreemptoff=1 timeout 3 ./hog; echo "exit status: $?"'
