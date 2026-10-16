#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of web-automation, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash captures.sh       # root, because it acts as the user ana
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. `diagnosis` shows
# quarantine.config.js and the first quarantine/typing.spec.js, `quarantine`
# replaces the test with its tagged version, which is what `stage 14` leaves.
# The other test files run here (tests/ssr.spec.js, tests/waiting.spec.js)
# are lessons 6 and 10's. What is STAGED rather than typed, beyond what
# ../../lab.sh's header lists for every lesson:
#   - in "diag-20" and "diag-w1", the first version of the test, taken from
#     `diagnosis` with `lab.sh fence`; the final one is put back after;
#   - in "race-pass", "race-fail" and "race-tally", race.mjs (lesson 3) is run
#     up to 30 times at 145 ms a key; the first run that ended on one fruit
#     and the first that ended on three are printed whole, and the tally says
#     how many runs it took. The selection is the script's, not the student's;
#   - in "with-fail", `test.fail();` inserted with sed as the first line of the
#     test's body, as the section describes, and taken out after;
#   - in "fixed", app/public/search.js with its listener replaced by lesson
#     3's fixed one (lesson 3's "fixed-listener"), and the original put back;
#   - /tmp/run.log is where the section sends a run to read its exit code;
#   - Playwright's colour codes are stripped from the test runs, which is what
#     a terminal shows once it has drawn them.
#
# Recorded 2026-10-16 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4,
# Playwright 1.56.0 and Chromium 141.0.7390.37, TZ=America/Sao_Paulo, on a
# machine with 4 processors (so Playwright's default is 2 workers).

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh" lib
lock
machine
stage 14 || exit 1
P=$REPO_DEFAULT
cd "$P" || exit 1
nocolor() { sed 's/\x1b\[[0-9;]*m//g'; }
SUM="grep -E '^  [0-9]+ (failed|flaky|passed)'"
PAIR='tests/ssr.spec.js tests/waiting.spec.js'

block gate-10
run "for i in 1 2 3 4 5 6 7 8 9 10; do npx playwright test | grep -E '^  [0-9]+ (failed|flaky|passed)|^    tests/'; done" | nocolor

block pair-w1
run "npx playwright test $PAIR --repeat-each 10 --workers 1 | $SUM" | nocolor
block pair-w2
run "npx playwright test $PAIR --repeat-each 10 --workers 2 | grep -E '^  [0-9]+ (failed|flaky|passed)|Expected:|Received:'" | nocolor

bash "$HERE/../../lab.sh" fence "$HERE/diagnosis.md" quarantine/typing.spec.js > quarantine/typing.spec.js
chown ana:ana quarantine/typing.spec.js
block diag-20
run "npx playwright test --config quarantine.config.js --repeat-each 20 | grep -E '✓|✘|^  [0-9]+ (failed|flaky|passed)'" | nocolor
block diag-w1
run "npx playwright test --config quarantine.config.js --repeat-each 20 --workers 1 | $SUM" | nocolor
bash "$HERE/../../lab.sh" fence "$HERE/quarantine.md" quarantine/typing.spec.js > quarantine/typing.spec.js
chown ana:ana quarantine/typing.spec.js

start_app
pass= fail= n=0
for i in $(seq 30); do
  n=$i
  out=$(run 'node race.mjs papaya 145')
  if printf '%s\n' "$out" | tail -1 | grep -q '1 found: Papaya'; then
    [ -n "$pass" ] || pass=$out
  else
    [ -n "$fail" ] || fail=$out
  fi
  [ -n "$pass" ] && [ -n "$fail" ] && break
done
stop_app
block race-pass
printf '%s\n' "$pass"
block race-fail
printf '%s\n' "$fail"
block race-tally
echo "runs: $n"

block retries-typing
run "npx playwright test --config quarantine.config.js --repeat-each 20 --retries 2 | $SUM" | nocolor
block retries-pair
run "npx playwright test $PAIR --repeat-each 10 --retries 2 > /tmp/run.log; echo \"exit code \$?\"" | nocolor
run "$SUM /tmp/run.log" | nocolor
block fail-on-flaky
run "npx playwright test $PAIR --repeat-each 10 --retries 2 --fail-on-flaky-tests > /tmp/run.log; echo \"exit code \$?\"" | nocolor
run "$SUM /tmp/run.log" | nocolor

block gate
run "npx playwright test | $SUM" | nocolor
block quarantine-job
run "npx playwright test --config quarantine.config.js --repeat-each 20 | $SUM" | nocolor

block with-fail
cp quarantine/typing.spec.js /tmp/l14-typing.js
sed -i "s|^}, async ({ page }) => {$|&\n  test.fail();|" quarantine/typing.spec.js
grep -c 'test.fail();' quarantine/typing.spec.js >/dev/null || echo 'with-fail: sed did not apply' >&2
run "npx playwright test --config quarantine.config.js --repeat-each 20 | grep -E 'Expected to fail|^  [0-9]+ (failed|flaky|passed)' | sort | uniq -c" | nocolor
cp /tmp/l14-typing.js quarantine/typing.spec.js; chown ana:ana quarantine/typing.spec.js

block fixed
cp app/public/search.js /tmp/l14-search.js
python3 - app/public/search.js <<'PY'
import sys
s = open(sys.argv[1]).read()
i = s.index("// One request per key")
fixed = """input.addEventListener('input', async () => {
  const asked = input.value;
  waiting += 1;
  results.setAttribute('aria-busy', 'true');
  const response = await fetch('/api/search?q=' + encodeURIComponent(asked));
  const found = await response.json();
  waiting -= 1;
  if (waiting === 0) results.setAttribute('aria-busy', 'false');
  // The fix: an answer to a question the box no longer asks is dropped.
  if (asked !== input.value) return;
  results.replaceChildren(...found.map((p) => {
    const li = document.createElement('li');
    li.textContent = p.name;
    return li;
  }));
  count.textContent = `${found.length} found`;
});
"""
open(sys.argv[1], "w").write(s[:i] + fixed)
PY
run "npx playwright test --config quarantine.config.js --repeat-each 20 | $SUM" | nocolor
cp /tmp/l14-search.js app/public/search.js; chown ana:ana app/public/search.js
rm -f /tmp/run.log
