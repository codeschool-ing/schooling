#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of apis, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine itself, built by `lab.sh up`
# with every package of the section "The packages" already installed; the two
# files of the section "The shelf", copied out of that section by `shown`
# rather than pasted into nano. The server runs in the background, where the
# lesson has the student run it in a second terminal, and `log` prints what
# that terminal showed. Dates, the Date header and the server's log times
# differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)

machine l1

block packages
run 'grep PRETTY /etc/os-release; python3 --version'
run "python3 -c 'import yaml, jsonschema, graphql, grpc, zeep, bcrypt, argon2, jwt; print(\"all eight import\")'"
run 'curl --version | head -1; sqlite3 --version | cut -d" " -f1; jq --version'

shown "$HERE_DIR/the-shelf.md"
at '~/shelf'
block shelf
run 'ls'
serve 'python3 rest.py'
run 'curl -s localhost:8000/v1/books/1'
run 'ls'
run "sqlite3 shelf.db 'SELECT id, title, price_cents, stock FROM books'"

block resources
run "curl -s localhost:8000/v1/books | jq -c '.[] | {id, title, author_id}'"
run 'curl -si localhost:8000/v1/books/3'
run 'curl -si localhost:8000/v1/books/99'
run 'curl -s localhost:8000/v1/authors/2'
run "curl -s localhost:8000/v1/authors/2/books | jq -c '.[] | {id, title}'"
run "curl -s 'localhost:8000/v1/books?author_id=3' | jq -c '.[] | {id, title}'"
run "curl -s -o /dev/null -w '%{http_code}\n' localhost:8000/v1/getBooks"

block verbs-post
run "curl -si -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '{\"isbn\": \"9786500000078\", \"title\": \"Quincas Borba\", \"author_id\": 1, \"year\": 1891, \"price_cents\": 3990}'"
run "curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '{\"isbn\": \"9786500000078\", \"title\": \"Quincas Borba\", \"author_id\": 1, \"year\": 1891, \"price_cents\": 3990}'"
block verbs-put
run "curl -s -w '%{http_code}\n' -X PUT localhost:8000/v1/books/7 -H 'Content-Type: application/json' -d '{\"isbn\": \"9786500000078\", \"title\": \"Quincas Borba\", \"author_id\": 1, \"year\": 1891, \"price_cents\": 4190, \"stock\": 2}'"
run "curl -s -w '%{http_code}\n' -X PUT localhost:8000/v1/books/7 -H 'Content-Type: application/json' -d '{\"isbn\": \"9786500000078\", \"title\": \"Quincas Borba\", \"author_id\": 1, \"year\": 1891, \"price_cents\": 4190, \"stock\": 2}'"
run "curl -s -w '%{http_code}\n' -X PUT localhost:8000/v1/books/7 -H 'Content-Type: application/json' -d '{\"stock\": 5}'"
run "curl -s -w '%{http_code}\n' -X PATCH localhost:8000/v1/books/7 -H 'Content-Type: application/json' -d '{\"stock\": 5}'"
block verbs-delete
run 'curl -si -X DELETE localhost:8000/v1/books/7'
run "curl -s -w '%{http_code}\n' -X DELETE localhost:8000/v1/books/7"
run 'curl -si -X DELETE localhost:8000/v1/books'

block status
run "curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books -d 'title=Quincas Borba'"
run "curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '{\"title\": '"
run "curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '[\"Quincas Borba\"]'"
run "curl -s -w '%{http_code}\n' -X PATCH localhost:8000/v1/books/1 -H 'Content-Type: application/json' -d '{\"colour\": \"red\"}'"
run "curl -s -w '%{http_code}\n' -X PATCH localhost:8000/v1/books/1 -H 'Content-Type: application/json' -d '{\"price_cents\": \"39.90\"}'"
run "curl -s -w '%{http_code}\n' -X PATCH localhost:8000/v1/books/1 -H 'Content-Type: application/json' -d '{\"stock\": -1}'"
run "curl -s -w '%{http_code}\n' -X PATCH localhost:8000/v1/books/1 -H 'Content-Type: application/json' -d '{\"author_id\": 99}'"
run 'curl -si -X OPTIONS localhost:8000/v1/books'

block versions
run 'curl -s localhost:8000/v1/books/1'
run 'curl -s localhost:8000/v2/books/1'
run "curl -si -X PATCH localhost:8000/v2/books/1 -H 'Content-Type: application/json' -d '{\"stock\": 11}'"

block fails
run 'python3 rest.py'
stop
run 'curl -s localhost:8000/v1/books/1; echo "exit $?"'
run 'curl -sS localhost:8000/v1/books/1'

block log
log
