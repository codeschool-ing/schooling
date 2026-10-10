#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of apis, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine itself, built by `lab.sh up`
# with every package of lesson 1's section "The packages" already installed;
# `db.py` and `rest.py`, copied out of lesson 1's section "The shelf" by
# `shown`, and `catalogue.py`, copied out of this lesson's section "The
# catalogue" the same way. `book.schema.json` is JSON, which has no comment to
# carry its path, so `shown` cannot find it: it is copied here out of the one
# ```json fence of the section "Validation" that has a "$schema", which is the
# file that section prints. The servers run in the background, where the lesson
# has the student run them in a second terminal, and `log` prints what that
# terminal showed. rest.py runs first, for one request, and is stopped before
# catalogue.py starts, as the lesson tells the student to do.
#
# What differs per run: the Date header, the server's log times, the output of
# `date`, the uuid from /proc and the `created_at` of the stored key. The
# idempotency key the lesson sends is a fixed string, so that the three
# requests that use it can be typed.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)

machine l02
shown "$HERE_DIR/../le-f6652c1w/the-shelf.md" "$HERE_DIR/the-catalogue.md"
python3 - "$HERE_DIR/validation.md" /var/lib/machines/apis-runs/l02/root/home/ana/shelf/book.schema.json <<'PY'
import re, sys
text = open(sys.argv[1], encoding='utf-8').read()
found = [b for b in re.findall(r'^```json\n(.*?)^```$', text, re.S | re.M) if '"$schema"' in b]
assert len(found) == 1, f'{len(found)} schema fences in {sys.argv[1]}'
open(sys.argv[2], 'w', encoding='utf-8').write(found[0])
print('shelf/book.schema.json', file=sys.stderr)
PY
asroot 'chown -R ana:ana /home/ana'

BOOK='{"isbn": "9786500000078", "title": "Quincas Borba", "author_id": 1, "year": 1891, "price": {"amount_cents": 3990, "currency": "BRL"}}'
ALIEN='{"isbn": "9786500000085", "title": "O Alienista", "author_id": 1, "year": 1882, "price": {"amount_cents": 2990, "currency": "BRL"}}'
ALIEN2='{"isbn": "9786500000085", "title": "O Alienista", "author_id": 1, "year": 1882, "price": {"amount_cents": 3290, "currency": "BRL"}}'
JSONH="-H 'Content-Type: application/json'"

block types
run "echo '{\"id\": 9007199254740993}' | jq .id"
run "echo '{\"id\": 9007199254740993}' | jq '.id + 0'"
run "python3 -c 'print(2**53, float(9007199254740993))'"
run "echo '[3990, 3990.0]' | jq -c ."
run "echo '[3990, 3990.0]' | jq -c 'map(. + 0)'"
run "python3 -c 'import json; print(json.loads(\"[3990, 3990.0]\"))'"
run "jq -n '39.90 * 3'"
run "python3 -c 'print(39.90 * 3, 3990 * 3)'"
run "echo '{\"published\": \"1899-01-01\"}' | jq '.published | type'"

block shape
run 'date -Iseconds; TZ=UTC date -Iseconds'
run "python3 -c 'from datetime import datetime; print(datetime.now().isoformat(timespec=\"seconds\"))'"
run "echo '{\"subtitle\": null}' | jq -c '[.subtitle, has(\"subtitle\")]'"
run "echo '{}' | jq -c '[.subtitle, has(\"subtitle\")]'"
run "echo '{\"in_stock\": \"false\"}' | jq 'if .in_stock then \"in stock\" else \"sold out\" end'"

at '~/shelf'
block schema
run 'ls'
run "echo '{\"isbn\": \"978650000007\", \"title\": \"\", \"year\": \"1891\", \"price\": {\"amount_cents\": 39.90}, \"colour\": \"red\"}' > bad.json"
run 'jsonschema -i bad.json book.schema.json; echo "exit $?"'
run "echo '$BOOK' > good.json"
run 'jsonschema -i good.json book.schema.json; echo "exit $?"'
run "echo '{\"isbn\": \"9786500000078\", \"title\": \"Quincas Borba\", \"author_id\": 1, \"year\": 1891, \"price\": {\"amount_cents\": 3990.0, \"currency\": \"BRL\"}}' > float.json"
run 'jsonschema -i float.json book.schema.json; echo "exit $?"'

block rest
serve 'python3 rest.py' rest
run 'curl -s localhost:8000/v1/books/1'
run "curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books $JSONH -d '{\"title\": \"\", \"year\": \"1891\", \"price_cents\": 39.90}'"
stop rest

block catalogue
serve 'python3 catalogue.py' cat
run 'curl -s localhost:8000/v1/books/1'
run 'curl -s localhost:8000/v1/books/1 | jq .'

block errors
run 'curl -si localhost:8000/v1/books/99'
run "curl -s -X POST localhost:8000/v1/books $JSONH -d '{\"title\": \"\", \"year\": \"1891\", \"price_cents\": 39.90}' | jq ."
run "curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books $JSONH -d '{\"isbn\": \"9786500000016\", \"title\": \"Dom Casmurro\", \"author_id\": 1, \"year\": 1899, \"price\": {\"amount_cents\": 3990, \"currency\": \"BRL\"}}'"
run "curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books $JSONH -d '{\"title\": '"
run 'curl -si -X DELETE localhost:8000/v1/books/1'

block pages
run "curl -si 'localhost:8000/v1/books?limit=2'"
run 'echo WyJpZCIsIDIsIDJd | base64 -d; echo'
run "curl -s 'localhost:8000/v1/books?limit=2&after=WyJpZCIsIDIsIDJd' | jq -c '.items[].id, .next'"
run "curl -s 'localhost:8000/v1/books?limit=2&after=WyJpZCIsIDQsIDRd' | jq -c '.items[].id, .next'"
run "curl -s 'localhost:8000/v1/books?limit=500' | jq -r .detail"

block drift
run "sqlite3 shelf.db 'SELECT id, title FROM books ORDER BY id DESC LIMIT 2 OFFSET 0'"
run "curl -s 'localhost:8000/v1/books?sort=-id&limit=2' | jq -c '.items[].id, .next'"
run "curl -s -X POST localhost:8000/v1/books $JSONH -d '$BOOK' | jq -c '{id, title}'"
run "sqlite3 shelf.db 'SELECT id, title FROM books ORDER BY id DESC LIMIT 2 OFFSET 2'"
run "curl -s 'localhost:8000/v1/books?sort=-id&limit=2&after=WyItaWQiLCA1LCA1XQ' | jq -c '.items[].id, .next'"

block filters
run "curl -s 'localhost:8000/v1/books?author_id=1&sort=-year' | jq -c '.items[] | {id, title, year}'"
run "curl -s 'localhost:8000/v1/books?in_stock=false' | jq -c '.items[] | {id, title, stock}'"
run "curl -s 'localhost:8000/v1/books?sort=-price&limit=3' | jq -c '.items[] | {title, price: .price.amount_cents}'"
run "curl -s 'localhost:8000/v1/books?sort=isbn' | jq -r .detail"
run "curl -s 'localhost:8000/v1/books?colour=red' | jq -r .detail"
run "curl -s 'localhost:8000/v1/books?in_stock=yes' | jq -r .detail"
run "curl -s 'localhost:8000/v1/books?sort=title&after=WyJpZCIsIDIsIDJd' | jq -r .detail"

block keys
run 'cat /proc/sys/kernel/random/uuid'
run "curl -si -X POST localhost:8000/v1/books $JSONH -H 'Idempotency-Key: 3f1c9a2e-alienista' -d '$ALIEN'"
run "curl -si -X POST localhost:8000/v1/books $JSONH -H 'Idempotency-Key: 3f1c9a2e-alienista' -d '$ALIEN'"
run "curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books $JSONH -H 'Idempotency-Key: 3f1c9a2e-alienista' -d '$ALIEN2'"
run "curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books $JSONH -d '$ALIEN'"
run "sqlite3 shelf.db 'SELECT key, location, created_at FROM idempotency_keys'"

block compat
run 'curl -s localhost:8000/v1/books/1 > one.json'
run "echo '{\"type\": \"object\", \"required\": [\"id\", \"title\"], \"additionalProperties\": false, \"properties\": {\"id\": {}, \"title\": {}}}' > strict.json"
run 'jsonschema -i one.json strict.json; echo "exit $?"'
run "echo '{\"type\": \"object\", \"required\": [\"id\", \"title\"], \"properties\": {\"id\": {}, \"title\": {}}}' > tolerant.json"
run 'jsonschema -i one.json tolerant.json; echo "exit $?"'

block log
log cat
