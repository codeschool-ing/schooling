#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of go-concurrency, as a script that
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
# into ~/flags/greet, ~/flags/tags and ~/flags/tool, and a `go mod init` in
# ~/flags. The addresses are from the documentation range 192.0.2.0/24. The
# `time` figures differ on every run; the lesson quotes one run of this script.
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

lab fresh flags
show defining.md flags greet/main.go
show custom.md flags tags/main.go
show subcommands.md flags tool/main.go
quiet flags 'go mod init example.com/flags'

block build
on flags 'go build -o bin/ ./...'
on flags 'ls bin'

block greet
on flags 'bin/greet'
on flags 'bin/greet -name=bia -times 2'
on flags 'bin/greet -shout -name caio extra words'
on flags 'time bin/greet -times 3 -pause 1s'

block help
on flags 'bin/greet -h; echo $?'
on flags 'bin/greet -times=two; echo $?'

block traps
on flags 'bin/greet bia -times 2'
on flags 'bin/greet -shout false'

block custom
on flags 'bin/tags -tag go -tag concurrency -port 9000 -addr 192.0.2.10'
on flags 'bin/tags'
on flags 'bin/tags -port 70000; echo $?'
on flags 'bin/tags -addr 192.0.2.300 2>&1 | head -1'

block tool
on flags 'bin/tool add -tag work buy milk'
on flags 'bin/tool list -limit 3'
on flags 'bin/tool list -tag x; echo $?'
on flags 'bin/tool remove; echo $?'
on flags 'bin/tool; echo $?'
