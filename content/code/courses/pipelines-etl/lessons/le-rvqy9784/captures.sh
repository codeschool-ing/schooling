#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of pipelines-etl, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: `lab.sh reset` and the first twenty-one
# days of March before the first block; Ana's project from lessons 6 to 9,
# copied into ~/etl from ../../lab/project, with what lessons 11, 12, 15 and 16
# changed copied over it from ../../lab/after-11, after-12, after-15 and
# after-16; raw loaded and the dbt project built once; and copies of
# validate_prices.py and load_raw.py kept in /tmp before Ana edits them, so
# that `diff` can show each edit. Her edits to existing files are applied from
# here and shown in the lesson with `diff` or `grep`; and the waits in the
# `hang` block, for the test to block and then for its timeout to end it. The files are written by `put` and shown in
# the lesson. Airflow is not started.
#
# dbt's clock in its own lines is UTC; times and durations are the recording's
# own.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, Python 3.13, pytest 9.1.1,
# dbt-core 1.12.5, 4 cores, TZ=America/Sao_Paulo, on 2026-10-07.
. "$(dirname "$0")/../../capture.sh"
L=$(cd "$(dirname "$0")/../../lab" && pwd)
shop() { printf 'ana@vm:~/etl/shop$ %s\n' "$*"; lab exec "cd shop && $*" 2>&1 || true; }
lab reset >/dev/null
lab until 2026-03-21 >/dev/null
for f in $(cd "$L/project" && find . -type f ! -name README | sed 's|^\./||'); do put "$f" < "$L/project/$f"; done
for o in after-11 after-12 after-15 after-16; do
  for f in $(cd "$L/$o" && find . -type f ! -name README ! -name profiles.yml | sed 's|^\./||'); do put "$f" < "$L/$o/$f"; done
done
lab exec 'rm -rf ~/.dbt; mkdir -p ~/.dbt && cat > ~/.dbt/profiles.yml' < "$L/after-11/profiles.yml"
lab exec 'touch landing/prices.jsonl; python load_raw.py >/dev/null; cd shop && dbt build --full-refresh >/dev/null'
lab exec 'cp validate_prices.py /tmp/validate_prices.before.py; cp load_raw.py /tmp/load_raw.before.py'

# ---------------------------------------------------------------- unit tests
lab exec 'python3 - validate_prices.py' <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
head, tail = s.split('src, good_path, bad_path = sys.argv[1:4]\n')
body = "\n".join(("    " + l) if l else l for l in tail.rstrip("\n").split("\n"))
body = body.replace("    sys.exit(1)", "    return 1")
s = (head + "def main(src, good_path, bad_path):\n" + body + "\n    return 0\n\n\n"
     'if __name__ == "__main__":\n    sys.exit(main(*sys.argv[1:4]))\n')
open(p, "w").write(s)
PY
block refactor
on 'diff /tmp/validate_prices.before.py validate_prices.py | head -n 12; echo …; diff /tmp/validate_prices.before.py validate_prices.py | tail -n 6'

put tests/test_validate.py <<'PY'
"""Unit tests for the price validator: one record in, one decision out."""
from collections import Counter

from validate_prices import check, isbn13_ok


def price(**changes):
    """A record the validator accepts as it is, with some fields changed."""
    rec = {"isbn": "9786574218454", "publisher": "Borda", "list_price_cents": 10490,
           "currency": "BRL", "updated_at": "2026-01-01T05:01:00-03:00"}
    rec.update(changes)
    return rec


def test_a_real_isbn_passes_its_check_digit():
    assert isbn13_ok("9786574218454")


def test_one_wrong_digit_fails_it():
    assert not isbn13_ok("9786574218455")


def test_hyphens_are_removed_and_counted():
    rec, fixed = price(isbn="978-65-7421-845-4"), Counter()
    assert check(rec, fixed) is None
    assert rec["isbn"] == "9786574218454"
    assert fixed == {"isbn written with hyphens": 1}


def test_a_missing_price_is_rejected():
    assert check(price(list_price_cents=None), Counter()) == "price missing"


def test_a_price_with_a_decimal_comma_is_rejected():
    assert check(price(list_price_cents="104,90"), Counter()) == "price '104,90' is not a number"


def test_another_currency_is_rejected_not_converted():
    assert check(price(currency="USD"), Counter()) == "currency 'USD'"


def test_a_price_in_reais_is_not_taken_for_cents():
    assert check(price(list_price_cents=104.9), Counter()) == "price 104.9 is not a whole number of cents"
PY
code test-validate tests/test_validate.py
block pytest-unit
on 'python -m pytest -q tests/test_validate.py 2>&1 | tail -n 15'
block fix
lab exec "python3 - validate_prices.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
a = '''    if not 100 <= rec["list_price_cents"] <= 100_000:'''
b = '''    if not isinstance(rec["list_price_cents"], int):
        return f"price {rec['list_price_cents']} is not a whole number of cents"
    if not 100 <= rec["list_price_cents"] <= 100_000:'''
assert a in s
open(p, "w").write(s.replace(a, b, 1))
PY
on 'diff /tmp/validate_prices.before.py validate_prices.py | sed -n "/whole number/,+0p;/isinstance(rec/,+0p"'
on 'python -m pytest -q tests/test_validate.py'

# ------------------------------------------------------- dbt unit test
put shop/models/staging/unit_tests.yml <<'YML'
version: 2

unit_tests:
  - name: order_date_is_the_day_in_sao_paulo
    description: >
      Late on a São Paulo evening is already tomorrow in UTC; the order belongs to
      the shop's day. And only a completed order is a sale.
    model: stg_orders
    given:
      - input: source('raw', 'orders')
        rows:
          - {order_id: 1, shop_id: 1, ordered_at: "2026-03-02 23:30:00-03", status: completed}
          - {order_id: 2, shop_id: 1, ordered_at: "2026-03-03 00:10:00-03", status: completed}
          - {order_id: 3, shop_id: 7, ordered_at: "2026-03-02 12:00:00-03", status: refunded}
    expect:
      rows:
        - {order_id: 1, order_date: 2026-03-02, is_sale: true}
        - {order_id: 2, order_date: 2026-03-03, is_sale: true}
        - {order_id: 3, order_date: 2026-03-02, is_sale: false}
YML
code dbt-unit shop/models/staging/unit_tests.yml
block dbt-unit-run
shop 'dbt test -s test_type:unit 2>&1 | grep -E "PASS|FAIL|Done"'

# ------------------------------------------------------- the fixture
put tests/make_fixture.sh <<'SH'
#!/bin/sh
# One real day of the shop, cut out of its database into files that are kept
# with the tests: every order placed that day in São Paulo, its lines and its
# payments, the customers they name, and every shop and book. Customers keep
# their city and state and lose their name and e-mail.
#   sh tests/make_fixture.sh 2026-03-02
set -e
day=${1:?usage: make_fixture.sh YYYY-MM-DD}
out=tests/fixture
mkdir -p $out
pg_dump -d shop --schema-only --no-owner --no-privileges > $out/schema.sql
orders="SELECT order_id FROM orders WHERE (ordered_at AT TIME ZONE 'America/Sao_Paulo')::date = '$day'"
cut() { psql -q -d shop -c "\copy ($2) TO '$out/$1.csv' WITH (FORMAT csv, HEADER)"; }
cut shops       "SELECT * FROM shops ORDER BY shop_id"
cut books       "SELECT * FROM books ORDER BY book_id"
# Names and e-mails are personal and no test needs them: replaced on the way out.
cut customers   "SELECT customer_id, 'customer ' || customer_id AS name, customer_id || '@example.invalid' AS email, city, state, created_at, updated_at FROM customers WHERE customer_id IN (SELECT customer_id FROM orders WHERE order_id IN ($orders)) ORDER BY customer_id"
cut orders      "SELECT * FROM orders WHERE order_id IN ($orders) ORDER BY order_id"
cut order_lines "SELECT * FROM order_lines WHERE order_id IN ($orders) ORDER BY order_id, line_no"
cut payments    "SELECT * FROM payments WHERE order_id IN ($orders) ORDER BY order_id"
wc -l $out/*.csv
SH
code make-fixture tests/make_fixture.sh
block fixture
on 'sh tests/make_fixture.sh 2026-03-02'

# ------------------------------------------------------- the seams
lab exec "sed -i 's|^with psycopg.connect(\"dbname=shop\") as shop, psycopg.connect(\"dbname=wh\") as wh:|SHOP_DB = os.environ.get(\"SHOP_DB\", \"shop\")   # the tests point these at their own databases\\nWH_DB = os.environ.get(\"WH_DB\", \"wh\")\\n\\nwith psycopg.connect(dbname=SHOP_DB) as shop, psycopg.connect(dbname=WH_DB) as wh:|; s|^import glob$|import glob\\nimport os|' load_raw.py"
lab exec 'cat >> ~/.dbt/profiles.yml' <<'YML'
    test:                       # the integration tests' own warehouse
      type: postgres
      host: /run/etl-pg
      port: 5432
      user: ana
      password: ""
      dbname: wh_test
      schema: dbt
      threads: 4
YML
block seams
on 'diff /tmp/load_raw.before.py load_raw.py'
on 'tail -n 10 ~/.dbt/profiles.yml'

put tests/test_nightly.py <<'PY'
"""Integration tests: the whole nightly, on one real day of the shop, in databases
of its own. The answers are worked out from the fixture directly, by queries that
share no code with the pipeline."""
import os
import subprocess

import psycopg
import pytest

ETL = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DAY = "2026-03-02"


def sh(cmd, **env):
    subprocess.run(cmd, shell=True, check=True, cwd=env.pop("cwd", ETL),
                   env={**os.environ, **env}, stdout=subprocess.DEVNULL)


@pytest.fixture(scope="module")
def warehouse(tmp_path_factory):
    """Build shop_test from the fixture, then run the nightly into wh_test."""
    fixture = os.path.join(ETL, "tests", "fixture")
    sh("dropdb --if-exists --force shop_test; createdb shop_test; "
       f"psql -q -d shop_test -f {fixture}/schema.sql")
    for table in ["shops", "books", "customers", "orders", "order_lines", "payments"]:
        sh(f"psql -q -d shop_test -c \"\\copy {table} FROM '{fixture}/{table}.csv' "
           "WITH (FORMAT csv, HEADER)\"")
    sh("dropdb --if-exists --force wh_test; createdb wh_test")
    empty = tmp_path_factory.mktemp("landing")           # no prices and no events today
    sh(f"python {ETL}/load_raw.py", SHOP_DB="shop_test", WH_DB="wh_test", cwd=empty)
    sh("dbt build --project-dir shop --target test --quiet")
    with psycopg.connect("dbname=shop_test") as shop, psycopg.connect("dbname=wh_test") as wh:
        yield shop, wh


def one(conn, sql):
    return conn.execute(sql).fetchone()


def test_every_completed_line_of_the_day_is_one_fact_row(warehouse):
    shop, wh = warehouse
    expected = one(shop, "SELECT count(*), sum(l.quantity * l.unit_price_cents) "
                         "FROM order_lines l JOIN orders o USING (order_id) "
                         "WHERE o.status = 'completed'")
    got = one(wh, f"SELECT count(*), sum(line_cents) FROM dbt_marts.fact_sales "
                  f"WHERE order_date = '{DAY}'")
    assert got == expected


def test_daily_sales_adds_up_to_the_fact_table(warehouse):
    _, wh = warehouse
    daily = one(wh, "SELECT sum(books), sum(revenue_cents) FROM dbt_marts.daily_sales")
    facts = one(wh, "SELECT sum(quantity), sum(line_cents) FROM dbt_marts.fact_sales")
    assert daily == facts


def test_a_second_build_changes_nothing(warehouse):
    _, wh = warehouse
    fingerprint = ("SELECT md5(string_agg(f::text, chr(10) ORDER BY order_id, line_no)) "
                   "FROM dbt_marts.fact_sales f")
    before = one(wh, fingerprint)
    sh("dbt build --project-dir shop --target test --quiet")
    assert one(wh, fingerprint) == before
PY
code test-nightly tests/test_nightly.py
put waiting.sql <<'SQL'
-- Who is connected to the test warehouse, and what each one is doing or waiting for.
SELECT pid, application_name AS app, state, wait_event_type AS waiting,
       left(regexp_replace(query, '^/[*][^*]*[*]/\s*', ''), 46) AS query
  FROM pg_stat_activity
 WHERE datname = 'wh_test' AND pid <> pg_backend_pid()
 ORDER BY pid;
SQL
code waiting-sql waiting.sql
block hang
on 'timeout 150 python -m pytest -q tests/test_nightly.py > /tmp/pytest.out 2>&1 &'
for i in $(seq 120); do lab exec "psql -d wh_test -Atc \"SELECT count(*) FROM pg_stat_activity WHERE wait_event_type = 'Lock'\" 2>/dev/null" | grep -q '^[1-9]' && break; sleep 2; done
sleep 20
on 'psql -d wh_test -f waiting.sql'
for i in $(seq 120); do lab exec 'pgrep -u ana -f "^/opt/etl/py/bin/python -m pytest" >/dev/null' || break; sleep 2; done
on 'cat /tmp/pytest.out; echo'
block autocommit
lab exec 'python3 - tests/test_nightly.py' <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
a = '    with psycopg.connect("dbname=shop_test") as shop, psycopg.connect("dbname=wh_test") as wh:\n'
b = ('    # autocommit: a test that only reads must not hold locks the next build waits for\n'
     '    with psycopg.connect("dbname=shop_test", autocommit=True) as shop, \\\n'
     '         psycopg.connect("dbname=wh_test", autocommit=True) as wh:\n')
assert a in s
open(p, "w").write(s.replace(a, b))
PY
on 'grep -n -B1 -A1 "autocommit=True" tests/test_nightly.py'
block pytest-integration
on 'time python -m pytest -q tests/test_nightly.py 2>&1 | tail -n 3'
block all
on 'python -m pytest -q tests'
