#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of gcp-data (Spanner), as a script
# that produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE EMULATOR IS STARTED WITH THE COMMAND THE LESSON GIVES, as the student
# starts it in a terminal of its own; here it runs in the background. schema.sql,
# stale.py, two.py and price.py are the fences their files introduce, and
# keys.py and order.py are the schooling-examples, all read out of the lesson.
#
# NOTHING HERE IS SPANNER'S CAPACITY. The emulator is one process with no
# splits, no replicas and no TrueTime; the hotspot, external consistency, the
# editions and the bill are taught from Google's documentation and pricing page.
# The UUID counts in the keys block differ on every run, because UUIDs are random.
#
# STAGED: nothing beyond what lab.sh stages for every lesson.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
L="$HERE"
emu_start spanner || exit 1

# ---- instance-and-database ----------------------------------------------------
block configs
run 'gcloud spanner instance-configs list'
block instance
run 'gcloud spanner instances create quitanda --config=emulator-config --description="Quitanda shop" --processing-units=100'
run 'gcloud spanner instances list'
block pu-refused
run 'gcloud spanner instances create quitanda-test --config=emulator-config --description="A test" --processing-units=150'
file_fence "$L/instance-and-database.md" schema.sql > schema.sql
block database
run 'gcloud spanner databases create shop --instance=quitanda --ddl-file=schema.sql'
run "gcloud spanner databases ddl describe shop --instance=quitanda | grep -c 'CREATE TABLE'"
block rows
run 'gcloud spanner rows insert --instance=quitanda --database=shop --table=Customers --data=CustomerId=c-17,Name=Ana,District=Lapa'
run 'gcloud spanner rows insert --instance=quitanda --database=shop --table=Stock --data=Product=banana,Units=10'
run 'gcloud spanner rows insert --instance=quitanda --database=shop --table=Stock --data=Product=rice-5kg,Units=30'
run "gcloud spanner databases execute-sql shop --instance=quitanda --sql='SELECT Product, Units FROM Stock ORDER BY Product'"

block dialect
run 'gcloud spanner databases create shop-pg --instance=quitanda --database-dialect=POSTGRESQL'
run "gcloud spanner databases ddl update shop-pg --instance=quitanda --ddl='CREATE TABLE customers (customer_id varchar(36) NOT NULL PRIMARY KEY, name text NOT NULL)'"
run "gcloud spanner databases execute-sql shop-pg --instance=quitanda --sql=\"INSERT INTO customers (customer_id, name) VALUES ('c-17', 'Ana')\""
run "gcloud spanner databases execute-sql shop-pg --instance=quitanda --sql='SELECT customer_id, name FROM customers'"
block dialect-limits
run "gcloud spanner databases execute-sql shop-pg --instance=quitanda --sql='SELECT version()'"
run "gcloud spanner databases ddl update shop-pg --instance=quitanda --ddl='CREATE EXTENSION pg_trgm'"

# ---- the-key ------------------------------------------------------------------
example "$L/the-key.md" keys.py keys.py
block keys
run 'python3 keys.py'

# ---- interleaving -------------------------------------------------------------
block interleave-refused
run "gcloud spanner databases ddl update shop --instance=quitanda --ddl='CREATE TABLE OrderNotes (OrderId INT64 NOT NULL, Note STRING(MAX)) PRIMARY KEY (OrderId), INTERLEAVE IN PARENT Customers'"
block interleave-rows
run 'gcloud spanner rows insert --instance=quitanda --database=shop --table=Customers --data=CustomerId=c-18,Name=Bruno,District=Mooca'
run 'gcloud spanner rows insert --instance=quitanda --database=shop --table=Orders --data=CustomerId=c-18,Day=2026-10-29,TotalCents=4590'
run 'gcloud spanner rows insert --instance=quitanda --database=shop --table=Orders --data=CustomerId=c-18,Day=2026-10-30,TotalCents=1380'
run "gcloud spanner databases execute-sql shop --instance=quitanda --sql=\"SELECT c.Name, o.OrderId, o.Day, o.TotalCents FROM Customers c JOIN Orders o ON o.CustomerId = c.CustomerId WHERE c.CustomerId = 'c-18'\""
block index
run "gcloud spanner databases ddl update shop --instance=quitanda --ddl='CREATE INDEX OrdersByDay ON Orders(Day) STORING (TotalCents)'"
run "gcloud spanner databases execute-sql shop --instance=quitanda --sql=\"SELECT Day, CustomerId, TotalCents FROM Orders@{FORCE_INDEX=OrdersByDay} WHERE Day = '2026-10-29'\""
block index-interleaved
run "gcloud spanner databases ddl update shop --instance=quitanda --ddl='CREATE INDEX OrdersByCustomerDay ON Orders(CustomerId, Day), INTERLEAVE IN Customers'"
block cascade
run 'gcloud spanner rows delete --instance=quitanda --database=shop --table=Customers --keys=c-18'
run "gcloud spanner databases execute-sql shop --instance=quitanda --sql=\"SELECT COUNT(*) AS orders FROM Orders WHERE CustomerId = 'c-18'\""

# ---- transactions -------------------------------------------------------------
example "$L/transactions.md" order.py order.py
file_fence "$L/transactions.md" stale.py > stale.py
file_fence "$L/transactions.md" two.py > two.py
block order
run 'python3 order.py c-17 banana 4 2760'
run 'python3 order.py c-17 banana 8 5520'
run 'python3 order.py c-99 banana 1 690'
block order-after
run "gcloud spanner databases execute-sql shop --instance=quitanda --sql='SELECT CustomerId, OrderId, Day, TotalCents FROM Orders'"
run "gcloud spanner databases execute-sql shop --instance=quitanda --sql=\"SELECT Units FROM Stock WHERE Product = 'banana'\""
block stale
run 'python3 stale.py'
block two
run 'python3 two.py'

# ---- capacity-and-price -------------------------------------------------------
block editions
run "gcloud spanner instances create --help | sed -n '/^     --edition/,/Standard edition/p'"
file_fence "$L/capacity-and-price.md" price.py > price.py
block price
run 'python3 price.py'
block big-instance
run 'gcloud spanner instances create quitanda-big --config=emulator-config --description="Five nodes" --nodes=5'
run "gcloud spanner instances describe quitanda-big --format='value(nodeCount,processingUnits)'"
block update-refused
run 'gcloud spanner instances update quitanda --processing-units=200'
block no-plan
run "gcloud spanner databases execute-sql shop --instance=quitanda --sql='SELECT * FROM Stock' --query-mode=PLAN"
run "gcloud spanner databases execute-sql shop --instance=quitanda --sql='SELECT * FROM Stock' --query-mode=PROFILE"
block accepts
run 'gcloud spanner instances create quitanda-sp --config=regional-southamerica-east1 --description="São Paulo" --processing-units=100 --edition=ENTERPRISE'
run 'gcloud spanner instances describe quitanda-sp'
