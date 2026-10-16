---
title: What a worker costs
version: 1
---

**Every worker is a Node process and a browser, and a browser is several processes of its own.**
Adding a worker adds all of them, and they compete for the same processors and the same memory.
The belief that more workers is always faster holds only while the machine has something left to
give, and the way to find where it stops is to measure your own suite on your own machine.

## Measuring a run

`/usr/bin/time` would report a command's memory, but it measures one process, and a test run is a
tree of them: the runner, the shop, each worker and each worker's browser. The script below runs a
command, adds up the memory of the whole tree five times a second, and keeps the highest total.
Bash's `time` reports the processor time of the command and everything below it. Save it as
`measure.sh`:

```sh
#!/usr/bin/env bash
# Runs a command and reports what its whole process tree cost: the most
# memory it held at one moment, and the processor time it used.
report=$(mktemp)
TIMEFORMAT='%R %U %S'
{ time "$@" > /dev/null 2>&1; } 2> "$report" &
root=$!
peak=0
while kill -0 "$root" 2>/dev/null; do
  # Add up the resident memory of the command and everything below it.
  kb=$(ps -A -o pid=,ppid=,rss= | awk -v root="$root" '
    { parent[$1] = $2; rss[$1] = $3 }
    END {
      for (p in parent) {
        q = p
        while (q != root && q > 1) q = parent[q]
        if (q == root) total += rss[p]
      }
      print total + 0
    }')
  if [ "$kb" -gt "$peak" ]; then peak=$kb; fi
  sleep 0.2
done
wait "$root"
status=$?
read -r real user system < "$report"
rm -f "$report"
echo "exit $status  wall ${real}s  processor ${user}s user + ${system}s system  peak memory $((peak / 1024)) MB"
```

Two things to know before trusting its numbers. The memory is each process's resident memory
added together, and browser processes share some pages, so the total **overstates** what the
machine lost; it is good for comparing runs on one machine, not for buying memory. And a sample every 200 milliseconds can miss a peak that lasts less than
that.

## The curve

The suite under `turns.config.js`, so that every run is green and only the worker count changes,
from one worker to eight on this four-processor laptop:

```
%%CAP cost%%
```

%%CAP fig-cost%%

@@COSTREAD@@

## Why past the processors it gets worse

@@PROCESSOR@@ A test here is mostly waiting: for the shop to answer, for a page to draw, for an
assertion to see what it expects. **While a worker waits, another worker can use the
processor**, which is why going from one worker to two cut the time almost in half without the
processor time moving much.

Past the number of processors that stops. Four browsers drawing at the same moment already fill
four processors, and a fifth has to wait for a turn, while still holding its memory. The
operating system spends time switching between them, which shows up as processor time going up
for the same work. And every worker also costs a start-up, a browser launched and closed, that
buys nothing when the worker then waits in line. The eight-worker run shows all three:

```
%%CAP w8%%
```

@@W8READ@@ This is why Playwright's default is half the processors and not all of them. Its documentation
goes further for CI and recommends one worker there, for stable and repeatable runs, on machines
that often have fewer processors than a laptop and share them with other jobs.

**Measure, then choose.** The right number is the lowest count after which the wall time stops
falling, on the machine the suite actually runs on, written into the configuration or the CI
command so that every run uses it.
