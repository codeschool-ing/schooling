#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of go-production, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it. Every program it runs is placed from
# the lesson's own .md (or from lesson 1's) by `lab.sh place`, so nothing here
# is a second copy.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1, gcc and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the files of ~/vet-hits, placed from lesson 1 (le-03nqvqms), and
#     `go mod init example.com/hits` there.
#   - the files of ~/vetted and ~/oldloop, placed from this lesson's sections.
#   - `go mod init example.com/vetted` in ~/vetted and
#     `go mod init example.com/oldloop` in ~/oldloop, which the lesson names.
#   - `go clean -testcache` before each `go test`, so a run is a run and not a
#     line from the cache.
# Nothing here is a timing, apart from the `ok ... 0.00Ns` of `go test`.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
LAB_SH=${LAB_SH:-$HERE/../../lab.sh}
LESSON=$(basename "$HERE")
lab() { bash "$LAB_SH" "$@"; }
on() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "$*" 2>&1 || true; }
quiet() { lab exec "$1" "$2" >/dev/null 2>&1 || true; }
place() { lab place "$LESSON" "$1" "$2" "$3"; }
block() { printf '##### %s\n' "$1"; }

block hits-clean
lab fresh vet-hits
lab place le-03nqvqms arguments tools/genlog/main.go vet-hits
lab place le-03nqvqms subcommands internal/tally/tally.go vet-hits
lab place le-03nqvqms subcommands main.go vet-hits
lab place le-03nqvqms output-and-exit-codes main_test.go vet-hits
quiet vet-hits 'go mod init example.com/hits'
on vet-hits 'go vet ./...; echo $?'

block report
lab fresh vetted
quiet vetted 'go mod init example.com/vetted'
place what-vet-is report/main.go vetted
on vetted 'go run ./report'
on vetted 'go vet ./report; echo $?'

block oldloop
lab fresh oldloop
place what-vet-is main.go oldloop
quiet oldloop 'go mod init example.com/oldloop'
on oldloop 'go mod edit -go=1.21 && go vet .'
on oldloop 'go run . | sort'
on oldloop 'go mod edit -go=1.27.1 && go vet . && go run . | sort'

block notfound
place the-checks notfound/main.go vetted
on vetted 'go run ./notfound'
on vetted 'go vet ./notfound'

block counter
place the-checks counter/main.go vetted
on vetted 'go run ./counter 2>&1 | head -1'
on vetted 'go vet ./counter'

block fetch
place the-checks fetch/main.go vetted
on vetted 'go run ./fetch'
on vetted 'go vet ./fetch'

block rows
place the-checks rows/main.go vetted
on vetted 'go run ./rows'
on vetted 'go vet ./rows'

block dedup
place the-checks dedup/main.go vetted
on vetted 'go run ./dedup'
on vetted 'go vet ./dedup'

block header
place the-checks header/main.go vetted
on vetted 'go run ./header'
on vetted 'go vet ./header'

block limit
place the-checks limit/main.go vetted
on vetted 'go run ./limit'
on vetted 'go vet ./limit'

block subset
on vetted 'go help test | grep -A2 "That subset"'
on vetted 'grep -A40 "defaultVetFlags = " "$(go env GOROOT)/src/cmd/go/internal/test/test.go" | grep -E "^\s+\"-" | tr -d "\t\"," | tr "\n" " "; echo'

block status-fail
place vet-in-go-test status/status.go vetted
place vet-in-go-test status/status_test.go vetted
quiet vetted 'go clean -testcache'
on vetted 'go test ./status'

block status-off
quiet vetted 'go clean -testcache'
on vetted 'go test -vet=off -v ./status'

block status-fixed
quiet vetted 'go clean -testcache'
on vetted 'sed -i "s/Testparse/TestParse/" status/status_test.go'
on vetted 'sed -i "s/errors.As(err, e)/errors.As(err, \&e)/" status/status.go'
on vetted 'go test ./status'
on vetted 'sed -i "s/n > 999/n > 599/" status/status.go && go test ./status'

block counter-test
place vet-in-go-test counter/main_test.go vetted
quiet vetted 'go clean -testcache'
on vetted 'go test ./counter'
on vetted 'go test -vet=all ./counter'

block select
on vetted 'go vet -printf=false ./report ./notfound; echo $?'
on vetted 'go vet -copylocks -lostcancel ./... 2>&1 | sort'

block applog
place tuning-and-limits applog/main.go vetted
on vetted 'go run ./applog'
on vetted 'go vet ./applog'
on vetted 'go vet -printf.funcs=logf ./applog'

block load
place tuning-and-limits load/main.go vetted
on vetted 'echo hits > name.txt'
on vetted 'go vet ./load; echo $?'
on vetted 'go run ./load 2>&1 | head -1'

block shadow
on vetted 'go install golang.org/x/tools/go/analysis/passes/shadow/cmd/shadow@v0.52.0'
on vetted 'go vet -vettool=$(command -v shadow) ./load'
