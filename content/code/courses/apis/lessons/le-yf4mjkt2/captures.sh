#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of apis, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine itself, built by `lab.sh up`
# with every package of lesson 1's "The packages" already installed; `db.py`
# and `rest.py` from lesson 1's "The shelf", and this lesson's `sessions.py`,
# `tokens.py` and `hs256.py`, copied out of the sections that print them by
# `shown` rather than pasted into nano. Each server runs in the background,
# where the lesson has the student run it in a second terminal, and
# `sessions.py` is stopped before `tokens.py` starts, as the lesson says.
# Session ids, CSRF tokens, refresh tokens, `jti`s, signatures, the signing
# key, every timestamp and the Date header differ on every run; the lengths
# (43 and 240 characters, 159 for the payload) do not.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)

machine l08

shown "$HERE_DIR/../le-f6652c1w/the-shelf.md" \
  "$HERE_DIR/cookie-sessions.md" "$HERE_DIR/jwt-decoded.md" "$HERE_DIR/signing.md"
at '~/shelf'

LOGIN_ANA="-H 'Content-Type: application/json' -d '{\"name\": \"ana\", \"password\": \"correct-horse\"}'"
CSRF='-H "X-CSRF-Token: $(curl -s -b jar.txt localhost:8000/me | jq -r .csrf)"'

# --- sessions.py -----------------------------------------------------------
serve 'python3 sessions.py'

block sess-login
run "curl -si -c jar.txt localhost:8000/login $LOGIN_ANA"
run 'cat jar.txt'
run 'curl -s -b jar.txt localhost:8000/me'
run 'curl -si localhost:8000/me'
run "sqlite3 shelf.db 'SELECT id_hash, user_id, expires FROM sessions'"
run "awk '\$6 == \"sid\" {printf \"%s\", \$7}' jar.txt | sha256sum"

block sess-wrong
run "curl -s localhost:8000/login -H 'Content-Type: application/json' -d '{\"name\": \"ana\", \"password\": \"correct-hors\"}'"
run "curl -s localhost:8000/login -H 'Content-Type: application/json' -d '{\"name\": \"anna\", \"password\": \"correct-horse\"}'"

block sess-secure
run "curl -si -c shop.txt --resolve shop.test:8000:127.0.0.1 http://shop.test:8000/login -H 'Content-Type: application/json' -d '{\"name\": \"bruno\", \"password\": \"battery-staple\"}'"
run 'cat shop.txt'

block sess-logout
run 'cp jar.txt kept.txt'
run "curl -si -b jar.txt -c jar.txt -X POST localhost:8000/logout $CSRF"
run 'cat jar.txt'
run 'curl -s -b kept.txt localhost:8000/me'
run "sqlite3 shelf.db 'SELECT user_id, expires FROM sessions'"

block sess-csrf
run "curl -s -c jar.txt localhost:8000/login $LOGIN_ANA"
run "curl -s -w '%{http_code}\n' -b jar.txt localhost:8000/wishlist -H 'Content-Type: application/json' -d '{\"book_id\": 3}'"
run "curl -s -w '%{http_code}\n' -b jar.txt localhost:8000/wishlist -H 'Content-Type: application/json' $CSRF -d '{\"book_id\": 3}'"
run 'curl -s -b jar.txt localhost:8000/wishlist'

stop

# --- tokens.py -------------------------------------------------------------
serve 'python3 tokens.py'

block tok-login
run "curl -s localhost:8000/login $LOGIN_ANA | tee login.json | jq ."
run 'curl -s localhost:8000/me -H "Authorization: Bearer $(jq -r .access_token login.json)"'
run 'curl -si localhost:8000/me'
run 'ls -l jwt.key'

block tok-decode
run 'jq -r .access_token login.json | cut -d. -f1 | base64 -d; echo'
run 'jq -r .access_token login.json | cut -d. -f2 | basenc --base64url -d; echo'
run 'jq -r .access_token login.json | cut -d. -f2 | tr -d "\n" | wc -c'
run "jq -r .access_token login.json | cut -d. -f2 | sed 's/\$/=/' | basenc --base64url -d; echo"

block tok-sign
run 'python3 hs256.py "$(jq -r .access_token login.json)"'
run "jq -r .access_token login.json | sed 's/\\.eyJzdWIiOiIx/.eyJzdWIiOiIy/' > edited.txt"
run "cut -d. -f2 edited.txt | sed 's/\$/=/' | basenc --base64url -d; echo"
run 'python3 hs256.py "$(cat edited.txt)"'
run 'curl -si localhost:8000/me -H "Authorization: Bearer $(cat edited.txt)"'

block tok-claims
run "date -d @\$(jq -r .access_token login.json | cut -d. -f2 | sed 's/\$/=/' | basenc --base64url -d | jq .exp)"
run "python3 -c 'import tokens, time; print(tokens.issue(1, now=time.time() - 310))' > late.txt"
run 'curl -s localhost:8000/me -H "Authorization: Bearer $(cat late.txt)"'
run "python3 -c 'import tokens, time; print(tokens.issue(1, now=time.time() - 600))' > old.txt"
run 'curl -s localhost:8000/me -H "Authorization: Bearer $(cat old.txt)"'
run "python3 -c 'import json, jwt, tokens; t = json.load(open(\"login.json\"))[\"access_token\"]; jwt.decode(t, tokens.KEY, algorithms=[\"HS256\"], audience=\"shelf-admin\")' 2>&1 | tail -1"

block tok-none
run "python3 -c 'import jwt; print(jwt.encode({\"sub\": \"1\", \"iss\": \"shelf\", \"aud\": \"shelf-api\"}, None, algorithm=\"none\"))' > none.txt"
run 'cat none.txt'
run 'curl -s localhost:8000/me -H "Authorization: Bearer $(cat none.txt)"'
run "python3 -c 'import jwt; jwt.decode(open(\"none.txt\").read().strip())' 2>&1 | tail -1"

block tok-refresh
run "jq '{refresh_token}' login.json | curl -s localhost:8000/refresh -H 'Content-Type: application/json' -d @- | tee second.json | jq ."
run "jq '{refresh_token}' login.json | curl -s localhost:8000/refresh -H 'Content-Type: application/json' -d @-"
run "jq '{refresh_token}' second.json | curl -s localhost:8000/refresh -H 'Content-Type: application/json' -d @-"
run 'curl -s localhost:8000/me -H "Authorization: Bearer $(jq -r .access_token second.json)"'

block tok-logout
run "curl -s localhost:8000/login $LOGIN_ANA > login.json"
run 'curl -si -X POST localhost:8000/logout -H "Authorization: Bearer $(jq -r .access_token login.json)"'
run 'curl -s localhost:8000/me -H "Authorization: Bearer $(jq -r .access_token login.json)"'
run "sqlite3 shelf.db 'SELECT jti, exp FROM revoked'"

block size
run "awk '\$6 == \"sid\" {printf \"%s\", \$7}' kept.txt | wc -c"
run 'jq -j .access_token login.json | wc -c'

