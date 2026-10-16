#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of go-concurrency, as a script that
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
# into ~/patterns/match, ~/patterns/nope, ~/patterns/evil, ~/patterns/cost and
# ~/patterns/evil.py, and a `go mod init` in ~/patterns. The Python is the
# python3 on the recording machine's PATH, whatever its version; the lesson
# prints it. Every timing differs from run to run, and the lesson quotes one run
# of this script.
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

lab fresh patterns
show matching.md patterns match/main.go
show re2.md patterns nope/main.go
show re2.md patterns evil/main.go
show re2.md patterns evil.py
show the-cost.md patterns cost/main.go
quiet patterns 'go mod init example.com/patterns'

block match
on patterns 'go run ./match'

block re2
on patterns 'go run ./nope'
on patterns 'go run ./evil'
on patterns 'python3 --version'
on patterns 'python3 evil.py'

block cost
on patterns 'go build -o bin/cost ./cost'
on patterns 'bin/cost'
on patterns 'bin/cost'
