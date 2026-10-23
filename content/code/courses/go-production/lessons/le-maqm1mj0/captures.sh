#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of go-production, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it. Every program it runs is placed from
# the lesson's own .md by `lab.sh place`, so nothing here is a second copy.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1, gcc and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - ~/reflect: the programs typeof/main.go, tags/main.go and set/main.go,
#     placed from this lesson's sections, and `go mod init example.com/reflect`.
#   - ~/reflect-hits: lesson 1's internal/tally/tally.go and
#     tools/genlog/main.go, placed from lesson 1, `go mod init example.com/hits`,
#     and this lesson's internal/columns/columns.go, internal/columns/table.go,
#     internal/columns/columns_test.go and cmd/cols/main.go placed from its
#     sections.
#   - the 20,000-line access.log, written by genlog with lesson 1's command.
# TIMINGS ARE REAL AND VARY BETWEEN RUNS: the benchmark figures in the prose are
# the run pasted, and the prose says which parts are stable (the ratios and the
# allocation counts). The hexadecimal arguments in a panic's stack trace come
# from the binary and may differ on another build.
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

block typeof
lab fresh reflect
place type-and-value typeof/main.go reflect
quiet reflect 'go mod init example.com/reflect'
on reflect 'go run ./typeof'
on reflect 'go doc reflect.TypeOf'
on reflect 'sed -n 1367,1369p /usr/local/go/src/reflect/type.go'
on reflect 'sed -n 158,169p /usr/local/go/src/reflect/value.go'

block tags
place struct-tags tags/main.go reflect
on reflect 'go run ./tags'
on reflect 'go vet ./tags'
on reflect 'sed -n 1133,1141p /usr/local/go/src/encoding/json/encode.go'

block cols
lab fresh reflect-hits
lab place le-03nqvqms arguments tools/genlog/main.go reflect-hits
lab place le-03nqvqms subcommands internal/tally/tally.go reflect-hits
quiet reflect-hits 'go mod init example.com/hits'
place struct-tags internal/columns/columns.go reflect-hits
place struct-tags cmd/cols/main.go reflect-hits
quiet reflect-hits 'go run ./tools/genlog -n 20000 > access.log'
on reflect-hits 'go build -o cols ./cmd/cols && ./cols access.log'
on reflect-hits './cols -fields hits,path -n 5 access.log'
on reflect-hits './cols -fields path,hist access.log; echo $?'
on reflect-hits './cols -fields Hits access.log; echo $?'

block set
place setting-values set/main.go reflect
on reflect 'go vet ./set && go run ./set'
on reflect 'for m in copy kind unexported args typo; do go run ./set $m 2>&1 | grep ^panic; done'
on reflect 'go run ./set kind 2>&1 | sed -n 7,20p'

block cost
place the-cost internal/columns/table.go reflect-hits
place the-cost internal/columns/columns_test.go reflect-hits
on reflect-hits 'go vet ./... && go test -count=1 ./internal/columns'
on reflect-hits 'go test -run "^$" -bench . -benchmem -count=3 ./internal/columns'

block typos
on reflect-hits 'sed -i "s/tally.Top(s, \*n)/tally.Top(s, *n)[0]/" cmd/cols/main.go'
on reflect-hits 'go vet ./... && go build -o cols ./cmd/cols && ./cols access.log; echo $?'
on reflect-hits 'sed -i "s/r.Hits)/r.Hist)/" internal/columns/table.go'
on reflect-hits 'go build ./...'
on reflect-hits 'sed -i "s/r.Hist)/r.Hits)/" internal/columns/table.go'
on reflect-hits 'sed -i "s/tally.Top(s, \*n)\[0\]/tally.Top(s, *n)/" cmd/cols/main.go'
on reflect-hits 'go build -o cols ./cmd/cols && ./cols -n 1 access.log'

block users
on reflect-hits 'go list -f "{{.ImportPath}} {{range .Imports}}{{if eq . \"reflect\"}}imports reflect{{end}}{{end}}" encoding/json fmt flag text/template strconv slices'

quiet reflect-hits 'rm -f cols'
