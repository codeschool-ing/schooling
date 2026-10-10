#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of apis, gRPC and Protocol Buffers,
# as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine itself, built by `lab.sh up`
# with every package of lesson 1's section "The packages" already installed;
# `db.py` from lesson 1's section "The shelf", and this lesson's four files
# (`stock.proto`, `stock_server.py`, `stock_client.py`, `next/stock.proto`),
# copied out of the sections that print them by `shown` rather than pasted into
# nano. The gRPC server runs in the background, where the lesson has the
# student run it in a second terminal, and `log stock` prints what that
# terminal showed; it is started twice, once for the calls and once again
# after the section on failures stops it. The stream in "Four kinds of call"
# depends on timing: the two reservations made in the background land about a
# second apart, and a slower machine can print them in a different line of the
# watch, never a different count. The DeprecationWarning printed by
# grpc_tools is Ubuntu's package, and is what a student sees too.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)

machine l04

shown "$HERE_DIR/../le-f6652c1w/the-shelf.md" "$HERE_DIR/protocol-buffers.md" \
  "$HERE_DIR/server-and-client.md" "$HERE_DIR/evolving.md"
at '~/shelf'

block gen
run 'python3 -m grpc_tools.protoc -I . --python_out=. --grpc_python_out=. stock.proto'
run 'ls stock*'
run 'wc -l stock_pb2.py stock_pb2_grpc.py'
run "grep -n '^class\|^def ' stock_pb2_grpc.py"

block wire
run "echo 'isbn: \"9786500000016\" title: \"Dom Casmurro\" copies: 12 availability: IN_STOCK' > dom.txt"
run 'protoc --encode=shelf.stock.v1.StockLevel stock.proto < dom.txt > dom.bin'
run 'od -An -tx1 dom.bin'
run "echo 'copies: 300' | protoc --encode=shelf.stock.v1.StockLevel stock.proto | od -An -tx1"
run 'protoc --decode=shelf.stock.v1.StockLevel stock.proto < dom.bin'
run 'protoc --decode_raw < dom.bin'
run 'wc -c < dom.bin'
run "echo '{\"isbn\": \"9786500000016\", \"title\": \"Dom Casmurro\", \"copies\": 12, \"availability\": \"IN_STOCK\"}' | jq -cj . | wc -c"

block run
PORT=50051 serve 'python3 stock_server.py' stock
run 'python3 stock_client.py get 9786500000016'
run 'python3 stock_client.py reserve 9786500000016 2'

block runlog
log stock

block kinds
run 'python3 stock_client.py get 9786500000061'
run '(sleep 1; python3 stock_client.py reserve 9786500000061 1 >/dev/null; sleep 1; python3 stock_client.py reserve 9786500000061 1 >/dev/null) & python3 stock_client.py watch 9786500000061 4'
run 'python3 stock_client.py restock 9786500000061 5 9786500000030 2 9786500000061 1'

block status
run 'python3 stock_client.py get 9786500000099'
run 'python3 stock_client.py reserve 9786500000016 0'
run 'python3 stock_client.py reserve 9786500000030 5'
run 'python3 stock_client.py restock 9786500000016 5 9786500000099 1'
run 'python3 stock_client.py get 9786500000016'

block statuslog
log stock

block down
stop stock
run 'python3 stock_client.py get 9786500000016; echo "exit $?"'

block h2
PORT=50051 serve 'python3 stock_server.py' stock
run 'curl -sS http://127.0.0.1:50051/shelf.stock.v1.Stock/GetStock'
run "echo 'isbn: \"9786500000016\"' | protoc --encode=shelf.stock.v1.BookRef stock.proto > ask.bin"
run 'od -An -tx1 ask.bin'
run "{ printf '\\x00\\x00\\x00\\x00\\x0f'; cat ask.bin; } > ask.grpc"
run "curl -sS --http2-prior-knowledge -D - -o reply.grpc -H 'content-type: application/grpc' -H 'te: trailers' --data-binary @ask.grpc http://127.0.0.1:50051/shelf.stock.v1.Stock/GetStock"
run 'od -An -tx1 reply.grpc'
run 'tail -c +6 reply.grpc | protoc --decode=shelf.stock.v1.StockLevel stock.proto'
run "curl -sS --http2-prior-knowledge -D - -o /dev/null -H 'content-type: application/grpc' -H 'te: trailers' --data-binary @ask.grpc http://127.0.0.1:50051/shelf.stock.v1.Stock/GetPrice"

block evolve
run "echo 'isbn: \"9786500000016\" copies: 12 availability: IN_STOCK location: \"A3\"' | protoc -I next --encode=shelf.stock.v1.StockLevel next/stock.proto > new.bin"
run 'protoc --decode=shelf.stock.v1.StockLevel stock.proto < new.bin'
run 'protoc --decode_raw < new.bin'
run "python3 -c 'import sys, stock_pb2; m = stock_pb2.StockLevel.FromString(sys.stdin.buffer.read()); m.copies -= 1; sys.stdout.buffer.write(m.SerializeToString())' < new.bin | protoc --decode_raw"
run "sed 's/location = 5/location = 2/' next/stock.proto > reuse.proto"
run 'protoc reuse.proto -o /dev/null'
