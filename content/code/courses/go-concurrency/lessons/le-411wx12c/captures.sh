#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of go-concurrency, as a script that
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
# into ~/logs/first, ~/logs/handlers, ~/logs/attrs and ~/logs/levels, and a
# `go mod init` in ~/logs. The first program prints the date and time of the
# run, which the lesson quotes from one run; every other program removes the
# time from its records so that their output is the same on every run.
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

lab fresh logs
show handlers.md logs first/main.go
show handlers.md logs handlers/main.go
show attributes.md logs attrs/main.go
show levels-and-context.md logs levels/main.go
quiet logs 'go mod init example.com/logs'

block first
on logs 'go run ./first'

block handlers
on logs 'go run ./handlers'
on logs 'go run ./handlers | grep ERROR'
on logs 'go run ./handlers | tail -1 | python3 -m json.tool'

block attrs
on logs 'go run ./attrs'
on logs 'go vet ./attrs; echo $?'

block levels
on logs 'go run ./levels'
