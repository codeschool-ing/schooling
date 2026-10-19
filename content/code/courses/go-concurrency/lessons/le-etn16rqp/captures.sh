#!/usr/bin/env bash
# The terminal sessions quoted in lesson 29 of go-concurrency, as a script that
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
# files lessons 25 to 28 show, in their last versions, then this lesson's
# files are taken out of the sections that show them, by `lab.sh fence`, in the
# order the lesson shows them. What is STAGED rather than typed: those files
# and the `go mod init example.com/wordcount` lesson 25 names. The timings and
# the round counts differ on every run, and the lab machine was not idle while
# they ran; the lesson quotes one run of this script, and the addresses in the
# disassembly are whatever that build produced.
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
L27=$HERE/../le-w0ye2z6h
L28=$HERE/../le-bbfct1z1
from() { lab fence "$1" "$3" ${4:-} | lab put "$2/$3" || exit 1; }

lab fresh wordcount
quiet wordcount 'go mod init example.com/wordcount'
from "$L25/first-test.md" wordcount wordcount.go 2
from "$L25/helpers.md" wordcount file.go
from "$L26/the-table.md" wordcount wordcount_test.go
from "$L26/failure-messages.md" wordcount top.go 2
from "$L26/failure-messages.md" wordcount top_test.go
from "$L27/fakes-and-stubs.md" wordcount source.go
from "$L27/fakes-and-stubs.md" wordcount source_test.go
from "$L27/what-not-to-mock.md" wordcount fssource.go
from "$L27/what-not-to-mock.md" wordcount fssource_test.go
from "$L28/recorder.md" wordcount handler.go 2
from "$L28/recorder.md" wordcount handler_test.go
from "$L28/server.md" wordcount httpsource.go
from "$L28/server.md" wordcount httpsource_test.go
from "$L28/client-timeouts.md" wordcount timeout_test.go

show writing.md wordcount bench_test.go
block bench
on wordcount "go test -run '^\$' -bench . -benchmem"
block count5
on wordcount "go test -run '^\$' -bench Count -benchmem -count 5"

show reading.md wordcount wordcount.go
block candidate
on wordcount 'go test . -count=1'
on wordcount "go test -run '^\$' -bench Count -benchmem -count 5"
from "$L25/first-test.md" wordcount wordcount.go 2
quiet wordcount 'go test . -count=1'

show not-fooling.md wordcount sum_test.go
block sum
on wordcount "go test -run '^\$' -bench Sum -count 3"
block objdump
on wordcount "go test -c -o wc.test && go tool objdump -s 'BenchmarkSumN\$' wc.test"
on wordcount 'rm sum_test.go wc.test'
