#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of apis, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine itself, built by `lab.sh up`
# with every package of lesson 1's "The packages" already installed; `db.py`
# and `rest.py` from lesson 1's "The shelf", and `graph.py` from this lesson's
# "graph.py", copied out of those sections by `shown` rather than pasted into
# nano. The servers run in the background, one at a time, where the lesson has
# the student run them in a second terminal, and `log` prints what that
# terminal showed. The log's times and the Date header differ on every run;
# nothing else does.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)

# One GraphQL request: the JSON body, then anything that follows it on the line.
gql() { run "curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '$1'${2:+ $2}"; }

machine l03

shown "$HERE_DIR/../le-f6652c1w/the-shelf.md" "$HERE_DIR/graph-py.md"
at '~/shelf'

block rest-over
serve 'python3 rest.py' rest
run 'curl -s localhost:8000/v1/books/2'
run 'curl -s localhost:8000/v1/books | wc -c'

block rest-page
run "curl -s localhost:8000/v1/books/2 | jq -c '{title, author_id}'"
run "curl -s localhost:8000/v1/authors/1 | jq -c '{name}'"
run "curl -s localhost:8000/v1/authors/1/books | jq -c '[.[].title]'"

block rest-list
run 'for a in $(curl -s localhost:8000/v1/books | jq ".[].author_id"); do curl -s localhost:8000/v1/authors/$a | jq -r .name; done'

block rest-log
log rest
stop rest

block graph-run
serve 'python3 graph.py' graph
gql '{"query": "{ book(id: 2) { title author { name books { title } } } }"}' '| jq .'

block graph-bytes
gql '{"query": "{ books { title } }"}' '| wc -c'

block q-fields
gql '{"query": "{ books(authorId: 2) { title year } }"}' '| jq -c .'
gql '{"query": "{ books { titel } }"}' "-w '%{http_code}\n'"
gql '{"query": "{ book(id: 1) { author } }"}' "-w '%{http_code}\n'"

block q-alias
gql '{"query": "{ first: book(id: 1) { title } fifth: book(id: 5) { title } }"}' '| jq -c .'

block q-fragment
gql '{"query": "{ book(id: 6) { ...card } books(authorId: 3) { ...card } } fragment card on Book { title year priceCents }"}' '| jq -c .data'

block q-vars
gql '{"query": "query Page($id: ID!) { book(id: $id) { title author { name } } }", "variables": {"id": "4"}}' '| jq -c .'

block n1-off
gql '{"query": "{ books { title author { name } } }"}' '| jq -c .extensions'

block fan-off
gql '{"query": "{ books { author { books { author { name } } } } }"}' '| jq -c .extensions'

block graph-log
log graph
stop graph

block n1-on
serve 'python3 graph.py --batch' batch
gql '{"query": "{ books { title author { name } } }"}' '| jq -c .extensions'
gql '{"query": "{ books { author { books { author { name } } } } }"}' '| jq -c .extensions'

block mutation
run "curl -si localhost:8000/graphql -H 'Content-Type: application/json' -d '{\"query\": \"mutation { a: setStock(bookId: 1, stock: 10) { title stock } b: setStock(bookId: 2, stock: -1) { title stock } }\"}'"
gql '{"query": "{ a: book(id: 1) { stock } b: book(id: 2) { stock } }"}' '| jq -c .data'

block introspection
gql '{"query": "{ __schema { queryType { name } mutationType { name } types { name } } }"}' "| jq -c '.data.__schema | {queryType, mutationType, types: [.types[].name]}'"
gql '{"query": "{ __type(name: \"Book\") { fields { name type { kind ofType { name } } } } }"}' "| jq -c '.data.__type.fields[]'"

block depth
gql '{"query": "{ books { author { books { author { books { title } } } } } }"}' "-w '%{http_code}\n'"
run "python3 -c 'import graph, graphql; print(graph.deepest(graphql.parse(graphql.get_introspection_query())))'"

block get
run "curl -si 'localhost:8000/graphql?query=%7Bbooks%7Btitle%7D%7D'"

block batch-log
log batch
stop batch
