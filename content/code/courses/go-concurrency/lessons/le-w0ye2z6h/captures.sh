#!/usr/bin/env bash
# The terminal sessions quoted in lesson 27 of go-concurrency, as a script that
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
# files lessons 25 and 26 show, in their last versions, then this lesson's
# files are taken out of the sections that show them, by `lab.sh fence`, in the
# order the lesson shows them. What is STAGED rather than typed: those files
# and the `go mod init example.com/wordcount` lesson 25 names. The timings
# differ on every run; the lesson quotes one run of this script.
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
L26=$HERE/../le-9wkwb1ah
from() { lab fence "$1" "$3" ${4:-} | lab put "$2/$3" || exit 1; }

lab fresh wordcount
quiet wordcount 'go mod init example.com/wordcount'
from "$L25/first-test.md" wordcount wordcount.go 2
from "$L25/helpers.md" wordcount file.go
from "$L26/the-table.md" wordcount wordcount_test.go
from "$L26/failure-messages.md" wordcount top.go 2
from "$L26/failure-messages.md" wordcount top_test.go

show the-seam.md wordcount source.go
show fakes-and-stubs.md wordcount source_test.go
block spy-fails
on wordcount 'go test -v -run TopOf'
show fakes-and-stubs.md wordcount source.go
block spy-passes
on wordcount 'go test -run TopOf'

show what-not-to-mock.md wordcount fssource.go
show what-not-to-mock.md wordcount fssource_test.go
block fs
on wordcount 'go test -v -run FSSource'
block all
on wordcount 'go test'
