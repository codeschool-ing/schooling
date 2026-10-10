#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of web-automation, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash captures.sh       # root, because it acts as the user ana
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. `the-config` shows
# evidence.config.js and evidence/ssr.spec.js, `reading-a-trace` shows
# evidence/search.spec.js, `attaching` shows evidence/errors.spec.js and
# `visual-comparison` shows evidence/visual.spec.js, all whole; `stage 16`
# leaves them in the project. Every test under evidence/ fails on purpose
# except the visual one, which fails once, on the run that writes its
# baseline. What is STAGED rather than typed, beyond what ../../lab.sh's
# header lists for every lesson:
#   - in "visual-changed", one colour in app/public/style.css changed with sed
#     (a card border from #c9d6c3 to #2f6f4e, the change the section describes), and the original put back after;
#   - Playwright's colour codes are stripped from the test runs, which is what
#     a terminal shows once it has drawn them.
# The trace viewer and `npx playwright show-report` were not run: both open a
# window and this machine has no screen. Nothing here watched a video.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4,
# Playwright 1.56.0 and Chromium 141.0.7390.37, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh" lib
lock
machine
stage 16 || exit 1
P=$REPO_DEFAULT
cd "$P" || exit 1
nocolor() { sed 's/\x1b\[[0-9;]*m//g'; }
SSR=test-results/ssr-a-click-on-ssr-at-once

# --- the-config
block quarantined
run 'npx playwright test tests/search.spec.js --trace retain-on-failure' | nocolor
run 'find test-results'
block ssr-evidence
run 'npx playwright test --config evidence.config.js evidence/ssr.spec.js' | nocolor

# --- evidence
block evidence-ls
run "ls -la $SSR/"
block evidence-file
run "file $SSR/test-failed-1.png $SSR/video.webm"
block error-context
run "cat $SSR/error-context.md"
block report-du
run 'du -sh test-results playwright-report'

# --- reading-a-trace
block trace-list
run "unzip -l $SSR/trace.zip"
block trace-actions
run "unzip -p $SSR/trace.zip 0-trace.trace | grep '\"type\":\"before\"' | grep -o '\"method\":\"[a-zA-Z]*\"\\|\"startTime\":[0-9.]*' | paste - -"
block trace-network
run "unzip -p $SSR/trace.zip 0-trace.network | grep -o '\"url\":\"[^\"]*\"\\|\"time\":[0-9.]*\\|\"_monotonicTime\":[0-9.]*' | paste - - -"
block search-run
run 'npx playwright test --config evidence.config.js evidence/search.spec.js' | nocolor | head -8
block search-network
run "unzip -p test-results/search-*/trace.zip 0-trace.network | grep -o '\"url\":\"[^\"]*search?[^\"]*\"\\|\"time\":[0-9.]*\\|\"_monotonicTime\":[0-9.]*' | paste - - - | grep search"
block search-actions
run "unzip -p test-results/search-*/trace.zip 0-trace.trace | grep '\"type\":\"before\"' | grep -o '\"method\":\"[a-zA-Z]*\"\\|\"startTime\":[0-9.]*' | paste - -"

# --- attaching
block errors-run
run 'npx playwright test --config evidence.config.js evidence/errors.spec.js' | nocolor
block errors-trace
run "unzip -p test-results/errors-*/trace.zip 0-trace.trace | grep -o '\"type\":\"console\".\\{0,120\\}\\|\"method\":\"pageError\".\\{0,120\\}'"

# --- in-ci
block retry
run 'npx playwright test --config evidence.config.js evidence/ssr.spec.js --retries 1 --trace on-first-retry' | nocolor | head -6
run 'find test-results -type f | sort'
block trace-off
run 'npx playwright test tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js' | nocolor | tail -2
run 'du -sh test-results'
block trace-on
run 'npx playwright test tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js --trace on' | nocolor | tail -2
run 'du -sh test-results; find test-results -name trace.zip | wc -l'

# --- visual-comparison
rm -rf evidence/visual.spec.js-snapshots
block visual-first
run 'npx playwright test --config evidence.config.js evidence/visual.spec.js' | nocolor
block visual-second
run 'npx playwright test --config evidence.config.js evidence/visual.spec.js' | nocolor
run 'ls -la evidence/visual.spec.js-snapshots/'
block visual-changed
cp app/public/style.css /tmp/l16-style.css
sed -i 's/border: 1px solid #c9d6c3/border: 1px solid #2f6f4e/' app/public/style.css
run 'npx playwright test --config evidence.config.js evidence/visual.spec.js' | nocolor
run 'ls -la test-results/visual-*/'
cp /tmp/l16-style.css app/public/style.css; chown ana:ana app/public/style.css
