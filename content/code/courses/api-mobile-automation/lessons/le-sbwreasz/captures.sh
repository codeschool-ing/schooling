#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of api-mobile-automation, as the
# script that produces them. Every transcript in the lesson was copied from its
# output, where each block starts with a line `##### <name>`.
#
#   sudo bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON. Section `a-stub` shows
# payments-stub.mjs whole, section `wiremock` shows the two mapping files and
# downloads WireMock's standalone jar from Maven Central with curl, section
# `prism` runs Prism from npm with npx, and section `when-the-mock-lies` shows
# payments.yaml whole. ../../lab.sh writes the project from those very blocks
# before anything runs; openapi.yaml comes from lesson 2 the same way. Java 21
# is the one lesson 7 installed. What is STAGED rather than typed:
#   - every server, started in the background where the lesson starts it in a
#     terminal of its own; the lines the lesson shows under each start are
#     read from that server's log;
#   - Prism's own log, which is not shown: it marks every line with symbols
#     the course's transcripts cannot draw, so the lesson says in words what
#     it printed;
#   - the order in which servers are stopped, which the lesson does with
#     Ctrl-C in their terminals. npx starts Prism as a child process, so it is
#     stopped with its children;
#   - curl's link marks: on a terminal it writes a location header as a link
#     (OSC 8), and those escape codes are removed like the colour ones.
# The Date header, WireMock's Matched-Stub-Id and the id of a mapping added
# through its admin API differ on every run, and so does the token.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4, curl
# 8.5.0, jq 1.7.1, OpenJDK 21, WireMock 3.13.2 and Prism 5.14.2,
# TZ=America/Sao_Paulo, as user ana. See ../../lab.sh for the rest.

source "$(dirname "$0")/../../lab.sh"
# curl marks a location header as a link when it writes to a terminal (OSC 8);
# those escape codes are removed with the colour ones, as lab.sh's strip does.
strip() { sed -e 's/\x1b\]8;[^\x1b]*\x1b\\//g' -e 's/\x1b\[[0-9;?]*[A-Za-z]//g' -e 's/\r$//'; }
project 11 /home/ana/boxoffice
here /home/ana/boxoffice

# start NAME CMD URL: like serve, for a server that never prints "listening";
# it waits until URL answers instead, for up to two minutes.
start() {
  as_ana "$2 > /tmp/lab-$1.log 2>&1 < /dev/null 9>&- & echo \$! > /tmp/lab-$1.pid"
  for _ in $(seq 1200); do
    as_ana "curl -s -o /dev/null $3" && return 0
    sleep 0.1
  done
  echo "lab: $1 did not answer at $3" >&2; cat "/tmp/lab-$1.log" >&2; return 1
}

# halt_tree NAME: halt, and every process below it first, by pid.
kids() { local p; for p in $(pgrep -P "$1"); do kids "$p"; echo "$p"; done; }
halt_tree() {
  [ -f "/tmp/lab-$1.pid" ] || return 0
  local top; top=$(cat "/tmp/lab-$1.pid")
  kill $(kids "$top") "$top" 2>/dev/null
  rm -f "/tmp/lab-$1.pid"
  sleep 0.5
}

J="-H 'content-type: application/json'"
A="-H \"authorization: Bearer \$TOKEN\""
order() { echo "curl -s localhost:8080/v1/orders $A $J -d '{\"show_id\":\"sh-101\",\"seats\":$1}'"; }

# ---- a-stub ------------------------------------------------------------------
block start-stub
prompt; echo 'node payments-stub.mjs'
serve stub 'node payments-stub.mjs'
head -1 /tmp/lab-stub.log

block start-boxoffice
prompt; echo 'PAYMENTS_URL=http://localhost:8090 node boxoffice.mjs'
serve api 'PAYMENTS_URL=http://localhost:8090 node boxoffice.mjs'
head -1 /tmp/lab-api.log

block token
run "TOKEN=\$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)"
LAB_EXTRA="TOKEN=$(as_ana "curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token")"

block order
run "$(order 2) | jq"

block requests
run 'curl -s localhost:8090/__requests | jq'

block decline
run 'curl -s -X PUT localhost:8090/__mode -d decline'
run "$(order 2)"

block stub-log
prompt; echo 'node payments-stub.mjs'
cat /tmp/lab-stub.log

block bad-mode
run 'MODE=declined node payments-stub.mjs'
halt api

# ---- wiremock ----------------------------------------------------------------
block wm-download
run 'curl -fsSL -o wiremock/wiremock-standalone-3.13.2.jar https://repo1.maven.org/maven2/org/wiremock/wiremock-standalone/3.13.2/wiremock-standalone-3.13.2.jar'
run 'ls -lh wiremock/*.jar'

block wm-start
prompt; echo 'java -jar wiremock/wiremock-standalone-3.13.2.jar --port 8091 --root-dir wiremock --disable-banner'
start wm 'java -jar wiremock/wiremock-standalone-3.13.2.jar --port 8091 --root-dir wiremock --disable-banner' localhost:8091/__admin/health
sleep 0.5
cat /tmp/lab-wm.log

block wm-charges
run "curl -si localhost:8091/charges $J -d '{\"amount_cents\":16000,\"reference\":\"ord-1001\"}'"
echo
run "curl -s localhost:8091/charges $J -d '{\"amount_cents\":48000,\"reference\":\"ord-1002\"}'; echo"

block wm-miss
run "curl -si localhost:8091/charges $J -d '{\"amount\":16000,\"reference\":\"ord-1003\"}'"

block wm-clear
run 'curl -s -X DELETE localhost:8091/__admin/requests; echo'

block wm-boxoffice
prompt; echo 'PAYMENTS_URL=http://localhost:8091 node boxoffice.mjs'
serve api 'PAYMENTS_URL=http://localhost:8091 node boxoffice.mjs'
head -1 /tmp/lab-api.log

block wm-orders
run "$(order 2)"
run "$(order 6)"

block wm-verify
run "curl -s localhost:8091/__admin/requests/count -d '{\"method\":\"POST\",\"url\":\"/charges\"}'; echo"
run "curl -s localhost:8091/__admin/requests | jq -c '.requests[].request | {key: .headers[\"idempotency-key\"], body}'"

# ---- prism -------------------------------------------------------------------
block prism-engines
run 'npm view @stoplight/prism-cli@5.15.11 engines'
run 'npm view @stoplight/prism-cli@5.14.2 engines'

start prism 'npx --yes @stoplight/prism-cli@5.14.2 mock openapi.yaml' localhost:4010/health

P4="-H 'authorization: Bearer anything'"
block prism-shows
run 'curl -s localhost:4010/v1/shows | jq'

block prism-order
run "curl -si localhost:4010/v1/orders $P4 $J -d '{\"show_id\":\"sh-103\",\"seats\":2}'; echo"

block prism-knows-nothing
run 'curl -s localhost:4010/v1/shows/sh-999; echo'
run 'curl -s localhost:4010/oauth/token -d grant_type=client_credentials -d client_id=nobody -d client_secret=wrong; echo'

block prism-seven
run "curl -si localhost:4010/v1/orders $P4 $J -d '{\"show_id\":\"sh-103\",\"seats\":7}' | grep -iE '^HTTP|^sl-violations'"

block prism-notoken
run "curl -si localhost:4010/v1/orders $J -d '{\"show_id\":\"sh-103\",\"seats\":2}' | grep -iE '^HTTP|^sl-violations'"

block prism-unknown
run "curl -si localhost:4010/v1/orders $P4 $J -d '{\"show_id\":\"sh-103\",\"seats\":2,\"seat_class\":\"vip\"}' | grep -iE '^HTTP|^sl-violations'"
run "curl -s -o /dev/null -w '%{http_code}\\n' localhost:8080/v1/orders $A $J -d '{\"show_id\":\"sh-103\",\"seats\":2,\"seat_class\":\"vip\"}'"

block prism-date
run "curl -si 'localhost:4010/v1/shows?date=tomorrow' | grep -iE '^HTTP|^sl-violations'"
run "curl -s 'localhost:8080/v1/shows?date=tomorrow'"

block prism-prefer
run "curl -si localhost:4010/v1/orders $P4 $J -H 'Prefer: code=409' -d '{\"show_id\":\"sh-103\",\"seats\":2}' | head -1"
halt_tree prism

# ---- when-the-mock-lies ------------------------------------------------------
block lie-add
run "curl -s localhost:8091/__admin/mappings -d '{\"priority\":1,\"request\":{\"method\":\"POST\",\"url\":\"/charges\"},\"response\":{\"status\":200,\"jsonBody\":{\"id\":\"ch-wm-3\",\"status\":\"approved\"}}}' | jq -c '{id, response}'"

block lie-order
run "$(order 2)"

block lie-log
prompt; echo 'PAYMENTS_URL=http://localhost:8091 node boxoffice.mjs'
cat /tmp/lab-api.log

start proxy 'npx --yes @stoplight/prism-cli@5.14.2 proxy payments.yaml http://localhost:8091 --errors' localhost:4010/

C="-d '{\"amount_cents\":16000,\"reference\":\"ord-9001\"}'"
block proxy-lie
run "curl -si localhost:4010/charges $J -H 'idempotency-key: try-1' $C | grep -iE '^HTTP|^sl-violations'"

block proxy-reset
run 'curl -s -X POST localhost:8091/__admin/mappings/reset'
run "curl -si localhost:4010/charges $J -H 'idempotency-key: try-2' $C | grep -iE '^HTTP|^sl-violations|^\\{'"

block proxy-request
run "curl -si localhost:4010/charges $J $C | grep -iE '^HTTP|^sl-violations'"

halt_tree proxy
halt api
halt_tree wm
halt stub
