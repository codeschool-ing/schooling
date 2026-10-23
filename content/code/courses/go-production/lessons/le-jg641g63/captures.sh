#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of go-production, as a script that
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
#   - ~/prof as lesson 12 left it: lesson 1's tools/genlog/main.go,
#     internal/tally/tally.go, main.go and main_test.go, placed from
#     le-03nqvqms; lesson 12's internal/tally/bench_test.go, placed from
#     le-zpt0p8yk; `go mod init example.com/hits`; and the 100,000-line
#     internal/tally/testdata/access.log that lesson 12 generates with genlog.
#   - lesson 5's internal/tally/tally_test.go, placed from le-4c90x6nc just
#     before the new Parse. The lesson names it as the tests lesson 5 wrote.
#   - this lesson's own files, placed from its sections.
#   - the stacks of the CPU profile, written with `go tool pprof -traces` to
#     /tmp/le-jg641g63.traces for the author: the flame graph in the-flame-graph
#     and the picture of its labelling question are drawn from them.
#   - the cleanup at the end: profiles, binaries, the call graph and the two
#     benchmark files are deleted.
# Timings in this lesson vary from run to run; the prose quotes the run pasted.
# The recording machine was shared with other jobs, which showed in the profiles
# as preemption and lock samples; the run pasted was made with `nice -n -10 bash
# captures.sh` so that the benchmark got the processors it asked for.
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

block setup
lab fresh prof
lab place le-03nqvqms arguments tools/genlog/main.go prof
lab place le-03nqvqms subcommands internal/tally/tally.go prof
lab place le-03nqvqms subcommands main.go prof
lab place le-03nqvqms output-and-exit-codes main_test.go prof
lab place le-zpt0p8yk from-a-benchmark internal/tally/bench_test.go prof
quiet prof 'go mod init example.com/hits'
quiet prof 'mkdir -p internal/tally/testdata && go run ./tools/genlog -n 100000 > internal/tally/testdata/access.log'

block profile
on prof "go test -run '^\$' -bench Count -benchtime 200x -cpuprofile cpu.out -memprofile mem.out ./internal/tally"
on prof 'go tool pprof -top cpu.out | sed /^Time:/d | head -16'
on prof 'go tool pprof -top -cum cpu.out | sed /^Time:/d | head -16'
on prof 'go tool pprof -top -sample_index=alloc_objects mem.out | sed /^Time:/d | head -8'
on prof 'go tool pprof -top -sample_index=alloc_space mem.out | sed /^Time:/d | head -8'
lab exec prof 'go tool pprof -traces cpu.out' > /tmp/le-jg641g63.traces 2>&1

block line
on prof 'go tool pprof -list "tally.Parse" cpu.out | head -21'
on prof 'go tool pprof -peek "strings.Fields" cpu.out | sed /^Time:/d'
on prof 'go tool pprof -top -hide=runtime cpu.out | sed /^Time:/d | head -14'
on prof 'go tool pprof -top -ignore=runtime cpu.out | sed /^Time:/d | head -12'
on prof 'go tool pprof -top -nodefraction=0.05 cpu.out | sed /^Time:/d'
on prof 'go tool pprof -svg -output graph.svg cpu.out'
on prof 'stat -c "%s bytes  %n" graph.svg'

block fix
on prof "go test -run '^\$' -bench Count -benchmem -count 10 ./internal/tally > old.txt"
lab place le-4c90x6nc test internal/tally/tally_test.go prof
place a-faster-parse internal/tally/split.go prof
place a-faster-parse internal/tally/tally.go prof
place a-faster-parse internal/tally/split_test.go prof
on prof 'go vet ./... && go test ./...'
on prof 'cp internal/tally/split.go split.go.bak'
on prof 'sed -i "/c < .!. || c > .~./,+1d" internal/tally/split.go'
on prof 'go test ./internal/tally'
on prof 'mv split.go.bak internal/tally/split.go'
on prof 'go test -fuzz FuzzSplit5 -fuzztime 10s ./internal/tally'

block measure
on prof "go test -run '^\$' -bench Count -benchmem -count 10 ./internal/tally > new.txt"
on prof 'go install golang.org/x/perf/cmd/benchstat@v0.0.0-20261009192801-be2c69fb417e'
on prof 'benchstat old.txt new.txt'
on prof "go test -run '^\$' -bench Count -benchtime 200x -cpuprofile cpu.new -memprofile mem.new ./internal/tally"
on prof 'go tool pprof -top -diff_base cpu.out cpu.new | sed /^Time:/d | head -14'
on prof 'go tool pprof -top cpu.new | sed /^Time:/d | head -16'
on prof 'go tool pprof -top -sample_index=alloc_space mem.new | sed /^Time:/d | head -8'

block cleanup
quiet prof 'rm -f cpu.out mem.out cpu.new mem.new tally.test graph.svg old.txt new.txt'
