#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine, with Lighthouse 13.5.0,
# Playwright's Chromium and k6 v1.8.1 already installed (lessons 10 and 5); the
# box office of lesson 1, lesson 10's pages, pictures and metrics.jq, and this
# lesson's files, copied out of the sections that show them; a fresh database;
# the pictures, made by lesson 10's make_hero.py; CHROME_PATH in ~/.profile,
# as lesson 10 puts it there; the server, in the background, where the lesson
# has the student run it in the first terminal. The GitHub Actions workflow is
# shown and never run. Timings differ on every run, and more on a shared
# computer: the recording computer had 4 processors shared with other work.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)
L1="$HERE_DIR/../le-ymhwee3h"
L10="$HERE_DIR/../le-x8s7k1kq"

machine l11
shown "$L1/the-boxoffice.md" "$L10/two-pages.md" "$L10/lighthouse.md" \
  "$HERE_DIR/budgets.md" "$HERE_DIR/backend.md" "$HERE_DIR/pipeline.md" 2>/dev/null
at '~/boxoffice'
quiet 'python3 seed.py && python3 make_hero.py'
quiet "echo 'export CHROME_PATH=\$HOME/.cache/ms-playwright/chromium-1194/chrome-linux/chrome' >> ~/.profile"
serve 'python3 app.py'

block no-budget
run 'lighthouse --help | grep -ci budget'
run 'lighthouse --list-all-audits | grep -ci budget'

LH='--quiet --only-categories=performance --output=json --chrome-flags="--headless=new --no-sandbox"'
block budget-slow
run "lighthouse http://127.0.0.1:8000/ $LH --output-path=slow.json"
run 'python3 perf/budget.py slow.json; echo "exit $?"'

block budget-fast
run "lighthouse http://127.0.0.1:8000/fast.html $LH --output-path=fast.json"
run 'python3 perf/budget.py fast.json; echo "exit $?"'

block index
run 'curl -si localhost:8000/shows/990 | grep Server-Timing'
run 'sqlite3 data/boxoffice.db "CREATE INDEX bookings_show ON bookings(show_id)"'
run 'curl -si localhost:8000/shows/990 | grep Server-Timing'

block k6-first
run 'k6 run --quiet perf/api.js; echo "exit $?"'

block baseline
run 'mkdir -p perf/runs'
run 'for i in 1 2 3; do k6 run --quiet --summary-export=perf/runs/base-$i.json perf/api.js > /dev/null 2>&1; done'
run "jq -s '{p95_ms: (map(.metrics.http_req_duration[\"p(95)\"]) | sort | .[1])}' perf/runs/base-*.json > perf/baseline.json"
run 'cat perf/baseline.json'

block baseline-spread
run "jq '.metrics.http_req_duration[\"p(95)\"]' perf/runs/base-*.json"

block k6-second
run 'k6 run --quiet perf/api.js; echo "exit $?"'

block regress
run 'sqlite3 data/boxoffice.db "DROP INDEX bookings_show"'
run 'k6 run --quiet perf/api.js; echo "exit $?"'

block reindex
run 'sqlite3 data/boxoffice.db "CREATE INDEX bookings_show ON bookings(show_id)"'

block gate-slow
run 'bash perf/gate.sh /; echo "exit $?"'

block gate-fast
run 'bash perf/gate.sh /fast.html; echo "exit $?"'

block gate-regress
run 'sqlite3 data/boxoffice.db "DROP INDEX bookings_show"'
run 'bash perf/gate.sh /fast.html; echo "exit $?"'

stop
