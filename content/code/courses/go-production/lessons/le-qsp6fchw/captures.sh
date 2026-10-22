#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of go-production, as a script that
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
#   - the files of ~/trace-hits that lesson 1 printed (tools/genlog/main.go and
#     internal/tally/tally.go), placed from lesson 1, and `go mod init
#     example.com/hits`, which lesson 1 shows.
#   - cmd/pcount/main.go, cmd/pcount/main_test.go and cmd/flight/main.go,
#     placed from this lesson's sections.
#   - block figdata, which prints the numbers the two figures are drawn from
#     and is not quoted in the lesson. It serves each trace with `go tool
#     trace` on a local port and reads the "Goroutine analysis" table of the
#     workers, which is what figure 2 draws; and it walks the debug dump of
#     w4.trace for figure 1's window. Rerunning this script changes every
#     timing, so the figures and the prose are redrawn from the new run.
#   - the last block, which deletes the 137 MB log and the traces.
# TIMINGS ARE REAL AND VARY. The lab machine was shared with other work while
# this ran, and a second run gives different milliseconds; the prose quotes
# this run and says which ratios held across runs.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, TZ=America/Sao_Paulo,
# on 4 CPUs.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
LAB_SH=${LAB_SH:-$HERE/../../lab.sh}
LESSON=$(basename "$HERE")
D=trace-hits
lab() { bash "$LAB_SH" "$@"; }
on() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "$*" 2>&1 || true; }
quiet() { lab exec "$1" "$2" >/dev/null 2>&1 || true; }
place() { lab place "$LESSON" "$1" "$2" "$3"; }
block() { printf '##### %s\n' "$1"; }

block setup
lab fresh $D
lab place le-03nqvqms arguments tools/genlog/main.go $D
lab place le-03nqvqms subcommands internal/tally/tally.go $D
quiet $D 'go mod init example.com/hits'
place recording cmd/pcount/main.go $D
on $D 'find . -name "*.go" | sort'
on $D 'go run ./tools/genlog -n 3000000 > big.log && stat -c "%s bytes  %n" big.log'
on $D 'go build -o pcount ./cmd/pcount && ./pcount -h'

block record
on $D './pcount -workers 4 -trace w4.trace big.log'
on $D './pcount -workers 1 -trace w1.trace big.log'
on $D 'stat -c "%s bytes  %n" w1.trace w4.trace'
on $D 'for i in 1 2 3; do printf "plain   "; ./pcount big.log; printf "traced  "; ./pcount -trace x.trace big.log; done'
quiet $D 'rm -f x.trace'

block test
place recording cmd/pcount/main_test.go $D
on $D 'go test -count=1 -trace=test.trace ./cmd/pcount'
on $D 'stat -c "%s bytes  %n" test.trace'

block holds
on $D 'go tool trace -d=parsed w4.trace | wc -l'
on $D "go tool trace -d=parsed w4.trace | awk '/^M=/ {print \$4}' | sort | uniq -c | sort -rn"
on $D "go tool trace -d=parsed w4.trace | grep -o 'Running->Waiting Reason=\"[^\"]*\"' | sort | uniq -c | sort -rn"
on $D "go tool trace -d=parsed w4.trace | grep -E 'Task(Begin|End)|Log '"
on $D "go tool trace -d=parsed w4.trace | grep -o 'RegionBegin .*' | grep -o 'Type=.*' | sort | uniq -c"
on $D "go tool trace -d=parsed w4.trace | grep -c 'RangeBegin.*GC concurrent mark phase'"

block latency
on $D 'for w in 1 2 4 8; do ./pcount -workers $w big.log; done'
on $D 'time ./pcount -workers 1 big.log'
on $D 'time ./pcount -workers 4 -shared big.log'
on $D './pcount -workers 4 -shared -trace shared.trace big.log'
on $D 'go tool trace -pprof=sync shared.trace > sync.pprof'
on $D 'go tool pprof -top -focus=main.count sync.pprof'
on $D 'go tool trace -pprof=sync w4.trace > sync4.pprof && go tool pprof -top -focus=main.count sync4.pprof'
on $D 'GOMAXPROCS=1 ./pcount -workers 4 -trace p1.trace big.log'
on $D 'go tool trace -pprof=sched p1.trace > sched.pprof && go tool pprof -top -focus=main -nodecount=6 sched.pprof'

block flight
place flight-recorder cmd/flight/main.go $D
on $D 'go build -o flight ./cmd/flight && ./flight big.log'
on $D "go tool trace -d=parsed slow.trace | grep 'Category=\"slow\"'"
on $D 'go tool trace -pprof=sync slow.trace > slow.pprof && go tool pprof -top -focus=Mutex slow.pprof'
on $D './flight -slow 200ms -o none.trace big.log; ls none.trace'

block figdata
# Not quoted. Figure 2: the workers' row of "Goroutine analysis", per trace.
for t in w1 w4 shared p1; do
  echo "== $t"
  quiet $D "setsid sh -c 'echo \$\$ > ui.pid; exec go tool trace -http=127.0.0.1:18914 $t.trace' </dev/null >/dev/null 2>&1 &"
  for _ in $(seq 10); do lab exec $D 'test -s ui.pid' && break; sleep 1; done
  for _ in $(seq 60); do curl -s -o /dev/null http://127.0.0.1:18914/ && break; sleep 1; done
  curl -s 'http://127.0.0.1:18914/goroutine?name=sync.%28%2aWaitGroup%29.Go.func1' | python3 -c '
import html, re, sys
t = sys.stdin.read()
for tr in re.findall(r"<tr.*?</tr>", t, re.S):
    cells = [html.unescape(re.sub(r"<[^>]*>", "", c)).strip() for c in re.findall(r"<t[hd][^>]*>(.*?)</t[hd]>", tr, re.S)]
    if cells and (cells[0] == "Goroutine" or cells[0].isdigit()):
        print(" | ".join(cells))
'
  quiet $D 'kill -- -$(cat ui.pid); rm -f ui.pid'
  for _ in $(seq 30); do curl -s -o /dev/null http://127.0.0.1:18914/ || break; sleep 1; done
done
# Figure 1: 4 ms of w4.trace around the first GC mark phase that begins a
# third of the way into the count task or later.
lab exec $D 'go tool trace -d=parsed w4.trace' 2>/dev/null | python3 -c '
import re, sys, collections
st = re.compile(r"^M=\S+ P=\S+ G=\S+ StateTransition Time=(\d+) GoID=(\d+) (\w+)->(\w+) Reason=\"([^\"]*)\"")
rb = re.compile(r"^M=\S+ P=\S+ G=(\d+) RegionBegin Time=\d+ .*Type=\"parse\"")
rg = re.compile(r"^M=\S+ P=\S+ G=\S+ (RangeBegin|RangeEnd) Time=(\d+) Name=\"GC concurrent mark phase\"")
tk = re.compile(r"^M=\S+ P=\S+ G=\S+ (TaskBegin|TaskEnd) Time=(\d+)")
cur, iv, workers, gc, task = {}, collections.defaultdict(list), set(), [], []
for line in sys.stdin:
    m = st.match(line)
    if m:
        t, g, a, b, why = int(m[1]), int(m[2]), m[3], m[4], m[5]
        if g in cur: iv[g].append((cur[g][1], t, cur[g][0], cur[g][2]))
        cur[g] = (b, t, why); continue
    m = rb.match(line)
    if m: workers.add(int(m[1])); continue
    m = rg.match(line)
    if m: gc.append((m[1], int(m[2]))); continue
    m = tk.match(line)
    if m: task.append(int(m[2]))
third = task[0] + (task[1] - task[0]) // 3
a = min(t for k, t in gc if k == "RangeBegin" and t > third) - 1_000_000; z = a + 4_000_000
print("window", a, z, "task", task[0] - a, task[1] - a)
for g in [1] + sorted(workers):
    for s, e, k, why in iv[g]:
        if e > a and s < z: print(g, max(s, a) - a, min(e, z) - a, k, why)
for k, t in gc:
    if a - 10_000_000 < t < z + 10_000_000: print("gc", k, t - a)
'

block cleanup
quiet $D 'rm -f big.log *.trace *.pprof'
