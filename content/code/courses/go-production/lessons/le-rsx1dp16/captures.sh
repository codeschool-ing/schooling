#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of go-production, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it. Every program it runs is placed from
# a lesson's own .md by `lab.sh place`, so nothing here is a second copy.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1, gcc and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the files of ~/escape, placed from this lesson's sections.
#   - in ~/escape-hits: lesson 1's tools/genlog/main.go and main.go, placed
#     from le-03nqvqms; lesson 13's internal/tally/tally.go and
#     internal/tally/split.go, placed from le-jg641g63; `go mod init
#     example.com/hits`; and the 100,000-line internal/tally/testdata/access.log
#     that lesson 12 generates with genlog. The lesson names each of them.
#   - the cleanup at the end: the hits binary is deleted.
# Timings in this lesson vary from run to run; the prose quotes the run pasted.
# The run pasted was made with `nice -n -10 bash captures.sh`, because the
# recording machine was shared with other jobs.
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

block ask
lab fresh escape
place asking-the-compiler point/point.go escape
on escape 'go mod init example.com/escape'
on escape 'go build -gcflags=-m ./point'
on escape 'go build -gcflags=-m=2 ./point 2>&1 | grep -v inlin'

block why
place what-escapes why/iface.go escape
place what-escapes why/closure.go escape
place what-escapes why/words.go escape
place what-escapes why/push.go escape
place what-escapes why/method.go escape
place size-and-inlining why/makes.go escape
place size-and-inlining why/inline.go escape
on escape 'go build -gcflags=-m ./why 2>&1 | grep iface.go'
on escape 'go build -gcflags=-m=2 ./why 2>&1 | grep -A9 "iface.go:7:14: n escapes to heap in"'
on escape 'go build -gcflags=-m ./why 2>&1 | grep closure.go'
on escape "go build -gcflags='-m -l' ./why 2>&1 | grep closure.go:22"
on escape 'go build -gcflags=-m ./why 2>&1 | grep words.go'
on escape 'go build -gcflags=-m ./why 2>&1 | grep push.go'
on escape 'go build -gcflags=-m ./why 2>&1 | grep method.go'

block size
on escape 'go build -gcflags=-m ./why 2>&1 | grep makes.go'
on escape 'go build -gcflags=-m=2 ./why 2>&1 | grep "too large"'
on escape 'go build -gcflags=-m ./why 2>&1 | grep inline.go'
on escape 'go build -gcflags=-m=2 ./point 2>&1 | grep "can inline New"'
on escape 'sed -i "s|^func New(|//go:noinline\nfunc New(|" point/point.go'
on escape 'grep -B1 "^func New" point/point.go'
on escape 'go build -gcflags=-m ./point ./why 2>&1 | grep "point.go:10\|inline.go"'
on escape 'sed -i "/^\/\/go:noinline$/d" point/point.go'

block cost
place what-it-costs why/allocs_test.go escape
place what-it-costs why/cost_test.go escape
on escape 'go test -run Allocs -v ./why'
on escape "go test -run '^\$' -bench . -benchmem ./why"
on escape 'sed -i "s|^func New(|//go:noinline\nfunc New(|" point/point.go'
on escape "go test -run Allocs -v ./why | grep Distance"
on escape "go test -run '^\$' -bench 'Distance|Call' -benchmem ./why"
on escape 'sed -i "/^\/\/go:noinline$/d" point/point.go'

block hits
lab fresh escape-hits
lab place le-03nqvqms arguments tools/genlog/main.go escape-hits
lab place le-03nqvqms subcommands main.go escape-hits
lab place le-jg641g63 a-faster-parse internal/tally/tally.go escape-hits
lab place le-jg641g63 a-faster-parse internal/tally/split.go escape-hits
quiet escape-hits 'go mod init example.com/hits'
quiet escape-hits 'mkdir -p internal/tally/testdata && go run ./tools/genlog -n 100000 > internal/tally/testdata/access.log'
on escape-hits 'go build -gcflags=-m . 2>&1 | grep -c tally/'
on escape-hits "go build -gcflags='example.com/hits/...=-m' . 2>&1 | grep -c tally/"
on escape-hits 'go build -gcflags=all=-m . 2>&1 | wc -l'
on escape-hits "go build -gcflags='example.com/hits/...=-m' . 2>&1 | grep tally/ | grep -v inlin"
on escape-hits "go build -gcflags='example.com/hits/...=-m=2' . 2>&1 | grep -A6 'tally.go:64:26: string.* in Count'"
on escape-hits "go build -gcflags='example.com/hits/...=-m=2' . 2>&1 | grep -A2 'line leaks to {heap}'"

block experiment
on escape-hits 'cp internal/tally/tally.go tally.go.bak'
on escape-hits 'sed -i "s/strings.Fields(line)/strings.Fields(strings.Clone(line))/" internal/tally/tally.go'
on escape-hits "go build -gcflags='example.com/hits/...=-m=2' . 2>&1 | grep -A8 'line leaks to {heap}' | grep from"
on escape-hits 'sed -i "s/ParseDuration(f\[4\])/ParseDuration(strings.Clone(f[4]))/" internal/tally/tally.go'
on escape-hits "go build -gcflags='example.com/hits/...=-m=2' . 2>&1 | grep 'leaking param: line'"
on escape-hits "go build -gcflags='example.com/hits/...=-m=2' . 2>&1 | grep -A12 'tally.go:64:26: string.* in Count' | grep from"
on escape-hits 'mv tally.go.bak internal/tally/tally.go'
on escape-hits "awk '{ print length }' internal/tally/testdata/access.log | sort -n | sed -n '1p;\$p'"

block measure
place in-hits internal/tally/allocs_test.go escape-hits
on escape-hits 'go test -run Allocs -v ./internal/tally'

block cleanup
quiet escape-hits 'rm -f hits'
