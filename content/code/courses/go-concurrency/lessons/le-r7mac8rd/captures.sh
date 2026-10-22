#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of go-concurrency, as a script that
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
# into ~/propagate, and a `go mod init` there. The timings differ by a few
# milliseconds on every run; the lesson quotes one run of this script.
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

lab fresh propagate
show first-parameter.md propagate/layers layers.go
show through-the-call.md propagate/tree tree.go
show through-the-call.md propagate/detach detach.go
show checking.md propagate/loop loop.go
quiet propagate 'go mod init example.com/propagate'

block doc
on propagate 'go doc context | sed -n 33,43p'

block layers
on propagate 'go run ./layers'

block tree
on propagate 'go run ./tree'

block detach
on propagate 'go run ./detach'

block loop
on propagate 'go run ./loop'
