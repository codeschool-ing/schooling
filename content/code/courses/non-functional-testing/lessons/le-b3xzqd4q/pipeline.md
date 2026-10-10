---
title: The gate, and the job that runs it
version: 1
---

The two halves become one command, `perf/gate.sh`, whose exit code is the verdict. A pipeline
needs nothing else from it: a step that exits non-zero fails the job, and a failed job blocks the
merge. Write it with `nano perf/gate.sh`:

```schooling-example
{"language": "sh", "file": "boxoffice/perf/gate.sh", "parts": [{"code": "# boxoffice/perf/gate.sh\n# The performance gate. Three Lighthouse runs of one page, judged by their\n# medians against the budget; three k6 runs of the API, judged by their\n# thresholds. Exits 1 if either half fails. Run it from ~/boxoffice with the\n# box office running:  bash perf/gate.sh /fast.html\nset -u\npage=${1:?which page, for example /fast.html}\nexport CHROME_PATH=${CHROME_PATH:-$HOME/.cache/ms-playwright/chromium-1194/chrome-linux/chrome}\nmkdir -p perf/runs\nrm -f perf/runs/*.json\nfailed=0\n", "note": "One argument, the page. `CHROME_PATH` keeps the value lesson 10 put in `~/.profile` and falls back to the same path, because a pipeline's shell does not read `~/.profile`. Old reports are removed first, so a run that fails to write one cannot be judged on the last run's."}, {"code": "echo \"== front end: $page, 3 Lighthouse runs\"\nfor i in 1 2 3; do\n  lighthouse \"http://127.0.0.1:8000$page\" --quiet --only-categories=performance \\\n    --output=json --output-path=\"perf/runs/lh-$i.json\" \\\n    --chrome-flags=\"--headless=new --no-sandbox\"\ndone\npython3 perf/budget.py perf/runs/lh-*.json || failed=1\n", "note": "The front end: three Lighthouse runs and `budget.py` on all three, which judges their medians. Its exit code sets `failed`."}, {"code": "echo \"== back end: GET /shows/{id}, 3 k6 runs\"\ncrossed=0\nfor i in 1 2 3; do\n  k6 run --quiet --summary-export=\"perf/runs/k6-$i.json\" perf/api.js >/dev/null 2>&1\n  code=$?\n  p95=$(jq '.metrics.http_req_duration[\"p(95)\"] * 10 | round / 10' \"perf/runs/k6-$i.json\")\n  echo \"run $i: p95 $p95 ms, k6 exit $code\"\n  [ \"$code\" -ne 0 ] && crossed=$((crossed + 1))\ndone\nif [ \"$crossed\" -ge 2 ]; then\n  echo \"thresholds crossed in $crossed of 3 runs\"\n  failed=1\nfi\n", "note": "The back end: three k6 runs, each judged by its own thresholds. The gate fails when two or more of them crossed a threshold, which is the same as asking whether the median run crossed it."}, {"code": "[ \"$failed\" -eq 0 ] && echo \"GATE: pass\" || echo \"GATE: fail\"\nexit \"$failed\"", "note": "One line for the person reading the log, and the exit code for the pipeline, which reads nothing else."}]}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l11-gate\" aria-label=\"How gate.sh decides. On the front end, three Lighthouse runs of the page feed budget.py, which takes the median of each number and compares it with the budget, failing on any line over. On the back end, three k6 runs of GET /shows/{id}, each judged by its own thresholds, the 200 ms requirement and the baseline with its tolerance; the back end fails when two or more runs cross. The gate exits 0 only when both halves pass, and 1 otherwise, and the pipeline reads nothing but that exit code.\"><defs><marker id=\"l11-gate-nf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"30.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">front end</text><rect x=\"114.0\" y=\"48.0\" width=\"112.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><rect x=\"122.0\" y=\"54.0\" width=\"112.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><rect x=\"130.0\" y=\"60.0\" width=\"112.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"186.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lighthouse ×3</text><path d=\"M244.0 75.0 L268.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-gate-nf-ah-paper-dim)\"></path><rect x=\"272.0\" y=\"52.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"357.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">median of each number</text><path d=\"M442.0 70.0 L478.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-gate-nf-ah-paper-dim)\"></path><rect x=\"482.0\" y=\"52.0\" width=\"110.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"537.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">over budget?</text><path d=\"M592.0 70.0 L622.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-gate-nf-ah-paper-dim)\"></path><text x=\"30.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">back end</text><rect x=\"114.0\" y=\"148.0\" width=\"112.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><rect x=\"122.0\" y=\"154.0\" width=\"112.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><rect x=\"130.0\" y=\"160.0\" width=\"112.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"186.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">k6 ×3</text><path d=\"M244.0 175.0 L268.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-gate-nf-ah-paper-dim)\"></path><rect x=\"272.0\" y=\"152.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"357.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">each run vs its thresholds</text><path d=\"M442.0 170.0 L478.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-gate-nf-ah-paper-dim)\"></path><rect x=\"482.0\" y=\"152.0\" width=\"110.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"537.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2 of 3 crossed?</text><path d=\"M592.0 170.0 L622.0 135.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-gate-nf-ah-paper-dim)\"></path><rect x=\"626.0\" y=\"96.0\" width=\"74.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"663.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">exit 0</text><text x=\"663.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">exit 1</text><text x=\"360.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the pipeline reads the exit code and nothing else</text></svg>", "caption": "The gate: medians against a budget on one side, a majority of runs against thresholds on the other, and one exit code for both."}
```

## Running the gate

Before running it, put the index back, so the back end is the version the baseline describes:

```
ana@nft:~/boxoffice$ sqlite3 data/boxoffice.db "CREATE INDEX bookings_show ON bookings(show_id)"
```

**The slow page from lesson 10:**

```
ana@nft:~/boxoffice$ bash perf/gate.sh /; echo "exit $?"
== front end: /, 3 Lighthouse runs
largest-contentful-paint         13,052      2,500  OVER
cumulative-layout-shift           0.139        0.1  OVER
total-blocking-time               1,414        200  OVER
script bytes                        405     50,000  ok
image bytes                   2,431,680    200,000  OVER
total bytes                   2,435,280    400,000  OVER
total requests                        4         15  ok
3 runs, 5 over budget
== back end: GET /shows/{id}, 3 k6 runs
run 1: p95 2.1 ms, k6 exit 0
run 2: p95 12.5 ms, k6 exit 99
run 3: p95 11.4 ms, k6 exit 99
thresholds crossed in 2 of 3 runs
GATE: fail
exit 1
```

The front end fails on the same five lines as before, now judged on the median of three runs, and
the gate exits 1. **The back end failed too, and it should not have.** The index was in place, the
code was the version the baseline describes, and two of the three runs still crossed the 9.8 ms
limit, at 12.5 and 11.4 ms, while the first ran at 2.1. That is the false failure of the previous
section, caught on a machine shared with other work. Here the page failed anyway; on its own it
would have been a red job for nothing. The baseline came from three runs on a quieter minute, and
a gate that did this twice a week would need a baseline recorded from more runs, on the machine
the gate uses, or a wider slack.

**The fixed page:**

```
ana@nft:~/boxoffice$ bash perf/gate.sh /fast.html; echo "exit $?"
== front end: /fast.html, 3 Lighthouse runs
largest-contentful-paint            912      2,500  ok
cumulative-layout-shift               0        0.1  ok
total-blocking-time                   0        200  ok
script bytes                          0     50,000  ok
image bytes                      20,563    200,000  ok
total bytes                      23,466    400,000  ok
total requests                        3         15  ok
3 runs, 0 over budget
== back end: GET /shows/{id}, 3 k6 runs
run 1: p95 3.1 ms, k6 exit 0
run 2: p95 1.9 ms, k6 exit 0
run 3: p95 1.7 ms, k6 exit 0
GATE: pass
exit 0
```

Every line within budget, three k6 runs within their thresholds, exit 0.

**The fixed page again, with the index dropped:**

```
ana@nft:~/boxoffice$ sqlite3 data/boxoffice.db "DROP INDEX bookings_show"
ana@nft:~/boxoffice$ bash perf/gate.sh /fast.html; echo "exit $?"
== front end: /fast.html, 3 Lighthouse runs
largest-contentful-paint            911      2,500  ok
cumulative-layout-shift               0        0.1  ok
total-blocking-time                   0        200  ok
script bytes                          0     50,000  ok
image bytes                      20,563    200,000  ok
total bytes                      23,467    400,000  ok
total requests                        3         15  ok
3 runs, 0 over budget
== back end: GET /shows/{id}, 3 k6 runs
run 1: p95 23.1 ms, k6 exit 99
run 2: p95 16.8 ms, k6 exit 99
run 3: p95 21.9 ms, k6 exit 99
thresholds crossed in 3 of 3 runs
GATE: fail
exit 1
```

The page is fine and the gate still fails, because the back end regressed. That is the reason to
gate both halves in one place: a release is slow for its users whichever half got slower.

## The job

This is a GitHub Actions workflow that runs the gate on every pull request. **It was not run for
this course**: the box office is not a repository on GitHub, and the VM has no runner. It is shown
whole because it is the last step, and its commands are the ones these lessons print: the
installs of lessons 5 and 10, the box office of lesson 1, the index and the gate. The index is
made with Python's `sqlite3` module rather than the `sqlite3` program, which a runner image need
not have.

```yaml
# boxoffice/.github/workflows/performance.yml
# The performance gate on every pull request. The job fails when gate.sh exits
# non-zero, and a failed job blocks the merge where the branch is protected.
name: performance

on:
  pull_request:

jobs:
  gate:
    runs-on: ubuntu-24.04
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v5

      - uses: actions/setup-node@v5
        with:
          node-version: "24"

      - name: Install Lighthouse, Chromium and k6
        run: |
          sudo npm install -g lighthouse@13.5.0
          mkdir -p ~/browser && cd ~/browser && npm init -y
          npm install playwright@1.56.0 && npx playwright install --with-deps chromium
          curl -fsSLO https://github.com/grafana/k6/releases/download/v1.8.1/k6-v1.8.1-linux-amd64.tar.gz
          tar -xzf k6-v1.8.1-linux-amd64.tar.gz
          sudo install k6-v1.8.1-linux-amd64/k6 /usr/local/bin/

      - name: Start the box office
        run: |
          python3 seed.py
          python3 -c "import sqlite3; sqlite3.connect('data/boxoffice.db').execute('CREATE INDEX bookings_show ON bookings(show_id)')"
          python3 make_hero.py
          nohup python3 app.py > server.log 2>&1 &
          for i in $(seq 50); do curl -fs localhost:8000/health && break; sleep 0.2; done

      - name: Gate
        run: bash perf/gate.sh /fast.html

      - name: Keep the reports
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: performance-runs
          path: perf/runs/
```

Three things in it are decisions rather than syntax:

- **It installs exact versions**, the same ones as the VM, so the gate on the runner measures
  with the tool the baseline was measured with.
- **It runs only the fixed page.** The slow page exists to show a failure; a real repository would
  gate the pages it ships.
- **It keeps the reports even when the gate fails** (`if: always()`), because a red job with no
  evidence sends somebody to reproduce it by hand.

One caution about the baseline in a pipeline. The `baseline.json` in the repository was measured
on your VM, and a GitHub runner is a different machine with different neighbours. Record the
baseline on the runner the gate uses, by running the same three k6 runs there once, and commit
that file instead.

How the triggers, the jobs and the runners work is `testing-cicd` lessons 5 and 6: continuous
integration in general, and GitHub Actions and GitLab CI in practice. This lesson adds one more
check to that pipeline, and its exit code is all the pipeline has to understand.
