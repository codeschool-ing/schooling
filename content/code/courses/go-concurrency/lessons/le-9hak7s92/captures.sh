#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of go-concurrency, as a script that
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
# into ~/channels, and a `go mod init` there. forgot.go is made in the
# transcript itself, by the sed the lesson shows. The timings in "hand" differ
# slightly from run to run; the lesson quotes one run of this script.
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

lab fresh channels
show send-and-receive.md channels hand.go
show closing.md channels closed.go
show closing.md channels sendclosed.go
show closing.md channels closetwice.go
show closing.md channels oops.go
show ranging.md channels words.go
quiet channels 'go mod init example.com/channels'

block hand
on channels 'go run hand.go'

block closed
on channels 'go run closed.go'

block panics
on channels 'go run sendclosed.go'
on channels 'go run closetwice.go'

block oops
on channels 'go build oops.go'

block words
on channels 'go run words.go'

block forgot
on channels "sed '/close(out)/d' words.go > forgot.go"
on channels 'go run forgot.go'
