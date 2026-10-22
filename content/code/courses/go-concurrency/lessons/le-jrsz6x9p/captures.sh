#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of go-concurrency, as a script that
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
# into ~/locks, a `go mod init` there, and the `go build -o` commands the
# sections name. The timings differ on every run, and in "cache" the order of
# the two locks on short sections has been seen both ways; the lesson quotes
# one run of this script. The go vet message is exact.
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

lab fresh locks
show mutex.md locks count.go
show mutex.md locks copied.go
show rwmutex.md locks cache.go
show channel-or-mutex.md locks three.go
quiet locks 'go mod init example.com/locks'

block count
on locks 'for i in 1 2 3; do go run count.go; done'
on locks 'go run -race count.go'
block copied
on locks 'go run copied.go'
on locks 'go vet copied.go'
block cache
quiet locks 'go build -o cache cache.go'
on locks './cache mutex 200'
on locks './cache rw 200'
on locks './cache mutex 0'
on locks './cache rw 0'
block three
quiet locks 'go build -o three three.go'
on locks './three'
on locks './three'
