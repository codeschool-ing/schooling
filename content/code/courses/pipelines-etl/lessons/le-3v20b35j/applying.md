---
title: Applying the changes
version: 1
---

A stream of changes needs a starting point to apply them to. Ana copies the customers whole, once,
into a schema of the warehouse called `cdc` — after the slot was created, so that nothing committed
in between can fall through the gap:

```
-- The starting point: the customers as they are now, copied whole.
CREATE SCHEMA IF NOT EXISTS cdc;
DROP TABLE IF EXISTS cdc.customers;
CREATE TABLE cdc.customers (
  customer_id integer PRIMARY KEY, name text, email text, city text, state text,
  created_at timestamptz, updated_at timestamptz);
```

```
ana@vm:~/etl$ psql -q -d wh -f snapshot_customers.sql
psql:snapshot_customers.sql:3: NOTICE:  table "customers" does not exist, skipping
ana@vm:~/etl$ psql -c "\copy customers TO /tmp/customers.csv" && psql -d wh -c "\copy cdc.customers FROM /tmp/customers.csv"
COPY 5079
COPY 5079
```

From then on the copy is kept current by reading the slot and doing to it whatever the shop did:

```schooling-example
{
  "language": "python",
  "file": "apply_cdc.py",
  "parts": [
    {
      "code": "\"\"\"Apply the shop's committed changes to customers, read from a logical\nreplication slot, to the copy in the warehouse.\"\"\"\nimport re\n\nimport psycopg\n\n"
    },
    {
      "code": "FIELD = re.compile(r\"(\\w+)\\[[^\\]]+\\]:('(?:[^']|'')*'|\\S+)\")\n\n\n",
      "note": "`test_decoding` writes each column as `name[type]:value`, with text quoted and a quote inside doubled. One regular expression reads that."
    },
    {
      "code": "def values(text):\n    out = {}\n    for name, raw in FIELD.findall(text):\n        out[name] = None if raw == \"null\" else raw.strip(\"'\").replace(\"''\", \"'\")\n    return out\n\n\n",
      "note": "Turns the text of one change into a dictionary of column to value, with `null` as `None`."
    },
    {
      "code": "done = {\"INSERT\": 0, \"UPDATE\": 0, \"DELETE\": 0, \"other tables\": 0}\nwith psycopg.connect(\"dbname=shop\") as shop, psycopg.connect(\"dbname=wh\") as wh:\n    changes = shop.execute(\n        \"SELECT lsn, data FROM pg_logical_slot_get_changes('wh_cdc', NULL, NULL)\").fetchall()\n",
      "note": "**`get_changes` consumes.** It returns everything committed since the last call and moves the slot past it — but only when the shop's transaction commits, which happens after the warehouse's, because the connections close in reverse order."
    },
    {
      "code": "    for lsn, data in changes:\n        if not data.startswith(\"table \"):\n            continue                                   # BEGIN and COMMIT lines\n        if not data.startswith(\"table public.customers: \"):\n            done[\"other tables\"] += 1\n            continue\n",
      "note": "Transaction boundaries and every other table are counted and skipped. A real deployment would ask the database for only the tables it wants, which `test_decoding` cannot do."
    },
    {
      "code": "        op, _, rest = data.removeprefix(\"table public.customers: \").partition(\": \")\n        row = values(rest)\n",
      "note": "The operation and the columns."
    },
    {
      "code": "        if op == \"DELETE\":\n            wh.execute(\"DELETE FROM cdc.customers WHERE customer_id = %s\", (row[\"customer_id\"],))\n",
      "note": "A delete carries the key, and the key is enough."
    },
    {
      "code": "        else:\n            cols = list(row)\n            wh.execute(\n                f\"INSERT INTO cdc.customers ({', '.join(cols)}) VALUES ({', '.join(['%s'] * len(cols))})\"\n                f\" ON CONFLICT (customer_id) DO UPDATE SET \"\n                + \", \".join(f\"{c} = excluded.{c}\" for c in cols if c != \"customer_id\"),\n                list(row.values()))\n",
      "note": "An insert or an update becomes the same statement: insert the row, or overwrite it if the key is already there. **Applying the same change twice leaves the same row**, so a run that dies after the warehouse commits and before the slot moves does no harm when the changes come again."
    },
    {
      "code": "        done[op] += 1\nprint(f\"{len(changes)} changes read up to {changes[-1][0] if changes else '-'}: {done}\")"
    }
  ]
}
```

The first run applies 1 March. The second, straight after it, finds nothing — the first consumed
the changes and the slot moved on:

```
ana@vm:~/etl$ python apply_cdc.py
1088 changes read up to 0/BA8A238: {'INSERT': 19, 'UPDATE': 4, 'DELETE': 0, 'other tables': 643}
ana@vm:~/etl$ python apply_cdc.py
0 changes read up to -: {'INSERT': 0, 'UPDATE': 0, 'DELETE': 0, 'other tables': 0}
```

Twenty-three customer changes out of 666: the rest were orders, lines and payments, which this
script reads and drops. **Reading every table's changes to keep one table is waste**, and a real
deployment avoids it with a *publication*, which lists the tables a reader wants, and the `pgoutput`
plugin, which honours it. `test_decoding` has no such option; it is the plugin to learn on, not the
one to run.

## The day the watermark failed

Ana plays the days from 2 to 13 March with `shop day`, running `apply_cdc.py` after each one,
and then plays the 14th — the day a
customer asked to be forgotten:

```
ana@vm:~/etl$ sudo shop day 2026-03-14
ana@vm:~/etl$ python apply_cdc.py
2268 changes read up to 0/BE7CF38: {'INSERT': 22, 'UPDATE': 4, 'DELETE': 1, 'other tables': 1387}
ana@vm:~/etl$ psql -d wh -c "SELECT count(*) FROM cdc.customers WHERE customer_id = 1880"
 count 
-------
     0
(1 row)
```

`'DELETE': 1`, and customer 1880 is gone from the copy. **The delete that lesson 4's incremental
extraction never saw arrived here as a line like any other.** And the copy, after fourteen days of
changes applied one by one, agrees with the shop on every row:

```
ana@vm:~/etl$ psql -c "\copy customers TO /tmp/customers.csv" && psql -d wh -c "CREATE TEMP TABLE now_in_shop (LIKE cdc.customers)" -c "\copy now_in_shop FROM /tmp/customers.csv" -c "SELECT (SELECT count(*) FROM (TABLE now_in_shop EXCEPT TABLE cdc.customers) a) AS only_in_shop, (SELECT count(*) FROM (TABLE cdc.customers EXCEPT TABLE now_in_shop) b) AS only_in_copy"
COPY 5345
CREATE TABLE
COPY 5345
 only_in_shop | only_in_copy 
--------------+--------------
            0 |            0
(1 row)
```

The same `EXCEPT` check as lesson 2, now in one command because the shop and the warehouse are
different databases: the shop's table is copied into a temporary table first, and the two are
compared in both directions.
