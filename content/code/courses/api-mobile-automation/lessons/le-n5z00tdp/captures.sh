#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of api-mobile-automation, as the
# script that produces them. Every transcript in the lesson was copied from its
# output, where each block starts with a line `##### <name>`.
#
#   sudo bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON. Every new file under tests/
# is shown whole in the lesson, and ../../lab.sh writes the project from those
# very blocks before anything runs; payments-stub.mjs comes from lesson 11 and
# tests/lib.mjs and tests/start.mjs from lesson 12 the same way. What is
# STAGED rather than typed:
#   - boxoffice and the payments stub, started in the background where the
#     lesson starts them in terminals of their own; the lines shown under each
#     start, and the logs, are read from their log files;
#   - the stub's log in `timeouts` is read after a pause of a second and a
#     half, so that the slow charge has finished, as it has by the time a
#     student looks at the terminal.
# Durations, timings, the Date header and the token differ on every run.
#
# Recorded 2026-10-16 on Ubuntu 24.04 with Node 22.22.0, curl 8.5.0, jq
# 1.7.1, TZ=America/Sao_Paulo, as user ana. See ../../lab.sh for the rest.

source "$(dirname "$0")/../../lab.sh"
strip() { sed -e 's/\x1b\]8;[^\x1b]*\x1b\\//g' -e 's/\x1b\[[0-9;?]*[A-Za-z]//g' -e 's/\r$//'; }
project 13 /home/ana/boxoffice
here /home/ana/boxoffice
trap 'halt api; halt stub' EXIT

TAP='node --test --test-reporter=tap'
SUMMARY="grep -E '^(not )?ok|^# (pass|fail|todo)'"
A="-H \"authorization: Bearer \$TOKEN\" -H 'content-type: application/json'"
order() { echo "curl $1 localhost:8080/v1/orders $A $2-d '{\"show_id\":\"$3\",\"seats\":$4}'"; }

# ---- idempotency-keys --------------------------------------------------------
block start
prompt; echo 'node payments-stub.mjs'
serve stub 'node payments-stub.mjs'
head -1 /tmp/lab-stub.log
prompt; echo 'PAYMENTS_URL=http://localhost:8090 node boxoffice.mjs'
serve api 'PAYMENTS_URL=http://localhost:8090 node boxoffice.mjs'
head -1 /tmp/lab-api.log

block token
run "TOKEN=\$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)"
LAB_EXTRA="TOKEN=$(as_ana "curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token")"

block replay
run "$(order -s "-H 'idempotency-key: buy-7f3a' " sh-101 2)"
run "$(order -si "-H 'idempotency-key: buy-7f3a' " sh-101 2)"

block different-body
run "$(order -s "-H 'idempotency-key: buy-7f3a' " sh-101 3)"

block charged-once
run "curl -s localhost:8090/__requests | jq -c '.[]'"

block idempotency-run
run "$TAP tests/idempotency.test.mjs | $SUMMARY"

# ---- retries -----------------------------------------------------------------
block retry-run
run "$TAP tests/retry.test.mjs | grep -E '^(not )?ok|^# (tests|pass|fail|duration_ms)'"

# ---- the-error-path ----------------------------------------------------------
block decline
run 'curl -s -X PUT localhost:8090/__mode -d decline'
run "$(order -s '' sh-103 4)"
run 'curl -s localhost:8080/v1/shows/sh-103 | jq .seats_left'

block down
run 'curl -s -X PUT localhost:8090/__mode -d down'
run "$(order -s '' sh-103 4)"
run 'curl -s localhost:8080/v1/shows/sh-103 | jq .seats_left'

block failed-order
run "curl -s localhost:8080/v1/orders/ord-1003 -H \"authorization: Bearer \$TOKEN\""

block api-log
tail -6 /tmp/lab-api.log

block errors-run
run "$TAP tests/errors.test.mjs | $SUMMARY"

# ---- the-race ----------------------------------------------------------------
quiet 'curl -s -X PUT localhost:8090/__mode -d approve; curl -s -X DELETE localhost:8090/__requests'
block race-curl
run "for i in 1 2; do $(order -s "-H 'idempotency-key: tap-tap' " sh-102 1) & done; wait"
run "curl -s localhost:8090/__requests | jq -c '.[]'"

block race-run
run "$TAP tests/race.test.mjs"

# ---- timeouts ----------------------------------------------------------------
quiet 'curl -s -X DELETE localhost:8090/__requests'
block slow
run 'curl -s -X PUT localhost:8090/__mode -d slow'
run "$(order "-s -o /dev/null -w '%{http_code} %{time_total}\\n'" '' sh-103 4)"

block slow-after
sleep 1.5
run "curl -s localhost:8090/__requests | jq -c '.[]'"
run 'curl -s localhost:8080/v1/shows/sh-103 | jq .seats_left'

block stub-log
prompt; echo 'node payments-stub.mjs'
cat /tmp/lab-stub.log

block timeout-run
run "$TAP tests/timeout.test.mjs | grep -E '^(not )?ok|duration_ms|^# (pass|fail)'"
