#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of go-concurrency, as a script that
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
# into ~/pool, a `go mod init` there, and the four `go build -o` commands
# the sections name. The jobs open /etc/hostname, which
# every Ubuntu machine has, and sleep or compute instead of doing real work.
# The open-file limit is lowered with `ulimit -n` in a subshell, as the
# section shows. The timings differ on every run, and so does the number of
# failed jobs in "unbounded"; the lesson quotes one run of this script.
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

lab fresh pool
show the-shape.md pool unbounded.go
show the-shape.md pool pool.go
show sizing.md pool size.go
show semaphore.md pool semaphore.go
quiet pool 'go mod init example.com/pool'
quiet pool 'go build -o unbounded unbounded.go && go build -o pool pool.go && go build -o size size.go && go build -o semaphore semaphore.go'

block unbounded
on pool 'ulimit -n'
on pool './unbounded'
on pool '(ulimit -n 256; ./unbounded)'
block pool
on pool '(ulimit -n 256; ./pool)'
block size-cpu
on pool 'for w in 1 2 4 8 16; do ./size cpu $w; done'
block size-wait
on pool 'for w in 1 4 16 64; do ./size wait $w; done'
block semaphore
on pool '(ulimit -n 256; ./semaphore)'
