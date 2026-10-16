#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of api-mobile-automation, as the
# script that produces them. Every transcript in the lesson was copied from its
# output, where each block starts with a line `##### <name>`.
#
#   sudo bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON. The schemas, schemas/check.mjs,
# the schema collection, the new pom.xml and SchemaTest.java, and the three
# files under pact/ are shown whole in the lesson, and ../../lab.sh writes the
# project from those very blocks before anything runs; package.json, the lab
# environment and the REST Assured project come from lessons 4 to 7 the same
# way. ajv, ajv-formats and Pact are installed with the npm commands the
# lesson shows. What is STAGED rather than typed:
#   - `npm install`, run quietly first, which puts back the Newman that lesson
#     6 installed from the package.json it shows;
#   - boxoffice, started in the background where the lesson keeps it running
#     in a terminal of its own, and restarted once, for the Pact runs, so that
#     sh-103 has its four seats again;
#   - three edits the student makes by hand: the first schemas/order.json and
#     the first view of the collection and of SchemaTest.java, shown in the
#     lesson before the change it asks for, are written from the lesson's own
#     blocks (the order schema) or with sed applying the one line the lesson
#     prints (the `delete show.$schema` line, the @Disabled annotation);
#   - the network for the Pact verifier. This sandbox reaches the internet
#     through a proxy that lab.sh puts in the environment, and Pact's verifier
#     sends even its requests to localhost through it, which a student's
#     machine, with no proxy, never does; the proxy variables are emptied for
#     the two verifier runs;
#   - the json-schema-validator module's dependencies in ana's ~/.m2. Maven
#     Central answered this sandbox with 429 and 404 for some of them on the
#     day of the recording, so they were copied into ana's local repository
#     from the copy an earlier download on the same machine had left. Maven
#     reads them from there exactly as it would after downloading them.
# Timestamps, process ids, ports Pact picks, durations, the Date header and
# the token differ on every run.
#
# Recorded 2026-10-16 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4, OpenJDK
# 21, Maven 3.8.7, TZ=America/Sao_Paulo, as user ana. See ../../lab.sh.

source "$(dirname "$0")/../../lab.sh"
strip() { sed -e 's/\x1b\]8;[^\x1b]*\x1b\\//g' -e 's/\x1b\[[0-9;?]*[A-Za-z]//g' -e 's/\r$//'; }
project 10 /home/ana/boxoffice
here /home/ana/boxoffice
P=/home/ana/boxoffice
HERE=$(cd "$(dirname "$0")" && pwd)
trap 'halt api' EXIT

rc_run() { rm -f /tmp/lab-rc; prompt; printf '%s\n' "$1"; as_ana "script -qec $(printf '%q' "$1") /dev/null; echo \$? > /tmp/lab-rc" 2>&1 | strip; }
first_version() { # PATH SLUG: the first block section SLUG saves as PATH
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

quiet 'npm install --no-audit --no-fund'
serve api 'node boxoffice.mjs'

# ---- validating --------------------------------------------------------------
first_version schemas/order.json json-schema
grep -q cancelled $P/schemas/order.json && { echo "captures: order.json is not the first version" >&2; exit 1; }

block install-ajv
run 'npm install --save-dev --save-exact ajv@8.20.0 ajv-formats@3.0.1'

block check-show
rc_run 'curl -s localhost:8080/v1/shows/sh-103 | node schemas/check.mjs schemas/show.json'
prompt; echo 'echo $?'; cat /tmp/lab-rc

block check-bad
rc_run "echo '{\"id\":\"sh-1\",\"title\":\"\",\"starts_at\":\"8/11 18h\",\"price_cents\":65.5,\"seats_left\":-1,\"venue\":\"Sala 2\"}' | node schemas/check.mjs schemas/show.json"
prompt; echo 'echo $?'; cat /tmp/lab-rc

block token
run "TOKEN=\$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)"
LAB_EXTRA="TOKEN=$(as_ana "curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token")"

A="-H \"authorization: Bearer \$TOKEN\""
block check-order
run "curl -s localhost:8080/v1/orders $A -H 'content-type: application/json' -d '{\"show_id\":\"sh-101\",\"seats\":2}' | node schemas/check.mjs schemas/order.json"

block check-cancelled
run "curl -s -o /dev/null -w '%{http_code}\\n' -X DELETE localhost:8080/v1/orders/ord-1001 $A"
run "curl -s localhost:8080/v1/orders/ord-1001 $A | node schemas/check.mjs schemas/order.json"

# the corrected schema, as lab.sh wrote it from the last block
project 10 /tmp/lab-l10-fixed
cp /tmp/lab-l10-fixed/schemas/order.json $P/schemas/order.json; chown ana:ana $P/schemas/order.json
rm -rf /tmp/lab-l10-fixed

block check-cancelled-fixed
run "curl -s localhost:8080/v1/orders/ord-1001 $A | node schemas/check.mjs schemas/order.json"

# ---- in-the-tools: Postman and Newman ----------------------------------------
N='npx newman run postman/schemas.postman_collection.json -e postman/lab.postman_environment.json --disable-unicode'
block newman-2020
rc_run "$N"
prompt; echo 'echo $?'; cat /tmp/lab-rc

python3 - "$P/postman/schemas.postman_collection.json" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
old = "\"const show = JSON.parse(pm.collectionVariables.get('showSchema'));\",\n"
new = old + "              \"delete show.$schema; // Postman's validator knows draft-07, not 2020-12\",\n"
assert s.count(old) == 2
open(p, "w").write(s.replace(old, new))
PY

block newman-fixed
run "$N | grep -E 'Pass|^  [0-9]+\\.|assertions'"

# ---- in-the-tools: REST Assured ----------------------------------------------
go restassured
block ra-run
rc_run 'mvn -q test -Dtest=SchemaTest'
prompt; echo 'echo $?'; cat /tmp/lab-rc

T=$P/restassured/src/test/java/boxoffice/SchemaTest.java
sed -i 's|^import org.junit.jupiter.api.Test;|import org.junit.jupiter.api.Disabled;\nimport org.junit.jupiter.api.Test;|' $T
sed -i 's|^    // A confirmed order must carry its payment: the schema.s if/then says so.|&\n    @Disabled("REST Assured'"'"'s validator implements draft 4 and ignores if/then")|' $T
grep -q '@Disabled' $T || { echo "captures: the @Disabled edit did not apply" >&2; exit 1; }

block ra-disabled
run "mvn test -Dtest=SchemaTest | grep -E 'Tests run:|BUILD'"
here /home/ana/boxoffice

# ---- pact --------------------------------------------------------------------
block install-pact
run 'npm install --save-dev --save-exact @pact-foundation/pact@17.1.4'

block consumer-run
run 'node --test --test-reporter=tap pact/consumer.test.mjs'

block pact-file
run "jq '.interactions[0].response' pact/pacts/tickets-app-boxoffice.json"

halt api; serve api 'node boxoffice.mjs'
F="grep -E '^#  |^# Verifying|^# Failures|^# [0-9]\\)|^# There|^(not )?ok'"
SAVED=$LAB_PROXY; LAB_PROXY=
block pact-notice
run "node --test --test-reporter=tap pact/provider.test.mjs | grep -A2 'Please note'"

block provider-run
run "PACT_DO_NOT_TRACK=true node --test --test-reporter=tap pact/provider.test.mjs | $F"
LAB_PROXY=$SAVED

block kiosk-run
run "node --test --test-reporter=tap pact/kiosk.test.mjs | grep -E '^(not )?ok'"
run 'ls pact/pacts'

LAB_PROXY=
block provider-two
run "PACT_DO_NOT_TRACK=true node --test --test-reporter=tap pact/provider.test.mjs | $F"
LAB_PROXY=$SAVED
