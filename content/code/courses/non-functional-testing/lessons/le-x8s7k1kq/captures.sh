#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine, with Lighthouse 13.5.0 and
# Playwright's Chromium (chromium-1194) already installed by the lab the way
# "Lighthouse on both pages" installs them, except that the browser was copied
# from the recording computer's Playwright cache rather than downloaded; the
# box office of lesson 1 and this lesson's files, copied out of the sections
# that show them; a fresh database; the server, in the background, where the
# lesson has the student run it in the first terminal. Lighthouse's numbers
# differ on every run, and more on a shared computer: the recording computer
# had 4 processors shared with other work.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)
L1="$HERE_DIR/../le-ymhwee3h"

machine l10
shown "$L1/the-boxoffice.md" "$HERE_DIR/two-pages.md" "$HERE_DIR/lighthouse.md" 2>/dev/null
at '~/boxoffice'
quiet 'python3 seed.py'

block hero
run 'python3 make_hero.py'
run 'ls -l static'

serve 'python3 app.py'

block versions
run 'lighthouse --version'
run '~/.cache/ms-playwright/chromium-1194/chrome-linux/chrome --version'

block no-chrome
run 'lighthouse http://127.0.0.1:8000/ --quiet 2>&1 | head -1'

block chrome-path
run "echo 'export CHROME_PATH=\$HOME/.cache/ms-playwright/chromium-1194/chrome-linux/chrome' >> ~/.profile"
run 'source ~/.profile && echo $CHROME_PATH'

LH='--quiet --only-categories=performance --output=json --chrome-flags="--headless=new --no-sandbox"'
block slow
run "lighthouse http://127.0.0.1:8000/ $LH --output-path=slow.json"
run 'jq -f metrics.jq slow.json'

block fast
run "lighthouse http://127.0.0.1:8000/fast.html $LH --output-path=fast.json"
run 'jq -f metrics.jq fast.json'

block why
run "jq -c '.audits[\"long-tasks\"].details.items[] | [.url, .duration]' slow.json"
run "jq -r '.audits[\"layout-shifts\"].details.items[].subItems.items[].cause' slow.json"
run "jq -r '.audits[\"lcp-breakdown-insight\"].details.items[1].snippet' slow.json"
run "jq -c '.audits[\"resource-summary\"].details.items[] | select(.requestCount > 0) | [.resourceType, .requestCount, .transferSize]' slow.json"

block weights
run "jq -c '.categories.performance.auditRefs[] | select(.weight > 0) | [.id, .weight]' slow.json"

block throttling
run "jq -c '.configSettings | [.formFactor, .throttlingMethod, .throttling]' slow.json"

block spread
run "for i in 1 2 3 4 5; do lighthouse http://127.0.0.1:8000/ $LH --output-path=run.json; jq -r '[.categories.performance.score, .audits[\"largest-contentful-paint\"].displayValue, .audits[\"total-blocking-time\"].displayValue, .audits[\"cumulative-layout-shift\"].displayValue] | @tsv' run.json; done"

block provided
run "lighthouse http://127.0.0.1:8000/ $LH --throttling-method=provided --output-path=raw.json"
run 'jq -f metrics.jq raw.json'

stop
