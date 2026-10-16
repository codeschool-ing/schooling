#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of apis, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine itself, at the end of lesson 1,
# with every package of lesson 1's "The packages" installed; `db.py` and
# `rest.py` from lesson 1's "The shelf" and `keys.py` from this lesson's
# "keys.py", all copied out of those sections by `shown` rather than pasted
# into nano. The password for `adduser` is piped in, because a recording has
# no keyboard; the lesson says so. The server runs in the background, where
# the lesson has the student run it in a second terminal, and `log` prints what
# that terminal showed. It is stopped and started again between some blocks so
# that each `log` holds only the lines of its own section; nothing is lost,
# because every row lives in shelf.db. An hour of waiting for a token to expire
# is replaced by an UPDATE that moves its expiry into the past, and the lesson
# says so.
#
# What differs on every run: dates, the Date header, the server's log times,
# every token, key, salt and hash, and every timing.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)

machine l07

shown "$HERE_DIR/../le-f6652c1w/the-shelf.md" "$HERE_DIR/keys-py.md"
at '~/shelf'

LOGIN="curl -s localhost:8000/v1/login -H 'Content-Type: application/json' -d '{\"username\": \"ana\", \"password\": \"river-lamp-42\"}'"
BEARER='-H "Authorization: Bearer $(jq -r .token login.json)"'

block setup
run 'ls'
run "printf 'river-lamp-42\n' | python3 keys.py adduser ana"
run "sqlite3 shelf.db 'SELECT * FROM users'"
serve 'python3 keys.py'

block challenge
run 'curl -si localhost:8000/v1/books'
run 'curl -si -u ana:river-lamp-42 localhost:8000/v1/whoami'

block basic
run 'curl -s -u ana:river-lamp-42 localhost:8000/v1/books'
run "curl -sv -u ana:river-lamp-42 localhost:8000/v1/books/1 2>&1 | grep -i '^> authorization'"
run 'echo YW5hOnJpdmVyLWxhbXAtNDI= | base64 -d; echo'

block tokens
run "$LOGIN | tee login.json"
run "curl -s $BEARER localhost:8000/v1/whoami"
run "sqlite3 shelf.db 'SELECT * FROM tokens'"
run 'jq -j .token login.json | sha256sum'
run "sqlite3 shelf.db \"SELECT datetime(expires, 'unixepoch', 'localtime') FROM tokens\""

block revoke
run "curl -si -X POST $BEARER localhost:8000/v1/logout"
run "curl -si $BEARER localhost:8000/v1/whoami"
run "sqlite3 shelf.db 'SELECT count(*) FROM tokens'"

block expire
run "$LOGIN -o login.json"
run "sqlite3 shelf.db \"UPDATE tokens SET expires = strftime('%s', 'now') - 1\""
run "curl -s -w '%{http_code}\n' $BEARER localhost:8000/v1/whoami"
run "sqlite3 shelf.db 'SELECT count(*) FROM tokens'"

block keys
run "curl -s -u ana:river-lamp-42 localhost:8000/v1/keys -H 'Content-Type: application/json' -d '{\"name\": \"Livraria Parceira\"}' | tee partner.json"
run 'curl -s -H "X-API-Key: $(jq -r .key partner.json)" localhost:8000/v1/whoami'
run 'curl -s -H "X-API-Key: $(jq -r .key partner.json)" localhost:8000/v1/books/6'
run "sqlite3 shelf.db 'SELECT * FROM api_keys'"
run 'curl -si -H "X-API-Key: $(jq -r .key partner.json)" localhost:8000/v1/keys'

block rotate
run "curl -s -u ana:river-lamp-42 localhost:8000/v1/keys -H 'Content-Type: application/json' -d '{\"name\": \"Livraria Parceira, rotated\"}' -o partner-new.json"
run "curl -s -u ana:river-lamp-42 localhost:8000/v1/keys | jq -c '.[]'"
run 'for f in partner.json partner-new.json; do curl -s -H "X-API-Key: $(jq -r .key $f)" localhost:8000/v1/whoami; done'
run 'curl -si -u ana:river-lamp-42 -X DELETE localhost:8000/v1/keys/$(jq -r .prefix partner.json)'
run "curl -s -w '%{http_code}\n' -H \"X-API-Key: \$(jq -r .key partner.json)\" localhost:8000/v1/whoami"
run "curl -s -u ana:river-lamp-42 localhost:8000/v1/keys | jq -c '.[]'"

block url
stop
serve 'python3 keys.py' url
run "$LOGIN -o login.json"
run "curl -s $BEARER localhost:8000/v1/books/1"
run 'curl -s "localhost:8000/v1/books/1?access_token=$(jq -r .token login.json)"'

block url-log
log url

block compare
run "python3 -m timeit -s 'a = \"x\" * 100_000; b = \"y\" + \"x\" * 99_999' 'a == b'"
run "python3 -m timeit -s 'a = \"x\" * 100_000; b = \"x\" * 99_999 + \"y\"' 'a == b'"
run "python3 -m timeit -s 'import hmac; a = \"x\" * 100_000; b = \"y\" + \"x\" * 99_999' 'hmac.compare_digest(a, b)'"
run "python3 -m timeit -s 'import hmac; a = \"x\" * 100_000; b = \"x\" * 99_999 + \"y\"' 'hmac.compare_digest(a, b)'"

block same
stop url
serve 'python3 keys.py' same
run "curl -s -u ana:wrong-password -w '%{http_code} %{time_total}s\n' localhost:8000/v1/books"
run "curl -s -u nobody:wrong-password -w '%{http_code} %{time_total}s\n' localhost:8000/v1/books"
run "curl -s -u ana:river-lamp-42 -o /dev/null -w '%{http_code} %{time_total}s\n' localhost:8000/v1/books"
run "curl -s localhost:8000/v1/login -H 'Content-Type: application/json' -d '{\"username\": \"nobody\", \"password\": \"river-lamp-42\"}'"
run "curl -s -H 'Authorization: Bearer not-a-token' localhost:8000/v1/whoami"

block same-log
log same

block cleanup
run "curl -s -X POST $BEARER localhost:8000/v1/logout"
run 'curl -s -u ana:river-lamp-42 -X DELETE localhost:8000/v1/keys/$(jq -r .prefix partner-new.json)'
run 'rm login.json partner.json partner-new.json'
run 'ls'
stop same
