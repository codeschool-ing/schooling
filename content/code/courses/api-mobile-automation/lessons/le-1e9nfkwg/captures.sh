#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of api-mobile-automation, as the
# script that produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT RAN AND WHAT COULD NOT. Everything on the computer's side ran: the slow
# proxy the lesson shows whole, in front of boxoffice and in front of the
# payments stub of lesson 11; curl through it; and the test the lesson writes,
# with the retry helper of lesson 13. What could not run is anything on the
# phone's side (lesson 14): taking the network away from an emulator, the
# emulator's console, Appium's connectivity commands and the Espresso test
# class are written for the student and were not run, and the lesson says so.
# What is recorded of them: where Tickets sets its timeouts, read with grep;
# the emulator's own help text for its network options, which needs no
# emulator running; and the app's sources still compiling (`lab.sh appcheck`).
# What is STAGED rather than typed:
#   - boxoffice, the proxy and the stub, started in the background where the
#     lesson starts each in a terminal of its own, and restarted where the
#     lesson says to stop one with Ctrl-C; the lines shown under each start,
#     and the logs, are read from their log files;
#   - the token, which the student copies into TOKEN as in lesson 3; here it is
#     read from the same answer;
#   - the logs of the slow payments are read after a second's pause, so that
#     the charge boxoffice gave up on has finished, as it has by the time a
#     student looks at the terminal.
# Timings, the token and the order ids differ from run to run; which answers
# the proxy drops does not, because SEED fixes it.
#
# Recorded 2026-10-16 on Ubuntu 24.04 with Node 22.22.0, curl 8.5.0, jq 1.7.1
# and emulator 36.1.9, TZ=America/Sao_Paulo, as user ana. See ../../lab.sh for
# the rest.

source "$(dirname "$0")/../../lab.sh"
project 22 /home/ana/boxoffice
lab_appcheck /home/ana/boxoffice >&2 || { echo "captures: the app does not compile" >&2; exit 1; }
here /home/ana/boxoffice
trap 'halt proxy; halt pay; halt api; halt stub' EXIT

TAP='node --test --test-reporter=tap'
T="-w '%{http_code} %{time_total}\\n'"
A="-H \"authorization: Bearer \$TOKEN\" -H 'content-type: application/json'"
# proxy NAME ENV: start the slow proxy with ENV in front, and show the start.
proxy() {
  halt "$1"
  prompt; echo "${2:+$2 }node slow-proxy.mjs"
  serve "$1" "${2:+$2 }node slow-proxy.mjs"
  cat "/tmp/lab-$1.log"
}

serve api 'node boxoffice.mjs'

# ---- a-bad-network -----------------------------------------------------------
block proxy-start
proxy proxy ''

block direct
run "curl -s -o /dev/null $T localhost:8080/v1/shows"
run "curl -s -o /dev/null $T localhost:8070/v1/shows"

block delay
proxy proxy 'DELAY=800'
run "curl -s -o /dev/null $T localhost:8070/v1/shows"

block rate
proxy proxy 'RATE=200'
run "curl -s -o /dev/null -w '%{http_code} %{size_download} bytes, first byte %{time_starttransfer}, last %{time_total}\\n' localhost:8070/v1/shows"

block drop
proxy proxy 'DROP=0.3'
run "for i in \$(seq 10); do curl -s -o /dev/null -w '%{http_code} ' localhost:8070/v1/shows; done; echo"

block drop-log
prompt; echo 'DROP=0.3 node slow-proxy.mjs'
cat /tmp/lab-proxy.log

block too-slow
proxy proxy 'DELAY=6000'
run 'curl -sS --max-time 5 localhost:8070/v1/shows; echo "exit $?"'

# ---- the-api-under-it --------------------------------------------------------
block token
run "TOKEN=\$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)"
LAB_EXTRA="TOKEN=$(as_ana "curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token")"

block no-key
proxy proxy 'DROP=0.5 SEED=7'
run "for i in 1 2 3; do curl -sS localhost:8070/v1/orders $A -d '{\"show_id\":\"sh-103\",\"seats\":1}'; echo; done"
run 'curl -s localhost:8080/v1/shows/sh-103 | jq .seats_left'

block with-key
proxy proxy 'DROP=0.5 SEED=7'
run "for i in 1 2 3; do curl -sS -i localhost:8070/v1/orders $A -H 'idempotency-key: one-seat-7c1e' -d '{\"show_id\":\"sh-102\",\"seats\":1}' | grep -iE '^HTTP|^idempotent|^\\{'; echo; done"
run 'curl -s localhost:8080/v1/shows/sh-102 | jq .seats_left'

block with-key-log
prompt; echo 'DROP=0.5 SEED=7 node slow-proxy.mjs'
cat /tmp/lab-proxy.log
halt proxy

block poor-run
run "$TAP tests/poor-network.test.mjs | grep -E '^(not )?ok|^# (pass|fail)'"

halt api
block slow-pay-start
prompt; echo 'node payments-stub.mjs'
serve stub 'node payments-stub.mjs'
head -1 /tmp/lab-stub.log
proxy pay 'PORT=8071 TARGET=http://localhost:8090 DELAY=1500'
prompt; echo 'PAYMENTS_URL=http://localhost:8071 node boxoffice.mjs'
serve api 'PAYMENTS_URL=http://localhost:8071 node boxoffice.mjs'
head -1 /tmp/lab-api.log

block slow-pay
run "curl -s -o /dev/null $T localhost:8080/v1/orders $A -d '{\"show_id\":\"sh-103\",\"seats\":2}'"

block slower-pay
proxy pay 'PORT=8071 TARGET=http://localhost:8090 DELAY=2500'
run "curl -s -o /dev/null $T localhost:8080/v1/orders $A -d '{\"show_id\":\"sh-103\",\"seats\":2}'"

block slower-pay-after
sleep 1
run "curl -s localhost:8090/__requests | jq -c '.[]'"
run 'curl -s localhost:8080/v1/shows/sh-103 | jq .seats_left'

block slower-pay-log
prompt; echo 'PORT=8071 TARGET=http://localhost:8090 DELAY=2500 node slow-proxy.mjs'
cat /tmp/lab-pay.log
prompt; echo 'node payments-stub.mjs'
cat /tmp/lab-stub.log
halt pay; halt api; halt stub

# ---- the-app-offline ---------------------------------------------------------
block timeouts
run "grep -n 'Timeout\\|catch\\|return Loaded\\|Loaded\\.\\(Fresh\\|Offline\\)(' tickets/app/src/main/java/example/tickets/Shows.kt"

block netspeed
run 'emulator -help-netspeed'
