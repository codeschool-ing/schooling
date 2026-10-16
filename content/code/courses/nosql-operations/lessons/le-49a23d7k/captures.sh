#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of nosql-operations, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# What is staged: the network `nosql`, which lesson 1 creates, is created here
# without showing it, because every capture run starts from a clean daemon.
# Everything else was typed: the three nodes are started by the loop
# ring-and-partitions.md shows, the files orders.cql, days.cql and views.py are
# taken out of the lesson's own fences, so the file run is the file shown, and
# views.csv is written by views.py. The full `nodetool ring` printed in block
# ring-full is not quoted; the ring figure in ring-and-partitions.md is drawn
# from it. Tokens and addresses depend on the run: each node picks its tokens
# when it first joins.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"

quiet 'docker network create nosql'

block start
run "$(from ring-and-partitions.md 'for n in 1 2 3; do')"
quiet 'ready_cassandra c1 3'

block orders
from ring-and-partitions.md 'CREATE KEYSPACE shop' > orders.cql
run 'docker exec -i c1 cqlsh < orders.cql'

block status
run 'docker exec c1 nodetool status shop'
run "docker inspect -f '{{.Name}} {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' c1 c2 c3"
run 'docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}" c1 c2 c3'

block tokens
session 'docker exec -it c1 cqlsh' <<'S'
SELECT DISTINCT customer, token(customer) FROM shop.orders_by_customer;
exit
S
run 'for c in ana bruno carla diego elisa; do echo "$c $(docker exec c1 nodetool getendpoints shop orders_by_customer $c@example.com)"; done'

block ring
run 'docker exec c1 nodetool ring shop | head -12'
run 'docker exec c1 nodetool ring shop | grep -c Normal'

block ring-full
run 'docker exec c1 nodetool ring shop'

block clustering
session 'docker exec -it c1 cqlsh' <<'S'
SELECT order_id, ordered_at, total FROM shop.orders_by_customer WHERE customer = 'ana@example.com';
SELECT order_id, ordered_at, total FROM shop.orders_by_customer WHERE customer = 'ana@example.com' AND ordered_at >= '2026-03-01' AND ordered_at < '2026-04-01';
SELECT order_id, ordered_at, total FROM shop.orders_by_customer WHERE customer = 'ana@example.com' LIMIT 1;
SELECT order_id, ordered_at, total FROM shop.orders_by_customer WHERE customer = 'ana@example.com' ORDER BY ordered_at ASC;
SELECT order_id, ordered_at, total FROM shop.orders_by_customer WHERE customer = 'ana@example.com' ORDER BY total DESC;
exit
S

block refusals
session 'docker exec -it c1 cqlsh' <<'S'
SELECT order_id, customer FROM shop.orders_by_customer WHERE ordered_at >= '2026-04-01';
SELECT order_id, customer FROM shop.orders_by_customer WHERE status = 'shipped';
SELECT order_id, customer FROM shop.orders_by_customer ORDER BY ordered_at;
SELECT order_id, customer FROM shop.orders_by_customer WHERE status = 'shipped' ALLOW FILTERING;
exit
S

block trace
run "docker exec c1 cqlsh -e \"TRACING ON; SELECT order_id FROM shop.orders_by_customer WHERE customer = 'ana@example.com';\" | grep -oE 'Executing single-partition query on [a-z_]+|Submitting range requests on [0-9]+ ranges|Sending [A-Z_]+ message to /[0-9.:]+' | sort | uniq -c"
run "docker exec c1 cqlsh -e \"TRACING ON; SELECT order_id FROM shop.orders_by_customer WHERE status = 'shipped' ALLOW FILTERING;\" | grep -oE 'Executing single-partition query on [a-z_]+|Submitting range requests on [0-9]+ ranges|Sending [A-Z_]+ message to /[0-9.:]+' | sort | uniq -c"

block sai
session 'docker exec -it c1 cqlsh' <<'S'
CREATE INDEX orders_status ON shop.orders_by_customer (status) USING 'sai';
#sleep 10
SELECT order_id, customer FROM shop.orders_by_customer WHERE status = 'shipped';
exit
S
run "docker exec c1 cqlsh -e \"TRACING ON; SELECT order_id FROM shop.orders_by_customer WHERE status = 'shipped';\" | grep -oE 'Executing single-partition query on [a-z_]+|Submitting range requests on [0-9]+ ranges|Sending [A-Z_]+ message to /[0-9.:]+' | sort | uniq -c"

block by-day
from query-first.md 'CREATE TABLE shop.orders_by_day (' > days.cql
run 'docker exec -i c1 cqlsh < days.cql'
session 'docker exec -it c1 cqlsh' <<'S'
SELECT ordered_at, order_id, customer, total FROM shop.orders_by_day WHERE day = '2026-03-02';
exit
S
run "docker exec c1 cqlsh -e \"TRACING ON; SELECT order_id FROM shop.orders_by_day WHERE day = '2026-03-02';\" | grep -oE 'Executing single-partition query on [a-z_]+|Submitting range requests on [0-9]+ ranges|Sending [A-Z_]+ message to /[0-9.:]+' | sort | uniq -c"

block views
from partition-size.md 'import csv, datetime' > views.py
run 'python3 views.py'
run 'wc -l views.csv'
run 'head -3 views.csv'
session 'docker exec -it c1 cqlsh' <<'S'
CREATE TABLE shop.views_by_customer (customer text, month text, viewed_at timestamp, page text, PRIMARY KEY (customer, viewed_at));
CREATE TABLE shop.views_by_customer_month (customer text, month text, viewed_at timestamp, page text, PRIMARY KEY ((customer, month), viewed_at));
exit
S
run 'docker exec -i c1 cqlsh -e "COPY shop.views_by_customer (customer, month, viewed_at, page) FROM STDIN" < views.csv | tail -1'
run 'docker exec -i c1 cqlsh -e "COPY shop.views_by_customer_month (customer, month, viewed_at, page) FROM STDIN" < views.csv | tail -1'

block sizes
run 'for n in c1 c2 c3; do docker exec $n nodetool flush shop; done'
run 'docker exec c1 nodetool getendpoints shop views_by_customer ana@example.com'
run 'for m in 2026-01 2026-02 2026-03; do docker exec c1 nodetool getendpoints shop views_by_customer_month ana@example.com:$m; done'
run 'for n in c1 c2 c3; do echo "== $n"; docker exec $n nodetool tablestats shop.views_by_customer shop.views_by_customer_month | grep -E "Table:|Number of partitions|partition maximum bytes"; done'
