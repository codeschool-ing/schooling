---
title: Proving it, every time
version: 1
---

*This load is idempotent* is a claim, and lesson 12's lesson was that a claim about data is worth
what the test that checks it is worth. So Ana writes the test once, for any step:

```
#!/bin/sh
# Run a step twice and say whether the second run changed anything.
#   sh twice.sh 'STEP' 'QUERY'
# QUERY is any SELECT that describes what the step leaves behind; the step is
# idempotent, as far as that query can see, when it gives the same answer after
# the first run and after the second.
set -e
step=$1 query=$2
sh -c "$step" >/dev/null
first=$(psql -d wh -Atc "$query")
sh -c "$step" >/dev/null
second=$(psql -d wh -Atc "$query")
echo "after one run:  $first"
echo "after two runs: $second"
if [ "$first" = "$second" ]; then echo "idempotent"; else echo "NOT idempotent"; exit 1; fi
```

Run the step, describe what it left; run it again, describe it again; compare. The description is
whatever query fits the step — a fingerprint of the table it writes, usually. Then she runs it over
every step the nightly has:

```
ana@vm:~/etl$ sh twice.sh 'psql -q -d wh -At -f load/dim_book.sql' 'SELECT count(*), md5(string_agg(d::text, chr(10) ORDER BY book_id)) FROM marts.dim_book d'
psql:load/dim_book.sql:9: NOTICE:  relation "dim_book" already exists, skipping
psql:load/dim_book.sql:9: NOTICE:  relation "dim_book" already exists, skipping
after one run:  1200|1e2c91c165716d39f65b4be5211ade52
after two runs: 1200|1e2c91c165716d39f65b4be5211ade52
idempotent
ana@vm:~/etl$ sh twice.sh 'psql -q -d wh -f load/dim_customer.sql' 'SELECT count(*), md5(string_agg(d::text, chr(10) ORDER BY customer_key)) FROM marts.dim_customer d'
psql:load/dim_customer.sql:10: NOTICE:  relation "dim_customer" already exists, skipping
psql:load/dim_customer.sql:10: NOTICE:  relation "dim_customer" already exists, skipping
after one run:  5390|7a50cb47200d94b3580fa5aa406e5263
after two runs: 5390|7a50cb47200d94b3580fa5aa406e5263
idempotent
ana@vm:~/etl$ sh twice.sh 'dbt build --project-dir shop --quiet' 'SELECT count(*), md5(string_agg(f::text, chr(10) ORDER BY order_id, line_no)) FROM dbt_marts.fact_sales f'
after one run:  32886|7898a3d51049a824177c4fd81533f7e0
after two runs: 32886|7898a3d51049a824177c4fd81533f7e0
idempotent
ana@vm:~/etl$ sh twice.sh 'python load_raw.py' 'SELECT count(*), md5(string_agg(e::text, chr(10) ORDER BY e::text)) FROM raw.events e'
after one run:  41783|a11b783c5e5e3ef7e3af187848873be4
after two runs: 41783|a11b783c5e5e3ef7e3af187848873be4
idempotent
```

Four steps, four *idempotent*. `dim_book` is an upsert, and the second run updated nothing.
`dim_customer` is lesson 7's type 2 dimension, whose updates only touch customers who moved, so a
second run finds nobody to move. `dbt build` rebuilt every model and table and left the fact table's
32,886 lines exactly as they were. `load_raw.py` emptied raw and filled it again with the same
documents.

Two things make this worth more than it looks. It is cheap enough to run on every change to a load,
which is when idempotency is lost: somebody adds a step, and the step appends. And **it tests the
property itself rather than the code that is supposed to provide it**. `twice.sh` does not know what
an upsert is; it only knows that the table did not change, which is the thing that matters.

What it cannot show is a step that is idempotent *today* by luck — an insert that happens to find
nothing to insert because nothing new arrived. The fingerprint must be taken over the rows the step
writes, on a day when it has rows to write. Lesson 17 makes runs like this part of the tests.
