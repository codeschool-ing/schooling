#!/usr/bin/env bash
# The terminal sessions quoted in lesson 30 of go-concurrency, as a script that
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
# files lessons 25 to 29 show, in their last versions, then this lesson's
# files are taken out of the sections that show them, by `lab.sh fence`, in the
# order the lesson shows them. What is STAGED rather than typed: those files
# and the `go mod init example.com/wordcount` lesson 25 names, and in
# "negative" the one row the lesson adds to top_test.go, inserted after the
# `none` row exactly as the section prints it. The timings and the names of
# the counter files differ on every run; the lesson quotes one run of this
# script.
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
L29=$HERE/../le-etn16rqp
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
from "$L29/writing.md" wordcount bench_test.go

block cover
on wordcount 'go test -cover'
block profile
on wordcount 'go test -coverprofile=c.out'
on wordcount 'go tool cover -func=c.out'
show measuring.md wordcount readfail_test.go
block profile-after
on wordcount 'go test -coverprofile=c.out'
on wordcount 'go tool cover -func=c.out'

show what-it-misses.md wordcount negative_test.go
block negative
on wordcount 'go test -run TestTopNegative'
show what-it-misses.md wordcount top.go
row=$(grep -o '`{"negative", -1, \[\]Entry{}}`' "$HERE/what-it-misses.md" | tr -d '`')
[ -n "$row" ] || exit 1
lab exec wordcount "python3 -c 'import sys; p=\"top_test.go\"; t=open(p).read(); a=\"{\\\"none\\\", 0, []Entry{}},\\n\"; assert a in t; open(p,\"w\").write(t.replace(a, a+\"\\t\\t\"+sys.argv[1]+\",\\n\"))' '$row'" || exit 1
block fixed
on wordcount 'rm negative_test.go'
on wordcount 'go test -run TestTop -v'
block still
on wordcount "go test -coverprofile=c.out >/dev/null && go tool cover -func=c.out | grep Top"

show integration-coverage.md wordcount cmd/topwords/main.go
block program
on wordcount 'go build -cover -o topwords ./cmd/topwords'
on wordcount "printf 'to be or not to be\nthat is the question\n' > hamlet.txt"
on wordcount 'mkdir -p covdata'
on wordcount 'GOCOVERDIR=covdata ./topwords -n 2 hamlet.txt; echo "exit $?"'
on wordcount 'GOCOVERDIR=covdata ./topwords missing.txt; echo "exit $?"'
on wordcount 'ls covdata'
block covdata
on wordcount 'go tool covdata percent -i=covdata'
on wordcount 'go tool covdata textfmt -i=covdata -o prog.out'
on wordcount "go tool cover -func=prog.out | grep -E 'main|TopOf|Handler|total'"
