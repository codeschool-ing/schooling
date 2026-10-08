#!/usr/bin/env bash
# The psql sessions quoted in lesson 8 of sql-databases, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up && sudo bash ../../lab.sh role   # once
#   sudo bash captures.sh
#
# Every block starts from the shop exactly as lesson 1 loads it — shop.sql is
# taken out of lesson 1's reading-a-schema.md — because the lesson says each
# example does, and a write in one would otherwise change the next.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, TZ=UTC.
set -uo pipefail
cd "$(dirname "$0")"
export TZ=UTC LC_ALL=C.UTF-8
LAB_SH=../../lab.sh
lab() { bash "$LAB_SH" "$@"; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
fresh() { lab exec 'dropdb --if-exists shop; createdb shop; psql -q shop -f shop.sql >/dev/null'; }
exec 9>/var/tmp/sql-capture.lock; flock 9

lab role >/dev/null 2>&1
python3 ../../lab/fence.py ../le-96rkt034/installing-postgresql.md 'cat > ~/.psqlrc' | lab exec bash
python3 ../../lab/fence.py ../le-96rkt034/reading-a-schema.md '-- shop.sql:' | lab exec 'cat > shop.sql'

each() { block "$1"; fresh; session shop; }

each insert <<'SQL'
INSERT INTO customers (name, email, city) VALUES ('Duarte Alves', 'duarte@example.com', 'Sao Paulo');
SQL
each insert-no-list <<'SQL'
INSERT INTO customers VALUES ('Xico', 'xico@example.com', 'Porto');
SQL
each insert-two <<'SQL'
INSERT INTO products (sku, name, price) VALUES ('HD-500', 'Headset', 259.00), ('WC-020', 'Webcam', 179.90);
SQL
each insert-defaults <<'SQL'
INSERT INTO orders (customer_id, total) VALUES (3, 39.90) RETURNING id, ordered_on, status;
SQL
each update <<'SQL'
UPDATE orders SET status = 'shipped' WHERE ordered_on < DATE '2026-03-05';
SQL
each update-returning <<'SQL'
UPDATE products SET price = price * 1.10 WHERE sku = 'KB-101' RETURNING sku, price;
SQL
each delete-returning <<'SQL'
DELETE FROM order_lines WHERE quantity > 1 RETURNING order_id, product_id, quantity;
SQL
each check <<'SQL'
UPDATE orders SET status = 'enviado' WHERE id = 1;
SQL
each restrict <<'SQL'
DELETE FROM customers WHERE email = 'ana@example.com';
SQL
each cascade <<'SQL'
SELECT count(*) FROM order_lines WHERE order_id = 3;
DELETE FROM orders WHERE id = 3;
SELECT count(*) FROM order_lines WHERE order_id = 3;
SQL
each no-where <<'SQL'
SELECT sku, price FROM products;
UPDATE products SET price = price * 1.10;
SELECT sku, price FROM products;
SQL
each where-first <<'SQL'
SELECT id, status FROM orders WHERE customer_id = 1 AND status = 'placed';
UPDATE orders SET status = 'cancelled' WHERE customer_id = 1 AND status = 'placed';
SQL
