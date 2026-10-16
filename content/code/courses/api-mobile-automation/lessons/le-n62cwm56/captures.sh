#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of api-mobile-automation, as the
# script that produces them. Every transcript in the lesson was copied from its
# output, where each block starts with a line `##### <name>`.
#
#   sudo bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON. Every file under tests/ and
# run-integration.sh are shown whole in the lesson, and ../../lab.sh writes
# the project from those very blocks before anything runs; payments-stub.mjs
# comes from lesson 11 the same way. What is STAGED rather than typed:
#   - boxoffice and the payments stub, started in the background where the
#     lesson starts them in terminals of their own, and restarted between the
#     runs of section `order-dependence` where the lesson says to restart
#     boxoffice; the lines shown under each start are read from the logs;
#   - two edits the student makes by hand. In `node-test` the HEAD test gets
#     the `todo` option the lesson shows, applied here with sed after the run
#     that fails without it. In `order-dependence` the first versions of
#     seats.test.mjs and sellout.test.mjs, shown whole in the lesson before
#     the fixed ones, are written from their blocks in the lesson's own prose
#     for the runs that use them, then replaced by the fixed ones, which are
#     what lab.sh wrote.
# Durations, the Date header and the token differ on every run, and so does
# the path in a stack trace if the project lives elsewhere.
#
# Recorded 2026-10-16 on Ubuntu 24.04 with Node 22.22.0, curl 8.5.0, jq
# 1.7.1, TZ=America/Sao_Paulo, as user ana. See ../../lab.sh for the rest.

source "$(dirname "$0")/../../lab.sh"
strip() { sed -e 's/\x1b\]8;[^\x1b]*\x1b\\//g' -e 's/\x1b\[[0-9;?]*[A-Za-z]//g' -e 's/\r$//'; }
project 12 /home/ana/boxoffice
here /home/ana/boxoffice
P=/home/ana/boxoffice
HERE=$(cd "$(dirname "$0")" && pwd)
trap 'halt api; halt stub' EXIT

# first_version PATH SLUG: the FIRST block the section SLUG of this lesson
# saves as PATH, written to the project (lab.sh keeps the last one).
first_version() {
  python3 - "$HERE/$2.md" "$P/$1" "$1" <<'PY'
import re, sys
md, dest, path = sys.argv[1:]
lines = open(md).read().split("\n")
for i, l in enumerate(lines):
    if re.search(r"[Ss]ave it as `" + re.escape(path) + r"`:\s*$", l):
        j = i + 1
        while not lines[j].startswith("```"): j += 1
        k = j + 1
        while not lines[k].startswith("```"): k += 1
        open(dest, "w").write("\n".join(lines[j + 1:k]) + "\n")
        break
PY
  chown ana:ana "$P/$1"
}
restart_api() { halt api; serve api "$1"; }
TAP='node --test --test-reporter=tap'
SUMMARY="grep -E '^(not )?ok|^# (pass|fail|todo)'"

# ---- node-test ---------------------------------------------------------------
block start
prompt; echo 'node boxoffice.mjs'
serve api 'node boxoffice.mjs'
head -1 /tmp/lab-api.log

block first-run
rc_run() { rm -f /tmp/lab-rc; prompt; printf '%s\n' "$1"; as_ana "script -qec $(printf '%q' "$1") /dev/null; echo \$? > /tmp/lab-rc" 2>&1 | strip; }
rc_run "$TAP tests/shows.test.mjs"
prompt; echo 'echo $?'; cat /tmp/lab-rc

sed -i "s/test('HEAD answers like GET, without a body', async () => {/test('HEAD answers like GET, without a body', { todo: 'boxoffice answers HEAD with 405, lesson 1' }, async () => {/" $P/tests/shows.test.mjs
grep -q "todo: 'boxoffice answers HEAD" $P/tests/shows.test.mjs || { echo "captures: the todo edit did not apply" >&2; exit 1; }

block todo-run
rc_run "$TAP tests/shows.test.mjs > shows.tap"
prompt; echo 'echo $?'; cat /tmp/lab-rc
run "grep -E '^(not )?ok|^# (pass|fail|todo)' shows.tap"

# ---- two-services ------------------------------------------------------------
block start-two
prompt; echo 'node payments-stub.mjs'
serve stub 'node payments-stub.mjs'
head -1 /tmp/lab-stub.log
prompt; echo 'PAYMENTS_URL=http://localhost:8090 node boxoffice.mjs'
restart_api 'PAYMENTS_URL=http://localhost:8090 node boxoffice.mjs'
head -1 /tmp/lab-api.log

block payments-run
run "$TAP tests/payments.test.mjs | $SUMMARY"

block stub-log
prompt; echo 'node payments-stub.mjs'
cat /tmp/lab-stub.log

# ---- order-dependence --------------------------------------------------------
first_version tests/seats.test.mjs order-dependence
first_version tests/sellout.test.mjs order-dependence
grep -q 'start(' $P/tests/seats.test.mjs && { echo "captures: seats is not the first version" >&2; exit 1; }

restart_api 'PAYMENTS_URL=http://localhost:8090 node boxoffice.mjs'
block alone-sellout
run "$TAP tests/sellout.test.mjs | $SUMMARY"

restart_api 'PAYMENTS_URL=http://localhost:8090 node boxoffice.mjs'
block alone-seats
run "$TAP tests/seats.test.mjs | $SUMMARY"

block seats-again
run "$TAP tests/seats.test.mjs"

restart_api 'PAYMENTS_URL=http://localhost:8090 node boxoffice.mjs'
block together
run "$TAP --test-concurrency=1 tests/seats.test.mjs tests/sellout.test.mjs | $SUMMARY"

block together-reversed
restart_api 'PAYMENTS_URL=http://localhost:8090 node boxoffice.mjs'
run "$TAP --test-concurrency=1 tests/sellout.test.mjs tests/seats.test.mjs | $SUMMARY"

# the fixed versions, as lab.sh wrote them from the last blocks
project 12 /tmp/lab-l12-fixed
cp /tmp/lab-l12-fixed/tests/seats.test.mjs /tmp/lab-l12-fixed/tests/sellout.test.mjs $P/tests/
chown ana:ana $P/tests/*.mjs
rm -rf /tmp/lab-l12-fixed

block fixed
run "$TAP tests/seats.test.mjs tests/sellout.test.mjs | $SUMMARY"
run "$TAP tests/seats.test.mjs tests/sellout.test.mjs | $SUMMARY"

# ---- eventually --------------------------------------------------------------
restart_api 'PAYMENTS_URL=http://localhost:8090 node boxoffice.mjs'
block token
run "TOKEN=\$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)"
LAB_EXTRA="TOKEN=$(as_ana "curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token")"

block lag
K="-H 'x-api-key: lab-only-staff-key'"
run "curl -s -o /dev/null -w '%{http_code}\\n' localhost:8080/v1/orders -H \"authorization: Bearer \$TOKEN\" -H 'content-type: application/json' -d '{\"show_id\":\"sh-101\",\"seats\":3}'; curl -s localhost:8080/v1/reports/sales $K"
run "sleep 1; curl -s localhost:8080/v1/reports/sales $K"

block report-run
run "$TAP tests/report.test.mjs | $SUMMARY"

block report-slow
rc_run "REPORT_DELAY=5000 $TAP tests/report.test.mjs > slow.tap"
prompt; echo 'echo $?'; cat /tmp/lab-rc
run 'head -30 slow.tap'

# ---- in-the-pipeline-order ---------------------------------------------------
block taken
rc_run 'bash run-integration.sh'
prompt; echo 'echo $?'; cat /tmp/lab-rc

halt api
halt stub

block race
run 'node boxoffice.mjs > /dev/null & curl -s localhost:8080/health; echo "curl: $?"; kill $!'

block pipeline
rc_run 'bash run-integration.sh'
prompt; echo 'echo $?'; cat /tmp/lab-rc

block after
run "curl -s localhost:8080/health; echo \"curl: \$?\""
run 'ls *.log *.tap'
