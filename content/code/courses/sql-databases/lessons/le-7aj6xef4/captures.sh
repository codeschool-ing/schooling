#!/usr/bin/env bash
# The sessions quoted in lesson 12 of sql-databases, as a script that produces
# them — and the SQLite plan quoted in lesson 10's the-other-engines.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up && sudo bash ../../lab.sh role   # once
#   sudo apt install -y sqlite3 mysql-server   # and start mysqld
#   sudo bash captures.sh                      # PostgreSQL, SQLite, MySQL
#   sudo apt purge -y 'mysql-server*' && sudo apt install -y mariadb-server
#   sudo bash captures.sh                      # MariaDB
#
# MySQL and MariaDB cannot be installed together, so the script asks the server
# which one it is and captures that one's blocks. Each engine gets lesson 1's
# shop: shop.sql out of lesson 1's reading-a-schema.md for PostgreSQL, and
# shop-sqlite.sql and shop-mysql.sql out of this lesson's the-four.md.
#
# psql runs in a pseudo-terminal, as everywhere in this course. sqlite3 and
# mysql run once per statement, as `sqlite3 -column -header shop.db 'SQL'` and
# `mysql -t shop -e 'SQL'` — the lesson says so — and the `sqlite>`, `mysql>`
# and `MariaDB [shop]>` before each statement is printed by this script. What
# follows it is what the client printed.
#
# Recorded on Ubuntu 24.04: PostgreSQL 16.15, SQLite 3.45.1, MySQL 8.0.46,
# MariaDB 10.11.14, TZ=UTC.
set -uo pipefail
cd "$(dirname "$0")"
export TZ=UTC LC_ALL=C.UTF-8
LAB_SH=../../lab.sh
FENCE=../../lab/fence.py
lab() { bash "$LAB_SH" "$@"; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
ana() { (cd /home/ana && runuser -u ana -- env HOME=/home/ana TZ=UTC LC_ALL=C.UTF-8 "$@"); }
# sq 'SQL' ...: each statement typed at sqlite>, run against ~/shop.db
sq() { for q in "$@"; do printf 'sqlite> %s\n' "$q"; ana sqlite3 -column -header shop.db "$q" 2>&1; done; }
# my PROMPT 'SQL' ...: each statement typed at the mysql client's prompt
my() { local p=$1; shift; for q in "$@"; do printf '%s %s\n' "$p" "$q"; mysql -t shop -e "$q" 2>&1; done; }
exec 9>/var/tmp/sql-capture.lock; flock 9

REPORT="SELECT c.city, count(DISTINCT o.id) AS orders, sum(l.quantity * l.unit_price) AS revenue FROM customers c JOIN orders o ON o.customer_id = c.id JOIN order_lines l ON l.order_id = o.id WHERE o.status <> 'cancelled' GROUP BY c.city ORDER BY revenue DESC;"
THREE="INSERT INTO order_lines VALUES (5, 2, 'three', 189.00);"
EXACT="SELECT 0.1 + 0.2 = 0.3 AS exact;"
GROUP="SELECT city, name, count(*) FROM customers GROUP BY city;"
UPPER="SELECT id, email FROM customers WHERE email = 'ANA@EXAMPLE.COM';"
DIALECT="SELECT 5 / 2 AS half, 'MN' || '-330' AS sku;"
FELIPE="INSERT INTO customers (name, email, city) VALUES ('Felipe Nunes', 'felipe@example.com', 'Recife') RETURNING id;"

if [ "${ENGINE:-}" != mariadb ] && ! mysql -V 2>/dev/null | grep -q MariaDB; then
# --- PostgreSQL ------------------------------------------------------------------
lab role >/dev/null 2>&1
lab exec 'createdb shop'
python3 "$FENCE" ../le-96rkt034/installing-postgresql.md 'cat > ~/.psqlrc' | lab exec bash
python3 "$FENCE" ../le-96rkt034/reading-a-schema.md '-- shop.sql:' | lab exec 'cat > shop.sql'
lab exec 'psql -q shop -f shop.sql >/dev/null'

block pg-report;   printf '%s\n' "$REPORT" | session shop
block pg-three;    printf '%s\n' "$THREE" | session shop
block pg-typeof;   printf '%s\n' "SELECT sku, price, pg_typeof(price) FROM products;" | session shop
block pg-exact;    printf '%s\n' "$EXACT" | session shop
block pg-group;    printf '%s\n' "$GROUP" | session shop
block pg-upper;    printf '%s\n' "$UPPER" | session shop
block pg-dialect;  printf '%s\n' "$DIALECT" | session shop
block pg-d-orders; printf '%s\n' '\d orders' | session shop
block pg-felipe;   printf '%s\n' "$FELIPE" | session shop
block pg-ddl
session shop <<'SQL'
BEGIN;
ALTER TABLE customers ADD COLUMN phone varchar(30);
ROLLBACK;
SELECT column_name FROM information_schema.columns WHERE table_name = 'customers';
SQL

# --- SQLite ------------------------------------------------------------------------
python3 "$FENCE" the-four.md '-- shop-sqlite.sql:' | lab exec 'cat > shop-sqlite.sql'
lab exec 'rm -f shop.db && sqlite3 shop.db < shop-sqlite.sql'

block sq-report;  sq "$REPORT"
block sq-locked-1
printf 'sqlite> %s\n' "BEGIN;" "UPDATE products SET price = 359.00 WHERE sku = 'KB-101';"
rm -f /tmp/sql-capture.fifo; mkfifo /tmp/sql-capture.fifo; chmod 666 /tmp/sql-capture.fifo
(sleep 6 > /tmp/sql-capture.fifo &)
(ana sqlite3 shop.db < /tmp/sql-capture.fifo > /dev/null 2>&1 &)
sleep 0.5
printf "BEGIN;\nUPDATE products SET price = 359.00 WHERE sku = 'KB-101';\n" > /tmp/sql-capture.fifo
sleep 1
block sq-locked-2; sq "UPDATE products SET price = 199.00 WHERE sku = 'MS-204';"
block sq-read;     sq "SELECT sku, price FROM products WHERE sku = 'KB-101';"
sleep 6
block sq-wal;      sq "PRAGMA journal_mode;" "PRAGMA journal_mode = WAL;" "PRAGMA journal_mode;"
block sq-three;    sq "$THREE" "SELECT order_id, product_id, quantity, typeof(quantity) FROM order_lines WHERE order_id = 5;"
block sq-typeof;   sq "SELECT sku, price, typeof(price) FROM products;"
block sq-exact;    sq "$EXACT"
block sq-strict;   sq "CREATE TABLE order_lines_strict (order_id INTEGER NOT NULL, product_id INTEGER NOT NULL, quantity INTEGER NOT NULL CHECK (quantity > 0), unit_price TEXT NOT NULL, PRIMARY KEY (order_id, product_id)) STRICT;" "INSERT INTO order_lines_strict VALUES (5, 2, 'three', '189.00');"
block sq-group;    sq "$GROUP"
block sq-upper;    sq "$UPPER"
block sq-dialect;  sq "$DIALECT"
block sq-felipe;   sq "$FELIPE"
# lesson 10, the-other-engines: the plan, on a copy so this shop is left alone
lab exec 'cp shop.db plan.db'
block sq-plan
for q in "EXPLAIN QUERY PLAN SELECT * FROM orders WHERE customer_id = 42;" \
         "EXPLAIN QUERY PLAN SELECT * FROM customers WHERE email = 'user42@example.com';" \
         "CREATE INDEX orders_customer_id_idx ON orders (customer_id);" \
         "EXPLAIN QUERY PLAN SELECT * FROM orders WHERE customer_id = 42;"; do
  printf 'sqlite> %s\n' "$q"; ana sqlite3 plan.db "$q" 2>&1
done

# --- MySQL -------------------------------------------------------------------------
P='mysql>'
else
P='MariaDB [shop]>'
fi
mysql -e 'DROP DATABASE IF EXISTS shop; CREATE DATABASE shop'
python3 "$FENCE" the-four.md '-- shop-mysql.sql:' | mysql shop
if [ "$P" = 'mysql>' ]; then
block my-report;    my "$P" "$REPORT"
block my-three;     my "$P" "$THREE"
block my-exact;     my "$P" "$EXACT"
block my-sqlmode;   my "$P" 'SELECT @@sql_mode\G'
block my-group;     my "$P" "$GROUP"
block my-upper;     my "$P" "$UPPER"
block my-collation; my "$P" "SELECT @@collation_database AS collation_database;"
block my-bin;       my "$P" "SELECT id, email FROM customers WHERE email COLLATE utf8mb4_bin = 'ANA@EXAMPLE.COM';" "SELECT id, email FROM customers WHERE email COLLATE utf8mb4_bin = 'ana@example.com';"
block my-dialect;   my "$P" "$DIALECT"
block my-showcreate; my "$P" 'SHOW CREATE TABLE orders\G'
block my-felipe;    my "$P" "$FELIPE"
block my-ddl
printf '%s %s\n' "$P" 'BEGIN;' "$P" 'ALTER TABLE customers ADD COLUMN phone varchar(30);' "$P" 'ROLLBACK;' "$P" 'DESCRIBE customers;'
mysql -t shop -e 'BEGIN; ALTER TABLE customers ADD COLUMN phone varchar(30); ROLLBACK; DESCRIBE customers;' 2>&1
else
block ma-sqlmode;   my "$P" 'SELECT @@sql_mode\G'
block ma-group;     my "$P" "$GROUP"
block ma-upper;     my "$P" "$UPPER"
block ma-felipe;    my "$P" "$FELIPE"
fi
