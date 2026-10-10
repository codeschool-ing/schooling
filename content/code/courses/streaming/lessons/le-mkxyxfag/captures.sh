#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of streaming, as a script that
# produces them. Its output is not committed: run it and compare.
#
#   sudo bash ../../lab.sh files
#   sudo bash captures.sh > /tmp/le-mkxyxfag.out 2>&1
#
# STAGED, not typed, and said here: the lab starts from a fresh one-node
# cluster, and the SQLite files these programs write are deleted first, so
# every count starts from an empty database. The crashes are the programs'
# own os._exit, which ends a process with no cleanup, as kill -9 would.
# Nothing was NOT run.
. "$(dirname "$0")/../../lab/capture-lib.sh"

lab reset 1 >/dev/null
run 'rm -f demo.db prices.db stock.db stock2.db shop.db run1.txt run2.txt' >/dev/null
SUM='python -m sqlite3 stock.db "SELECT sum(qty) FROM stock"'

block setup
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3'
vm 'python tills.py --count 40 --rate 0'

block add
vm "python -m sqlite3 demo.db \"CREATE TABLE sold (book TEXT PRIMARY KEY, qty INTEGER NOT NULL)\""
vm "python -m sqlite3 demo.db \"INSERT INTO sold VALUES ('bk-04', 0)\""
vm "python -m sqlite3 demo.db \"UPDATE sold SET qty = qty + 2 WHERE book = 'bk-04'\""
vm "python -m sqlite3 demo.db \"UPDATE sold SET qty = qty + 2 WHERE book = 'bk-04'\""
vm "python -m sqlite3 demo.db \"SELECT * FROM sold\""
block upsert
vm "python -m sqlite3 demo.db \"CREATE TABLE sales (sale TEXT PRIMARY KEY, book TEXT, qty INTEGER)\""
vm "python -m sqlite3 demo.db \"INSERT INTO sales VALUES ('rec-000007', 'bk-04', 2) ON CONFLICT (sale) DO NOTHING\""
vm "python -m sqlite3 demo.db \"INSERT INTO sales VALUES ('rec-000007', 'bk-04', 2) ON CONFLICT (sale) DO NOTHING\""
vm "python -m sqlite3 demo.db \"SELECT book, sum(qty) FROM sales GROUP BY book\""

block naive
vm 'python stock_sink.py'
vm "$SUM"
vm 'python stock_sink.py --replay'
vm "$SUM"
block dedup
vm 'rm stock.db'
vm 'python stock_sink.py --dedup --replay'
vm "$SUM"
vm 'python stock_sink.py --dedup --replay'
vm "$SUM"
block crash
vm 'rm stock.db'
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --delete --group stock-sink'
vm 'python stock_sink.py --dedup --crash-after 15'
vm 'python stock_sink.py --dedup'
vm "$SUM"
block remember
vm 'python -m sqlite3 stock.db "SELECT count(*) FROM processed"'

block offsets
vm 'python offset_sink.py --crash-after 15'
vm 'python offset_sink.py'
vm 'python -m sqlite3 stock2.db "SELECT sum(qty) FROM stock"'
vm 'python -m sqlite3 stock2.db "SELECT * FROM offsets"'
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group offset-sink'

block versions
vm "python -m sqlite3 prices.db \"CREATE TABLE price (book TEXT PRIMARY KEY, cents INTEGER, version INTEGER)\""
for v in "3990, 1" "4490, 3" "4290, 2"; do
  vm "python -m sqlite3 prices.db \"INSERT INTO price VALUES ('bk-01', $v) ON CONFLICT (book) DO UPDATE SET cents = excluded.cents, version = excluded.version WHERE excluded.version > price.version\""
done
vm "python -m sqlite3 prices.db \"SELECT * FROM price\""

block outbox
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic stock-events --partitions 1'
vm 'python outbox.py restock bk-04 10'
vm 'python outbox.py restock bk-07 5'
vm 'python -m sqlite3 shop.db "SELECT id, sent FROM outbox"'
vm 'python outbox.py relay'
vm 'python outbox.py relay'
vm 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic stock-events --from-beginning --timeout-ms 5000 2>/dev/null'

block test-dedup
vm 'rm stock.db'
vm 'python stock_sink.py --dedup --replay'
vm 'python -m sqlite3 stock.db "SELECT * FROM stock ORDER BY book" > run1.txt'
vm 'python stock_sink.py --dedup --replay'
vm 'python -m sqlite3 stock.db "SELECT * FROM stock ORDER BY book" > run2.txt'
vm 'diff run1.txt run2.txt && echo identical'
block test-naive
vm 'rm stock.db'
vm 'python stock_sink.py --replay'
vm 'python -m sqlite3 stock.db "SELECT * FROM stock ORDER BY book" > run1.txt'
vm 'python stock_sink.py --replay'
vm 'python -m sqlite3 stock.db "SELECT * FROM stock ORDER BY book" > run2.txt'
vm 'diff run1.txt run2.txt && echo identical'
