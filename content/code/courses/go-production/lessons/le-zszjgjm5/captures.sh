#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of go-production, as a script that
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
#   - the files of ~/mem-stacks, ~/mem-knobs, ~/mem-stats and ~/mem-pool,
#     placed from this lesson's sections, and `go mod init` in each.
#   - ~/mem-hits: lesson 1's main.go, internal/tally/tally.go and
#     tools/genlog/main.go, placed from lesson 1, `go mod init example.com/hits`,
#     and this lesson's internal/keep and cmd/slowest placed from its sections.
#   - the 100,000-line internal/keep/testdata/access.log, written by genlog as
#     the prose says.
#   - big.log, mem.out and the binaries are deleted at the end, to save disk.
# TIMINGS ARE REAL AND VARY BETWEEN RUNS: the prose quotes the run it pastes and
# says which parts are stable. Addresses printed by ~/mem-stacks change on every
# run, because the runtime places its memory at a random address.
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

block stacks
lab fresh mem-stacks
place stack-and-heap main.go mem-stacks
quiet mem-stacks 'go mod init example.com/stacks'
on mem-stacks 'ulimit -s'
on mem-stacks 'sed -n 77,78p /usr/local/go/src/runtime/stack.go'
on mem-stacks 'go build -o stacks . && ./stacks'
on mem-stacks './stacks -max 1000000 2>&1 | head -6; echo ${PIPESTATUS[0]}'
on mem-stacks 'sed -n 160,167p /usr/local/go/src/runtime/proc.go'
on mem-stacks 'time ./stacks -depth 100000000 2>&1 | sed -n 4,6p'
on mem-stacks 'grep -n "adaptivestackstart = " /usr/local/go/src/runtime/runtime1.go'

block trace
lab fresh mem-hits
lab place le-03nqvqms arguments tools/genlog/main.go mem-hits
lab place le-03nqvqms subcommands internal/tally/tally.go mem-hits
lab place le-03nqvqms subcommands main.go mem-hits
quiet mem-hits 'go mod init example.com/hits'
on mem-hits 'go build -o hits . && go build -o genlog ./tools/genlog'
on mem-hits './genlog -n 2000000 > big.log; stat -c "%s bytes  %n" big.log'
on mem-hits 'GODEBUG=gctrace=1 ./hits count big.log 2>&1 >/dev/null | head -4'
on mem-hits 'GODEBUG=gctrace=1 ./hits count big.log 2>&1 >/dev/null | grep -c "^gc "'
on mem-hits 'sed -n 31,35p /usr/local/go/src/runtime/mbarrier.go'
on mem-hits 'grep -n "gcBackgroundUtilization = " /usr/local/go/src/runtime/mgcpacer.go'
on mem-hits 'sed -n 1609,1615p /usr/local/go/src/runtime/mgc.go'

block floor
on mem-hits 'sed -n 58,60p /usr/local/go/src/runtime/mgcpacer.go; sed -n 1343p /usr/local/go/src/runtime/mgcpacer.go'
on mem-hits 'for g in 50 200; do GOGC=$g GODEBUG=gctrace=1 ./hits count big.log 2>&1 >/dev/null | sed -n 5p; done'

block slowest
place gogc-and-gomemlimit internal/keep/keep.go mem-hits
place gogc-and-gomemlimit cmd/slowest/main.go mem-hits
on mem-hits 'go build -o slowest ./cmd/slowest && ./slowest big.log'
on mem-hits 'GODEBUG=gctrace=1 ./slowest big.log 2>&1 | grep -E "^gc 1[45] "'
on mem-hits 'sed -n 1295p /usr/local/go/src/runtime/mgcpacer.go'
on mem-hits 'for g in 50 100 200 400 off; do echo "GOGC=$g: $(GOGC=$g ./slowest big.log | tail -1)"; done'
on mem-hits 'time ./slowest big.log > /dev/null'
on mem-hits 'time GOGC=off ./slowest big.log > /dev/null'

block limit
on mem-hits 'GOGC=off GOMEMLIMIT=400MiB ./slowest big.log'
on mem-hits 'GOMEMLIMIT=100MiB ./slowest big.log'
on mem-hits 'GOMEMLIMIT=100MiB GODEBUG=gctrace=1 ./slowest big.log 2>&1 | grep -E "^gc 3[89] "'
on mem-hits 'sed -n 9,14p /usr/local/go/src/runtime/mgclimit.go'
on mem-hits 'grep -n "^func" /usr/local/go/src/runtime/cgroup_linux.go'

block knobs
lab fresh mem-knobs
place gogc-and-gomemlimit main.go mem-knobs
quiet mem-knobs 'go mod init example.com/knobs'
on mem-knobs 'go run .'
on mem-knobs 'GOGC=off GOMEMLIMIT=512MiB go run .'

block stats
lab fresh mem-stats
place measuring-allocations stats_test.go mem-stats
quiet mem-stats 'go mod init example.com/memstats'
on mem-stats 'sed -n 356,365p /usr/local/go/src/runtime/mstats.go'
on mem-stats 'go test -bench . -benchmem'

block load
place measuring-allocations internal/keep/keep_test.go mem-hits
quiet mem-hits 'mkdir -p internal/keep/testdata'
on mem-hits './genlog -n 100000 > internal/keep/testdata/access.log'
on mem-hits 'go test -run "^$" -bench Load ./internal/keep'
on mem-hits 'go test -count=1 -run Allocate -v ./internal/keep'
on mem-hits 'go test -run "^$" -bench "Load/hint=0" -memprofile mem.out ./internal/keep > /dev/null && go tool pprof -top -sample_index=alloc_space mem.out | sed /^Time:/d | head -9'
on mem-hits 'sed -n 337,341p /usr/local/go/src/runtime/slice.go'

block write
place fewer-allocations internal/keep/write.go mem-hits
place fewer-allocations internal/keep/write_test.go mem-hits
on mem-hits 'go test -count=1 ./internal/keep'
on mem-hits 'go test -run "^$" -bench Write -benchmem ./internal/keep'
on mem-hits './slowest big.log && ./slowest -hint $(wc -l < big.log) big.log'

block pool
lab fresh mem-pool
place fewer-allocations main.go mem-pool
quiet mem-pool 'go mod init example.com/pool'
on mem-pool 'GOMAXPROCS=1 go run .'
on mem-pool 'go run .'
on mem-pool 'sed -n 163,167p /usr/local/go/src/fmt/print.go'

block cleanup
quiet mem-hits 'rm -f big.log mem.out keep.test hits genlog slowest'
quiet mem-stacks 'rm -f stacks'
