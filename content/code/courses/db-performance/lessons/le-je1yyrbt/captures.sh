#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of db-performance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # the machine lesson 1's captures built
#   sudo bash captures.sh
#
# It starts from `market` as lesson 3 starts (lab.sh reset, which is what the
# student's ~/reset-market.sh does). lab.sh reset removes ~/workload, so the
# workload is written again from lesson 2's a-workload.md, as the student wrote
# it there; tag-search.sql is the file the pgbench runs use. pg_trgm and
# btree_gist come with the postgresql package (contrib), so CREATE EXTENSION
# needs nothing installed.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh
FENCE=../../lab/fence.py
lab() { bash "$LAB" "$@"; }
onw() { printf 'ana@vm:~/workload$ %s\n' "$*"; lab as "cd ~/workload && $*" 2>&1 || true; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/db-performance-capture.lock; flock 9

lab reset
python3 "$FENCE" ../le-9kwvr0x4/a-workload.md 'mkdir -p ~/workload' | lab as 'bash' >/dev/null

block order-by
session market <<'SQL'
EXPLAIN SELECT id, placed_at FROM orders WHERE placed_at >= '2025-12-24' ORDER BY placed_at LIMIT 5;
EXPLAIN SELECT id, placed_at FROM orders ORDER BY placed_at DESC LIMIT 5;
SQL

block like
session market <<'SQL'
EXPLAIN SELECT * FROM customers WHERE email LIKE 'user42@%';
SELECT datcollate FROM pg_database WHERE datname = current_database();
CREATE INDEX customers_email_pattern_idx ON customers (email text_pattern_ops);
EXPLAIN SELECT * FROM customers WHERE email LIKE 'user42@%';
EXPLAIN SELECT * FROM customers WHERE email LIKE '%42@example.com';
SQL

block hash
session market <<'SQL'
CREATE INDEX customers_email_hash_idx ON customers USING hash (email);
SELECT relname, pg_size_pretty(pg_relation_size(oid)) AS size FROM pg_class WHERE relname IN ('customers_email_key', 'customers_email_pattern_idx', 'customers_email_hash_idx');
EXPLAIN SELECT * FROM customers WHERE email = 'user42@example.com';
EXPLAIN SELECT * FROM customers WHERE email > 'user99990';
DROP INDEX customers_email_hash_idx;
DROP INDEX customers_email_pattern_idx;
SQL

block tag-before
onw 'pgbench -n -c 8 -j 4 -T 15 -f tag-search.sql market 2>&1 | grep -E "^(latency average|tps)"'
session market <<'SQL'
EXPLAIN ANALYZE SELECT id, title, price_cents FROM products WHERE tags @> ARRAY['kitchen'] ORDER BY price_cents LIMIT 20;
SQL

block tag-gin
session market <<'SQL'
CREATE INDEX products_tags_idx ON products USING gin (tags);
EXPLAIN ANALYZE SELECT id, title, price_cents FROM products WHERE tags @> ARRAY['kitchen'] ORDER BY price_cents LIMIT 20;
SQL
onw 'pgbench -n -c 8 -j 4 -T 15 -f tag-search.sql market 2>&1 | grep -E "^(latency average|tps)"'

block tag-btree
session market <<'SQL'
CREATE INDEX products_price_cents_idx ON products (price_cents);
EXPLAIN ANALYZE SELECT id, title, price_cents FROM products WHERE tags @> ARRAY['kitchen'] ORDER BY price_cents LIMIT 20;
SQL
onw 'pgbench -n -c 8 -j 4 -T 15 -f tag-search.sql market 2>&1 | grep -E "^(latency average|tps)"'

block tag-rare
session market <<'SQL'
EXPLAIN ANALYZE SELECT id, title, price_cents FROM products WHERE tags @> ARRAY['kitchn'] ORDER BY price_cents LIMIT 20;
SELECT relname, pg_size_pretty(pg_relation_size(oid)) AS size FROM pg_class WHERE relname IN ('products', 'products_tags_idx', 'products_price_cents_idx');
SQL

block jsonb
session market <<'SQL'
EXPLAIN ANALYZE SELECT count(*) FROM events WHERE payload @> '{"product": 4242}';
CREATE INDEX events_payload_idx ON events USING gin (payload);
CREATE INDEX events_payload_path_idx ON events USING gin (payload jsonb_path_ops);
SELECT relname, pg_size_pretty(pg_relation_size(oid)) AS size FROM pg_class WHERE relname IN ('events', 'events_payload_idx', 'events_payload_path_idx');
EXPLAIN ANALYZE SELECT count(*) FROM events WHERE payload @> '{"product": 4242}';
DROP INDEX events_payload_idx;
DROP INDEX events_payload_path_idx;
SQL

block trgm
session market <<'SQL'
CREATE EXTENSION pg_trgm;
EXPLAIN ANALYZE SELECT id, title FROM products WHERE title ILIKE '%chair 4242%';
CREATE INDEX products_title_trgm_idx ON products USING gist (title gist_trgm_ops);
EXPLAIN ANALYZE SELECT id, title FROM products WHERE title ILIKE '%chair 4242%';
SELECT id, title, round((title <-> 'wodden chiar 4242')::numeric, 3) AS distance FROM products ORDER BY title <-> 'wodden chiar 4242' LIMIT 5;
EXPLAIN SELECT id, title FROM products ORDER BY title <-> 'wodden chiar 4242' LIMIT 5;
SQL

block exclude
session market <<'SQL'
CREATE EXTENSION btree_gist;
CREATE TABLE seller_away (seller_id integer NOT NULL, during tstzrange NOT NULL, EXCLUDE USING gist (seller_id WITH =, during WITH &&));
INSERT INTO seller_away VALUES (42, '[2025-12-20, 2026-01-05)');
INSERT INTO seller_away VALUES (42, '[2026-01-02, 2026-01-10)');
INSERT INTO seller_away VALUES (43, '[2026-01-02, 2026-01-10)');
SQL

block brin
session market <<'SQL'
SELECT attname, correlation FROM pg_stats WHERE tablename = 'events' AND attname IN ('at', 'customer_id');
CREATE INDEX events_at_brin_idx ON events USING brin (at);
CREATE INDEX events_at_btree_idx ON events (at);
SELECT relname, pg_size_pretty(pg_relation_size(oid)) AS size FROM pg_class WHERE relname IN ('events', 'events_at_brin_idx', 'events_at_btree_idx');
DROP INDEX events_at_btree_idx;
EXPLAIN ANALYZE SELECT count(*) FROM events WHERE at >= '2025-12-24' AND at < '2025-12-25';
SQL

block brin-bad
session market <<'SQL'
CREATE INDEX events_customer_brin_idx ON events USING brin (customer_id);
EXPLAIN ANALYZE SELECT count(*) FROM events WHERE customer_id = 4242;
SQL
