---
title: A carga noturna inteira, sobre um dia de verdade
version: 1
---

O teste de integração monta o `shop_test` a partir da fixture, roda o carregador de verdade e o
projeto dbt de verdade para o `wh_test`, e confere três coisas:

```
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
```

O primeiro teste é o que mais importa, e a resposta esperada é a parte importante. Ela é
**calculada diretamente da fixture**, por uma consulta em `orders` e `order_lines` que não
compartilha código com o pipeline: nada de view de staging, nada de `int_sales`, nada de dbt. Se o
pipeline e o oráculo fossem o mesmo código, um bug nele concordaria consigo mesmo. O segundo confere
que o mart soma o mesmo que a tabela fato que ele resume. O terceiro é o teste de idempotência da
lição 15, feito parte da bateria.

Na primeira vez que a Ana o rodou, ele não terminou. Depois de um minuto ela olhou o que o warehouse
de teste estava fazendo:

```
-- Who is connected to the test warehouse, and what each one is doing or waiting for.
SELECT pid, application_name AS app, state, wait_event_type AS waiting,
       left(regexp_replace(query, '^/[*][^*]*[*]/\s*', ''), 46) AS query
  FROM pg_stat_activity
 WHERE datname = 'wh_test' AND pid <> pg_backend_pid()
 ORDER BY pid;
```

```
ana@vm:~/etl$ timeout 150 python -m pytest -q tests/test_nightly.py > /tmp/pytest.out 2>&1 &
ana@vm:~/etl$ psql -d wh_test -f waiting.sql
  pid  | app |        state        | waiting |                     query                      
-------+-----+---------------------+---------+------------------------------------------------
 10378 |     | idle in transaction | Client  | SELECT md5(string_agg(f::text, chr(10) ORDER B
 10428 | dbt | active              | Lock    | alter table "wh_test"."dbt_marts"."daily_sales
(2 rows)

ana@vm:~/etl$ cat /tmp/pytest.out; echo
..
```

Duas conexões. Uma é a do próprio teste, **idle in transaction**: a última consulta dela, o `md5` do
terceiro teste, terminou, mas o psycopg abre uma transação com a primeira consulta numa conexão e a
mantém aberta até o commit — e o segundo teste tinha lido o `daily_sales` nessa mesma transação. A
outra é o dbt, no meio do segundo build, **esperando um lock** para pôr o `daily_sales` no lugar com
o nome certo. Cada um esperava o outro: o dbt, que a transação do teste acabasse; o teste, que o dbt
terminasse. O PostgreSQL detecta deadlocks entre as próprias sessões, mas este tem um lado fora do
banco — um processo Python esperando um filho terminar —, então nada o desfez. Dois testes tinham
passado (`..`), e o terceiro teria esperado para sempre se o `timeout`
não o tivesse encerrado.

É a lição sobre locks da lição 7, achada por um teste e não por um relatório de gerente travado às
oito da manhã. A correção é ler sem deixar uma transação aberta:

```
ana@vm:~/etl$ grep -n -B1 -A1 "autocommit=True" tests/test_nightly.py
32-    # autocommit: a test that only reads must not hold locks the next build waits for
33:    with psycopg.connect("dbname=shop_test", autocommit=True) as shop, \
34:         psycopg.connect("dbname=wh_test", autocommit=True) as wh:
35-        yield shop, wh
```

```
ana@vm:~/etl$ time python -m pytest -q tests/test_nightly.py 2>&1 | tail -n 3
...                                                                      [100%]
3 passed in 7.87s

real	0m8.099s
user	0m7.193s
sys	0m0.427s
```

Três passaram, em menos de oito segundos. Depois a bateria inteira, unidade e integração juntas:

```
ana@vm:~/etl$ python -m pytest -q tests
..........                                                               [100%]
10 passed in 7.82s
done
```

Dez testes, e a primeira execução da bateria de integração achou um bug no teste, e não no pipeline. Isso acontece, e ainda assim vale
achar: um teste que trava é um teste que ninguém roda.
