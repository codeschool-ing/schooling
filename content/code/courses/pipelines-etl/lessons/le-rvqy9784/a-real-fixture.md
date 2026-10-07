---
title: A fixture that is real data
version: 1
---

An integration test needs a shop to run against, and the choice of shop decides what the test can
find. A fixture written by hand holds the cases its author imagined. Ana cuts hers out of the real
shop instead: one whole day, every order placed in it, and everything those orders touch.

```
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
```

`pg_dump --schema-only` copies the shop's table definitions exactly, constraints included, so the
fixture database has the same shape as the real one. Then one `\copy` per table, each written as the
query that decides what belongs in the day: the orders placed on the 2nd in São Paulo time, their
lines and payments, and the customers they name. All the shops and all the books go in too, because
they are small and every order needs them.

```
ana@vm:~/etl$ sh tests/make_fixture.sh 2026-03-02
  1201 tests/fixture/books.csv
   180 tests/fixture/customers.csv
   416 tests/fixture/order_lines.csv
   259 tests/fixture/orders.csv
   259 tests/fixture/payments.csv
     8 tests/fixture/shops.csv
  2323 total
```

Two hundred and fifty-eight orders, 415 lines, 179 customers: small enough to keep in the
repository next to the tests, and it is one real day, with everything a real day has. Some orders
were placed at a till by nobody; some were refunded; one customer may since have asked to be
forgotten. **None of that had to be imagined to be in the test.**

A slice of real data needs two cautions. **It is personal data until it is made not to be.** The
shop's `customers` table holds names and e-mail addresses, and no test needs either. The script
replaces them on the way out — `customer 4211`, `4211@example.invalid` — and keeps the city and state
the pipeline uses. Anything personal that a test does need must be treated like the database it came
from. And it is a snapshot: when the shop's tables change shape, Ana cuts the fixture again by running
the same script, which is why the script is kept with it.
