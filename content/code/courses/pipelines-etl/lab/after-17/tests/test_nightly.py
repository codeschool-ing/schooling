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
    # autocommit: a test that only reads must not hold locks the next build waits for
    with psycopg.connect("dbname=shop_test", autocommit=True) as shop, \
         psycopg.connect("dbname=wh_test", autocommit=True) as wh:
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
