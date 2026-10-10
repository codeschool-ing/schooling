#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of apis, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine itself, built by `lab.sh up`
# with every package of lesson 1's "The packages" already installed; lesson
# 1's db.py and rest.py, and this lesson's idp.py, pkce.py, check_token.py and
# saml/assertion.xml, copied out of the lessons by `shown` rather than pasted
# into nano. The server runs in the background, where the lesson has the
# student run it in a second terminal, and `log` prints what that terminal
# showed.
#
# ONE SHELL, KEPT BY A FILE. The lesson's commands are typed into one terminal,
# so a variable set by one command (VERIFIER, CODE, AT…) is there for the next.
# The lab runs every command in a fresh shell, so `run` below is capture.sh's
# with one addition: before each command it reads the variables the previous
# commands left, and after it writes them back to /tmp/shell.vars. Nothing in
# the transcript changes; only the persistence a real terminal has is restored.
#
# Differs on every run: the RSA keys (so the key id, the JWKS modulus and the
# signatures), every code, verifier, challenge, state, nonce and token, the
# iat and exp times, the Date header, and the SAML signature value.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)

VARS='STATE NONCE VERIFIER CHALLENGE AUTH CODE AT RT IDT AT2 MT RT2'
run() {
  printf 'ana@api:%s$ %s\n' "$HERE" "$1"
  lab as "$MACHINE" "cd $(dir) && export PAGER=cat COLUMNS=100 && { [ -f /tmp/shell.vars ] && . /tmp/shell.vars; $1 ; }; for v in $VARS; do [ -n \"\${!v-}\" ] && declare -p \$v; done > /tmp/shell.vars.new; mv /tmp/shell.vars.new /tmp/shell.vars" 2>&1 || true
}

TOKEN='curl -s localhost:8000/token -u shelf-web:lab-only-secret'
CB='http://127.0.0.1:9000/callback'

machine l09
shown "$HERE_DIR/../le-f6652c1w/the-shelf.md" "$HERE_DIR"/*.md
at '~/shelf'

block pkce
run 'python3 pkce.py'
run 'read VERIFIER CHALLENGE < <(python3 pkce.py)'
run 'echo $VERIFIER; echo $CHALLENGE'
run 'printf %s "$VERIFIER" | openssl dgst -sha256 -binary | basenc --base64url | tr -d ='

block idp
serve 'python3 idp.py'
run 'ls -l idp-key.pem'
block idp-log
log

block byhand
run 'STATE=$(openssl rand -hex 8); NONCE=$(openssl rand -hex 8)'
run "AUTH='localhost:8000/authorize?response_type=code&client_id=shelf-web&redirect_uri=$CB&code_challenge_method=S256'"
run 'curl -si "$AUTH&scope=openid+profile+books:read&state=$STATE&nonce=$NONCE&code_challenge=$CHALLENGE"'
run "CODE=\$(curl -s -o /dev/null -w '%{redirect_url}' \"\$AUTH&scope=openid+profile+books:read&state=\$STATE&nonce=\$NONCE&code_challenge=\$CHALLENGE\" | sed -E 's/.*code=([^&]+).*/\\1/'); echo \$CODE"
run "$TOKEN -d grant_type=authorization_code -d code=\$CODE -d redirect_uri=$CB -d code_verifier=\$VERIFIER | tee tokens.json | jq ."
run 'AT=$(jq -r .access_token tokens.json); RT=$(jq -r .refresh_token tokens.json); IDT=$(jq -r .id_token tokens.json)'
run "curl -s localhost:8000/books/stock -H \"Authorization: Bearer \$AT\" | jq -c '.[]'"
run 'curl -si localhost:8000/books/stock'
block byhand-refused
run "$TOKEN -d grant_type=authorization_code -d code=\$CODE -d redirect_uri=$CB -d code_verifier=\$VERIFIER"
run "CODE=\$(curl -s -o /dev/null -w '%{redirect_url}' \"\$AUTH&scope=openid+profile+books:read&state=\$STATE&nonce=\$NONCE&code_challenge=\$CHALLENGE\" | sed -E 's/.*code=([^&]+).*/\\1/')"
run "$TOKEN -d grant_type=authorization_code -d code=\$CODE -d redirect_uri=$CB -d code_verifier=not-the-verifier"
run 'curl -si "${AUTH/9000/9999}&scope=openid&code_challenge=$CHALLENGE"'

block scopes
run 'curl -s localhost:8000/userinfo -H "Authorization: Bearer $AT"'
run 'read VERIFIER CHALLENGE < <(python3 pkce.py)'
run "CODE=\$(curl -s -o /dev/null -w '%{redirect_url}' \"\$AUTH&scope=openid+email&code_challenge=\$CHALLENGE\" | sed -E 's/.*code=([^&]+).*/\\1/')"
run "AT2=\$($TOKEN -d grant_type=authorization_code -d code=\$CODE -d redirect_uri=$CB -d code_verifier=\$VERIFIER | jq -r .access_token)"
run 'curl -s localhost:8000/userinfo -H "Authorization: Bearer $AT2"'
run 'curl -si localhost:8000/books/stock -H "Authorization: Bearer $AT2"'
run 'curl -si "$AUTH&scope=openid+books:write&code_challenge=$CHALLENGE"'

block oidc
run "curl -s localhost:8000/.well-known/openid-configuration | jq ."
run "curl -s localhost:8000/jwks.json | jq ."
run 'python3 check_token.py "$IDT" shelf-web "$NONCE"'
run 'python3 check_token.py "$IDT" shelf-web 0123456789abcdef'
run 'python3 check_token.py "$AT" shelf-web'
run 'python3 check_token.py "$AT" shelf-api'
run 'curl -s localhost:8000/userinfo -H "Authorization: Bearer $IDT"'

block cc
run "$TOKEN -d grant_type=client_credentials -d scope=books:read | tee machine.json | jq 'del(.access_token)'"
run 'MT=$(jq -r .access_token machine.json)'
run "curl -s localhost:8000/books/stock -H \"Authorization: Bearer \$MT\" | jq -c '.[0]'"
run 'python3 check_token.py "$MT" shelf-api'
run 'curl -s localhost:8000/userinfo -H "Authorization: Bearer $MT"'
run "$TOKEN -d grant_type=client_credentials -d scope=openid"

block refresh
run 'echo $RT'
run "$TOKEN -d grant_type=refresh_token -d refresh_token=\$RT | tee tokens2.json | jq 'del(.access_token)'"
run 'RT2=$(jq -r .refresh_token tokens2.json)'
run "$TOKEN -d grant_type=refresh_token -d refresh_token=\$RT"
run "$TOKEN -d grant_type=refresh_token -d refresh_token=\$RT2"
run "curl -s -o /dev/null -w '%{http_code}\n' localhost:8000/books/stock -H \"Authorization: Bearer \$AT\""

block gone
run 'curl -si "${AUTH/response_type=code/response_type=token}&scope=openid&code_challenge=$CHALLENGE" | grep Location'
run "$TOKEN -d grant_type=password -d username=ana -d password=her-password"
run 'curl -si "$AUTH&scope=openid" | grep Location'

block saml
run 'openssl genpkey -quiet -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out saml/idp-key.pem'
run 'openssl req -x509 -new -key saml/idp-key.pem -subj /CN=idp.shelf.example -days 365 -out saml/idp-cert.pem'
run 'openssl x509 -in saml/idp-cert.pem -noout -subject -enddate'
run 'xmlsec1 --sign --privkey-pem saml/idp-key.pem --id-attr:ID urn:oasis:names:tc:SAML:2.0:assertion:Assertion --output saml/signed.xml saml/assertion.xml'
run "sed -n '/<ds:DigestValue>/p; /<ds:SignatureValue>/,/<\\/ds:SignatureValue>/p' saml/signed.xml"
run 'xmlsec1 --verify --pubkey-cert-pem saml/idp-cert.pem --id-attr:ID urn:oasis:names:tc:SAML:2.0:assertion:Assertion saml/signed.xml'
run "sed 's/>reader</>admin</' saml/signed.xml > saml/changed.xml"
run 'diff saml/signed.xml saml/changed.xml'
run 'xmlsec1 --verify --pubkey-cert-pem saml/idp-cert.pem --id-attr:ID urn:oasis:names:tc:SAML:2.0:assertion:Assertion saml/changed.xml'

block log
log
