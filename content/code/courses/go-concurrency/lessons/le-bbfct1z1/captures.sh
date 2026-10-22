#!/usr/bin/env bash
# The terminal sessions quoted in lesson 28 of go-concurrency, as a script that
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
# files lessons 25 to 27 show, in their last versions, then this lesson's
# files are taken out of the sections that show them, by `lab.sh fence`, in the
# order the lesson shows them. What is STAGED rather than typed: those files
# and the `go mod init example.com/wordcount` lesson 25 names. The timings,
# the port the test server listens on and the order of the stuck server's
# log lines differ on every run; the lesson quotes one run of this script.
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

show recorder.md wordcount handler.go 1
show recorder.md wordcount handler_test.go
block recorder-fails
on wordcount 'go test -v -run TestHandler'
show recorder.md wordcount handler.go 2
block recorder-passes
on wordcount 'go test -run TestHandler'

show server.md wordcount httpsource.go
show server.md wordcount httpsource_test.go
block server
on wordcount 'go test -v -run HTTPSource'

show client-timeouts.md wordcount timeout_test.go
block timeout
on wordcount 'go test -v -run Timeout'
show client-timeouts.md wordcount stuck_test.go
block stuck
on wordcount 'go test -v -run Stuck'
on wordcount 'rm stuck_test.go'
