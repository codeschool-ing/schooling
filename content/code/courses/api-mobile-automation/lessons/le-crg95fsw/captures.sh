#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of api-mobile-automation, as the
# script that produces them. Every transcript in the lesson was copied from its
# output, where each block starts with a line `##### <name>`.
#
#   sudo bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. Lesson 1 installs the tools
# and shows boxoffice.mjs whole, lesson 2 shows openapi.yaml, and this lesson
# shows .gitignore; ../../lab.sh writes them into the project from those very
# blocks before anything runs. What is STAGED rather than typed:
#   - the server, started in the background where the lesson starts it in a
#     second terminal; each restart ("restart", "short-lived", "env-file")
#     stops it by its pid where the student presses Ctrl-C, and prints the
#     command and the first line the second terminal shows. "key-in-url" prints
#     the line that terminal showed for that request, read from its log;
#   - the variables TOKEN, AUDITOR, FORGED, VERIFIER and SHORT, and the shell function
#     `code`, each typed once in the lesson; every command runs in a fresh
#     shell here, so they are passed to each one again (LAB_EXTRA for the
#     variables, CODE below for the function).
# The Date header, every token and the random values differ on every run.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Node 22.22.0, curl 8.5.0, jq 1.7,
# git 2.43.0, TZ=America/Sao_Paulo, as user ana. See ../../lab.sh for the rest.

source "$(dirname "$0")/../../lab.sh"
project 3 /home/ana/boxoffice
here /home/ana/boxoffice
serve api 'node boxoffice.mjs'

tokenof() { as_ana "curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=$1 -d client_secret=$2 | jq -r .access_token"; }
# restart TITLE CMD: the student's Ctrl-C and a new start in the second terminal.
restart() {
  halt api
  prompt; printf '%s\n' "$1"
  serve api "$1"
  head -1 /tmp/lab-api.log
}

# ---- api-key
block report-none
run 'curl -si localhost:8080/v1/reports/sales'

block report-key
run "curl -s localhost:8080/v1/reports/sales -H 'X-Api-Key: guess'"
run "curl -s localhost:8080/v1/reports/sales -H 'X-Api-Key: lab-only-staff-key'"

block key-in-url
run "curl -s 'localhost:8080/v1/reports/sales?key=lab-only-staff-key'"

block key-in-url-log
grep 'key=' /tmp/lab-api.log

# ---- tokens
block token-response
run 'curl -si localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret'

block token-refused
run 'curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=wrong'

block token
run "TOKEN=\$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)"
TOKEN=$(tokenof ci-tests ci-secret)
LAB_EXTRA="TOKEN=$TOKEN"

# ---- jwt
block parts
run 'echo "$TOKEN" | tr . "\n"'

block decode
run "node -e 'for (const part of process.argv[1].split(\".\").slice(0, 2)) console.log(Buffer.from(part, \"base64url\").toString())' \"\$TOKEN\""

block lifetime
run "node -e 'const c = JSON.parse(Buffer.from(process.argv[1].split(\".\")[1], \"base64url\")); console.log(c.exp - c.iat, new Date(c.exp * 1000).toString())' \"\$TOKEN\""

block auditor
run "AUDITOR=\$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=auditor -d client_secret=auditor-secret | jq -r .access_token)"
AUDITOR=$(tokenof auditor auditor-secret)
LAB_EXTRA="TOKEN=$TOKEN AUDITOR=$AUDITOR"

block forge
FORGE='const [head, body, sig] = process.argv[1].split("."); const claims = JSON.parse(Buffer.from(body, "base64url")); claims.scope = "orders:read orders:write"; console.log([head, Buffer.from(JSON.stringify(claims)).toString("base64url"), sig].join("."))'
run "FORGED=\$(node -e '$FORGE' \"\$AUDITOR\")"
FORGED=$(as_ana "node -e '$FORGE' \"$AUDITOR\"")
LAB_EXTRA="TOKEN=$TOKEN AUDITOR=$AUDITOR FORGED=$FORGED"

block forged
run "curl -si localhost:8080/v1/orders -H \"authorization: Bearer \$FORGED\" -H 'content-type: application/json' -d '{\"show_id\":\"sh-101\",\"seats\":1}' | grep -iE '^HTTP|^www'"

# ---- 401 and 403
CODE="code() { curl -s -o /dev/null -w '%{http_code}\\n' \"\$@\"; }"
runc() { prompt; printf '%s\n' "$1"; as_ana "script -qec $(printf '%q' "$CODE; $1") /dev/null" 2>&1 | strip; }
J="-H 'content-type: application/json' -d '{\"show_id\":\"sh-101\",\"seats\":1}'"

block define
prompt; printf '%s\n' "$CODE"

block matrix-ci
runc "code localhost:8080/v1/orders -H \"authorization: Bearer \$TOKEN\" $J"
runc "code localhost:8080/v1/orders/ord-1001 -H \"authorization: Bearer \$TOKEN\""

block matrix-auditor
runc "code localhost:8080/v1/orders -H \"authorization: Bearer \$AUDITOR\" $J"
runc "code localhost:8080/v1/orders/ord-1001 -H \"authorization: Bearer \$AUDITOR\""
runc "code -X DELETE localhost:8080/v1/orders/ord-1001 -H \"authorization: Bearer \$AUDITOR\""

block matrix-cross
runc "code localhost:8080/v1/orders/ord-1001 -H 'X-Api-Key: lab-only-staff-key'"
runc "code localhost:8080/v1/reports/sales -H \"authorization: Bearer \$TOKEN\""

block forbidden
run "curl -si localhost:8080/v1/orders -H \"authorization: Bearer \$AUDITOR\" $J | grep -iE '^HTTP|^www'"

block lowercase
run "curl -si localhost:8080/v1/orders/ord-1001 -H \"authorization: bearer \$TOKEN\" | grep -iE '^HTTP|^www'"

block matrix-delete
runc "code -X DELETE localhost:8080/v1/orders/ord-1001 -H \"authorization: Bearer \$TOKEN\""

# ---- oauth in apps
block pkce
GEN="node -e 'console.log(require(\"crypto\").randomBytes(32).toString(\"base64url\"))'"
run "VERIFIER=\$($GEN)"
VERIFIER=$(as_ana "$GEN")
SAVED_EXTRA=$LAB_EXTRA
LAB_EXTRA="$LAB_EXTRA VERIFIER=$VERIFIER"
run 'echo "$VERIFIER"'
run "node -e 'console.log(require(\"crypto\").createHash(\"sha256\").update(process.argv[1]).digest(\"base64url\"))' \"\$VERIFIER\""
LAB_EXTRA=$SAVED_EXTRA

# ---- secrets
block xtrace
run "bash -xc 'curl -s -o /dev/null localhost:8080/v1/orders/ord-1001 -H \"authorization: Bearer \$TOKEN\"'"

# ---- jwt, continued: what a restart does to a token
block restart
restart 'node boxoffice.mjs'

block after-restart
runc "code localhost:8080/v1/orders -H \"authorization: Bearer \$TOKEN\" $J"

block short-lived
restart 'TOKEN_TTL=5 node boxoffice.mjs'

block expired
run "SHORT=\$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)"
SHORT=$(tokenof ci-tests ci-secret)
LAB_EXTRA="TOKEN=$TOKEN AUDITOR=$AUDITOR SHORT=$SHORT"
runc "code localhost:8080/v1/orders -H \"authorization: Bearer \$SHORT\" $J"
run 'sleep 6'
run "curl -si localhost:8080/v1/orders -H \"authorization: Bearer \$SHORT\" $J | grep -iE '^HTTP|^www'"

# ---- secrets, continued
block env-file
run "echo \"TOKEN_SECRET=\$(node -e 'console.log(require(\"crypto\").randomBytes(32).toString(\"base64url\"))')\" > .env"
run 'wc -c .env'

block env-start
restart 'node --env-file=.env boxoffice.mjs'

block old-secret
run "curl -si localhost:8080/v1/orders/ord-1001 -H \"authorization: Bearer \$TOKEN\" | grep -iE '^HTTP|^www'"

block git
run 'git init -q'
run 'git status --short'

halt api
rm -rf /home/ana/boxoffice/.git
