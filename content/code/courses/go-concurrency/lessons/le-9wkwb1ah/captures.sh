#!/usr/bin/env bash
# The terminal sessions quoted in lesson 26 of go-concurrency, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1, gcc and the student, ana
#   sudo bash captures.sh
#
# THE PROGRAMS ARE THE LESSONS' OWN. ~/wordcount is rebuilt first from the
# files lesson 25 shows (wordcount.go as its second version, file.go), then
# this lesson's files are taken out of the sections that show them, by
# `lab.sh fence`, in the order the lesson shows them. What is STAGED rather
# than typed: those files and the `go mod init example.com/wordcount` lesson 25
# names. Which runs of TestTop fail differs on every run, because Go randomises
# the order a map is walked in, and so do the timings; the lesson quotes one
# run of this script.
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
L25=$HERE/../le-ykc6t56x
from() { lab fence "$1" "$3" ${4:-} | lab put "$2/$3" || exit 1; }

lab fresh wordcount
quiet wordcount 'go mod init example.com/wordcount'
from "$L25/first-test.md" wordcount wordcount.go 2
from "$L25/helpers.md" wordcount file.go

show the-table.md wordcount wordcount_test.go
block table
on wordcount 'go test'
block verbose
on wordcount 'go test -v'
block filter-space
on wordcount "go test -v -run 'TestCount/only punctuation'"
block filter-anchored
on wordcount "go test -v -run '^TestCount\$/only_punctuation'"

show failure-messages.md wordcount top.go 1
show failure-messages.md wordcount top_test.go
block top-once
on wordcount 'go test -run TestTop'
block top-count
on wordcount "go test -run TestTop -count=20 | grep -- '--- FAIL' | sort | uniq -c"
block top-ties
on wordcount "go test -run 'TestTop/ties' -count=5"

show failure-messages.md wordcount top.go 2
block fixed
on wordcount 'go test -run TestTop -count=100'
on wordcount 'go test .'
on wordcount 'go test .'
