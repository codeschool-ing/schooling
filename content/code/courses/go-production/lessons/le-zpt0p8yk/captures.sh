#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of go-production, as a script that
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
#   - lesson 1's tools/genlog/main.go, internal/tally/tally.go and main.go,
#     placed from le-03nqvqms into ~/prof, and `go mod init example.com/hits`
#     there. The lesson says it works on a copy of lesson 1's hits.
#   - this lesson's own files, placed from its sections.
#   - profserve runs in the background, started with setsid and stopped by its
#     pid. The lesson shows it as a second terminal: the command line printed
#     before its log is the command that was run, and the lines after it are
#     the first lines that run wrote to its standard error.
#   - the sleeps that give profserve time to leak, and the cleanup at the end:
#     the 91 MB log, the profiles, the binaries and the profile pprof saved in
#     ~/pprof are deleted.
# Timings in this lesson vary from run to run; the prose quotes the run pasted.
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
place1() { lab place le-03nqvqms "$1" "$2" "$3"; }
block() { printf '##### %s\n' "$1"; }

# Start profserve in the background, the way the lesson's second terminal does.
serve() {
  quiet prof '{ setsid ./profserve -timeout 500ms big.log > serve.log 2>&1 < /dev/null & } ; echo $! > serve.pid'
}
unserve() {
  quiet prof 'kill $(cat serve.pid); rm -f serve.pid'
  sleep 1
  # a second server on the same port would fail to bind and leave this one answering
  if lab exec prof 'curl -s -o /dev/null http://127.0.0.1:6060/'; then echo "profserve still running" >&2; exit 1; fi
}

block setup
lab fresh prof
place1 arguments tools/genlog/main.go prof
place1 subcommands internal/tally/tally.go prof
place1 subcommands main.go prof
quiet prof 'go mod init example.com/hits'

block bench
place from-a-benchmark internal/tally/bench_test.go prof
on prof 'mkdir -p internal/tally/testdata'
on prof 'go run ./tools/genlog -n 100000 > internal/tally/testdata/access.log'
on prof 'stat -c "%s bytes  %n" internal/tally/testdata/access.log'
on prof 'go test -bench Count -benchmem -cpuprofile cpu.out -memprofile mem.out ./internal/tally'
on prof 'ls'
on prof 'go tool pprof -top cpu.out | sed /^Time:/d | head -14'
on prof 'go tool pprof -raw cpu.out | sed /^Time:/d | head -5'
on prof 'go tool pprof -top mem.out | sed /^Time:/d | head -9'
on prof 'go tool pprof -raw mem.out | sed /^Time:/d | head -4'

block program
place from-a-program tools/profcount/main.go prof
on prof 'go run ./tools/genlog -n 2000000 > big.log'
on prof 'stat -c "%s bytes  %n" big.log'
on prof 'go build -o profcount ./tools/profcount'
on prof './profcount -cpuprofile count.cpu -memprofile count.mem big.log'
on prof 'stat -c "%s bytes  %n" count.cpu count.mem'
on prof 'go tool pprof -top count.cpu | sed /^Time:/d | head -10'
on prof 'go tool pprof -top count.mem | sed /^Time:/d | head -9'
on prof 'go tool pprof -top -sample_index=alloc_space count.mem | sed /^Time:/d | head -8'

block serve
place from-a-running-process tools/profserve/main.go prof
on prof 'go build -o profserve ./tools/profserve'
serve
sleep 3
on prof 'curl -s http://127.0.0.1:6060/debug/pprof/ | grep "<tr>" | sed "s/<[^>]*>/ /g"'
on prof 'go tool pprof -top "http://127.0.0.1:6060/debug/pprof/profile?seconds=5" | sed /^Time:/d | head -12'
sleep 8
on prof 'curl -s "http://127.0.0.1:6060/debug/pprof/goroutine?debug=1" | head -10'
on prof 'curl -s "http://127.0.0.1:6060/debug/pprof/goroutine?debug=2" | grep -A2 "chan send" | head -3'
on prof 'curl -s "http://127.0.0.1:6060/debug/pprof/goroutineleak?debug=1" | head -3'
unserve
block terminal2
printf 'ana@vm:~/prof$ ./profserve -timeout 500ms big.log\n'
lab exec prof 'head -6 serve.log'

block fixed
on prof "sed -i 's/done := make(chan result)/done := make(chan result, 1)/' tools/profserve/main.go"
on prof 'go build -o profserve ./tools/profserve'
serve
sleep 12
on prof 'curl -s "http://127.0.0.1:6060/debug/pprof/goroutineleak?debug=1" | head -3'
on prof 'curl -s "http://127.0.0.1:6060/debug/pprof/goroutine?debug=1" | head -1'
unserve

block cleanup
quiet prof 'rm -f big.log serve.log cpu.out mem.out count.cpu count.mem tally.test profcount profserve ~/pprof/pprof.profserve.*'
