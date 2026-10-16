#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of api-mobile-automation, as the
# script that produces them. Every transcript in the lesson was copied from its
# output, where each block starts with a line `##### <name>`.
#
#   sudo bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. Lesson 1 installs the tools
# and shows boxoffice.mjs whole; this lesson shows openapi.yaml whole. Both are
# written into the project by ../../lab.sh from those very blocks before
# anything runs. What is STAGED rather than typed:
#   - the server, started in the background where lesson 1 starts it in a
#     second terminal; "crash-log" prints the lines that terminal shows for
#     the request in "null-body", read from its log;
#   - the TOKEN variable and the shell function `order`, each typed once in
#     the lesson; every command runs in a fresh shell here, so they are passed
#     to each one again (LAB_EXTRA for the token, ORDER below for the function).
# The Date header and the token's contents differ on every run.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Node 22.22.0, curl 8.5.0, jq 1.7,
# TZ=America/Sao_Paulo, as user ana. See ../../lab.sh for the rest.

source "$(dirname "$0")/../../lab.sh"
project 2 /home/ana/boxoffice
here /home/ana/boxoffice
serve api 'node boxoffice.mjs'

# ---- resources
block collection
run "curl -s localhost:8080/v1/shows | jq '.shows[].id'"

block filter
run "curl -s 'localhost:8080/v1/shows?date=2026-11-07' | jq -c '.shows[] | {id, starts_at}'"

block token
run "TOKEN=\$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)"
LAB_EXTRA="TOKEN=$(as_ana "curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token")"

block create
run "curl -si localhost:8080/v1/orders -H \"authorization: Bearer \$TOKEN\" -H 'content-type: application/json' -d '{\"show_id\":\"sh-101\",\"seats\":2}' | grep -iE '^HTTP|^location'"

block stateless
run "curl -s localhost:8080/v1/orders/ord-1001 -H \"authorization: Bearer \$TOKEN\""
run "curl -s localhost:8080/v1/orders/ord-1001"

# ---- json
block types
run "curl -s localhost:8080/v1/shows/sh-103 | jq -r 'to_entries[] | \"\\(.key): \\(.value | type)\"'"

block missing
run "curl -s localhost:8080/v1/shows/sh-103 | jq '.discount, has(\"discount\")'"
run "echo '{\"discount\": null}' | jq '.discount, has(\"discount\")'"

block numbers
run "echo '[2, 2.0, 2e0]' | jq -c 'map(. == 2)'"

block money
run "node -e 'console.log(0.1 + 0.2)'"
run "node -e 'console.log(80.10 * 3)'"
run "node -e 'console.log(8010 * 3)'"

block dates
run "TZ=UTC node -e 'console.log(new Date(\"2026-11-08T18:00:00\").toISOString())'"
run "TZ=America/Sao_Paulo node -e 'console.log(new Date(\"2026-11-08T18:00:00\").toISOString())'"
run "TZ=UTC node -e 'console.log(new Date(\"2026-11-08T18:00:00-03:00\").toISOString())'"

block big-id
run "node -e 'console.log(JSON.parse(\"{\\\"id\\\": 9007199254740993}\").id)'"

# ---- the contract
block keys
run "curl -s localhost:8080/v1/shows/sh-103 | jq -c keys"

# ---- errors
block problems
run "curl -s localhost:8080/v1/shows/sh-999"
run "curl -s -X PUT localhost:8080/v1/shows"
run "curl -s localhost:8080/v1/orders"

block problem-type
run "curl -s -o /dev/null -w '%{http_code} %{content_type}\\n' localhost:8080/v1/shows/sh-999"
run "curl -s -o /dev/null -w '%{http_code} %{content_type}\\n' localhost:8080/v1/orders"

block oauth-error
run "curl -s -w '%{http_code} %{content_type}\\n' localhost:8080/oauth/token -d grant_type=password"

# ---- cases from the contract
ORDER="order() { curl -s -w '%{http_code}\\n' localhost:8080/v1/orders -H \"authorization: Bearer \$TOKEN\" -H 'content-type: application/json' -d \"\$1\"; }"
# runo CMD: like run, with the function `order` defined first, as the
# student's terminal has it after typing it once.
runo() { prompt; printf '%s\n' "$1"; as_ana "script -qec $(printf '%q' "$ORDER; $1") /dev/null" 2>&1 | strip; }

block define
prompt; printf '%s\n' "$ORDER"

block boundaries
runo "order '{\"show_id\":\"sh-101\",\"seats\":0}'"
runo "order '{\"show_id\":\"sh-101\",\"seats\":1}'"
runo "order '{\"show_id\":\"sh-101\",\"seats\":6}'"
runo "order '{\"show_id\":\"sh-101\",\"seats\":7}'"

block wrong-types
runo "order '{\"show_id\":\"sh-101\",\"seats\":2.5}'"
runo "order '{\"show_id\":\"sh-101\",\"seats\":\"2\"}'"
runo "order '{\"show_id\":\"sh-101\",\"seats\":2.0}'"

block missing-fields
runo "order '{\"show_id\":\"sh-101\"}'"
runo "order '{\"seats\":2}'"

block unknown-field
runo "order '{\"show_id\":\"sh-101\",\"seats\":1,\"price_cents\":1}'"

block null-body
runo "order 'null'"

block crash-log
sed -n '/^TypeError/,/POST \/v1\/orders 500/p' /tmp/lab-api.log

block bad-date
run "curl -s -w '%{http_code}\\n' 'localhost:8080/v1/shows?date=8-11-2026'"

halt api
