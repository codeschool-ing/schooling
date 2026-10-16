---
title: What a worker costs
version: 1
---

**Every worker is a Node process and a browser, and a browser is several processes of its own.**
Adding a worker adds all of them, and they compete for the same processors and the same memory.
The belief that more workers is always faster holds only while the machine has something left to
give, and the way to find where it stops is to measure your own suite on your own machine.

## Measuring a run

GNU `/usr/bin/time -v` reports a maximum resident size, but it is the largest single process, and a
test run is a tree of them: the runner, the shop, each worker and each worker's browser. The script below runs a
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
machine lost; it is good for comparing runs on one machine, not for buying memory. And a sample
every 200 milliseconds can miss a peak that lasts less than that.

## The curve

The full suite is the wrong thing to measure for this, because the one-at-a-time phase of the last
section sets a floor that no worker count moves. The `parallel` project alone, every test its own
group with `--fully-parallel`, and each test run four times with `--repeat-each 4` so that there is
enough work to share, from one worker to eight on this four-processor laptop:

```
ana@laptop:~/quitanda$ bash measure.sh npx playwright test --config turns.config.js --project parallel --fully-parallel --repeat-each 4 --workers 1
exit 0  wall 55.241s  processor 19.023s user + 5.056s system  peak memory 924 MB
ana@laptop:~/quitanda$ bash measure.sh npx playwright test --config turns.config.js --project parallel --fully-parallel --repeat-each 4 --workers 2
exit 0  wall 33.222s  processor 23.981s user + 5.579s system  peak memory 1480 MB
ana@laptop:~/quitanda$ bash measure.sh npx playwright test --config turns.config.js --project parallel --fully-parallel --repeat-each 4 --workers 3
exit 0  wall 26.121s  processor 27.515s user + 6.036s system  peak memory 2035 MB
ana@laptop:~/quitanda$ bash measure.sh npx playwright test --config turns.config.js --project parallel --fully-parallel --repeat-each 4 --workers 4
exit 0  wall 23.682s  processor 29.239s user + 6.826s system  peak memory 2573 MB
ana@laptop:~/quitanda$ bash measure.sh npx playwright test --config turns.config.js --project parallel --fully-parallel --repeat-each 4 --workers 6
exit 0  wall 23.327s  processor 35.685s user + 7.789s system  peak memory 3573 MB
ana@laptop:~/quitanda$ bash measure.sh npx playwright test --config turns.config.js --project parallel --fully-parallel --repeat-each 4 --workers 8
exit 0  wall 24.603s  processor 43.104s user + 9.083s system  peak memory 4476 MB
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two bar charts over the worker counts 1, 2, 3, 4, 6, 8. Wall time in seconds: 55.2, 33.2, 26.1, 23.7, 23.3, 24.6. Peak memory in MB: 924, 1480, 2035, 2573, 3573, 4476. A line marks four workers, the machine's four processors.\"><text x=\"30.0\" y=\"28.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">wall time, seconds</text><line x1=\"30\" y1=\"240\" x2=\"330\" y2=\"240\" stroke=\"var(--wire)\"></line><rect x=\"40.0\" y=\"67.3\" width=\"30.0\" height=\"172.7\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"55.0\" y=\"61.3\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">55.2</text><text x=\"55.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><rect x=\"90.0\" y=\"136.1\" width=\"30.0\" height=\"103.9\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"105.0\" y=\"130.1\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">33.2</text><text x=\"105.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><rect x=\"140.0\" y=\"158.3\" width=\"30.0\" height=\"81.7\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"155.0\" y=\"152.3\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">26.1</text><text x=\"155.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><rect x=\"190.0\" y=\"166.0\" width=\"30.0\" height=\"74.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"205.0\" y=\"160.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">23.7</text><text x=\"205.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><line x1=\"235.0\" y1=\"44\" x2=\"235.0\" y2=\"240\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"3 3\"></line><text x=\"239.0\" y=\"52.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 processors</text><rect x=\"240.0\" y=\"167.1\" width=\"30.0\" height=\"72.9\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"255.0\" y=\"161.1\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">23.3</text><text x=\"255.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6</text><rect x=\"290.0\" y=\"163.1\" width=\"30.0\" height=\"76.9\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"305.0\" y=\"157.1\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">24.6</text><text x=\"305.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8</text><text x=\"180.0\" y=\"276.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">workers</text><text x=\"390.0\" y=\"28.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">peak memory, MB</text><line x1=\"390\" y1=\"240\" x2=\"690\" y2=\"240\" stroke=\"var(--wire)\"></line><rect x=\"400.0\" y=\"204.3\" width=\"30.0\" height=\"35.7\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"415.0\" y=\"198.3\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">924</text><text x=\"415.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><rect x=\"450.0\" y=\"182.9\" width=\"30.0\" height=\"57.1\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"465.0\" y=\"176.9\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1480</text><text x=\"465.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><rect x=\"500.0\" y=\"161.5\" width=\"30.0\" height=\"78.5\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"515.0\" y=\"155.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2035</text><text x=\"515.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><rect x=\"550.0\" y=\"140.7\" width=\"30.0\" height=\"99.3\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"565.0\" y=\"134.7\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2573</text><text x=\"565.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><line x1=\"595.0\" y1=\"44\" x2=\"595.0\" y2=\"240\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"3 3\"></line><text x=\"599.0\" y=\"52.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 processors</text><rect x=\"600.0\" y=\"102.1\" width=\"30.0\" height=\"137.9\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"615.0\" y=\"96.1\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3573</text><text x=\"615.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6</text><rect x=\"650.0\" y=\"67.3\" width=\"30.0\" height=\"172.7\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"665.0\" y=\"61.3\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4476</text><text x=\"665.0\" y=\"256.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8</text><text x=\"540.0\" y=\"276.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">workers</text></svg>", "caption": "The same 120 tests at six worker counts on a four-processor laptop, one run each. Memory grows with every worker; the time stops falling."}
```

The wall time falls fast at first, from 55.2 seconds with one worker to 33.2 with two and 26.1
with three, then by less each time: 23.7 with four, 23.3 with six, and 24.6 with eight, slower than
four. Memory does not level off at all. Every worker added about half a gigabyte, from 924 MB with
one to 4476 MB with eight, nearly five times as much, for almost no gain after the fourth. **The fastest
count was not the one that cost the least**, and the curve says where to stop: about four, the
number of processors.

## Why past the processors it gets worse

A test here is mostly waiting: for the shop to answer, for a page to draw, for an assertion to see
what it expects. **While one worker waits, another can use the processor**, which is why the
second worker took so much off the wall time.

Past the number of processors that stops. Four browsers drawing at the same moment already fill
four processors, and a fifth worker has to wait for a turn while still holding its memory. Every
worker also costs a start-up, a Node process and a browser launched and closed, that buys
nothing when the worker then waits in line, and the operating system spends time switching
between them. That shows in the processor time, which counts the work done and not the wait: the same 120 tests
took 36.1 seconds of processor with four workers and 52.2 with eight, for a run that finished 0.9
seconds later.

Playwright's default, half the processors, sits below that point on any machine. Its documentation
goes further for CI and recommends one worker there, for stability and reproducibility, on machines
that often have fewer processors than a laptop and share them with other jobs.

**Measure, then choose.** The right number is the lowest count after which the wall time stops
falling, on the machine the suite actually runs on, written into the configuration or the CI
command so that every run uses it. Every run here was headless, Playwright's default; lesson 17
timed what a window adds.
