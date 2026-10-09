---
title: One row at a time, or all of them at once
version: 1
---

Lesson 6's raw loader used `COPY`, and said little about why. Here is why, measured: the
same thirty thousand lines written into an empty table three ways.

```schooling-example
{
  "language": "python",
  "file": "insert_speed.py",
  "parts": [
    {
      "code": "\"\"\"The same 30,000 order lines written into a table three ways, and timed.\"\"\"\nimport time\n\nimport psycopg\n\n",
      "note": "Python's clock and the PostgreSQL driver, nothing else."
    },
    {
      "code": "with psycopg.connect(\"dbname=wh\") as wh:\n    rows = wh.execute(\"SELECT order_date, order_id, line_no, shop_id, customer_id, book_id, \"\n                      \"quantity, line_cents FROM dbt_marts.fact_sales LIMIT 30000\").fetchall()\n",
      "note": "Thirty thousand real lines of the fact table, read into memory once, so that every method writes exactly the same rows."
    },
    {
      "code": "    wh.execute(\"CREATE TEMP TABLE t (LIKE dbt_marts.fact_sales)\")\n    insert = \"INSERT INTO t VALUES (%s, %s, %s, %s, %s, %s, %s, %s)\"\n\n",
      "note": "A temporary table with the fact table's columns, gone when the connection closes. The `INSERT` has one placeholder per column."
    },
    {
      "code": "    def timed(name, write):\n        wh.execute(\"TRUNCATE t\")\n        start = time.perf_counter()\n        write()\n        wh.commit()\n        took = time.perf_counter() - start\n        print(f\"{name:<28}{took:7.2f} s   {len(rows) / took:>10,.0f} rows a second\")\n\n",
      "note": "Each method starts from an empty table, and the clock stops after the commit, so a method cannot look fast by leaving work for later. **All three write inside one transaction**, which is the fair comparison: a commit per row would make the slow one slower still."
    },
    {
      "code": "    def one_statement_per_row():\n        for row in rows:\n            wh.execute(insert, row)\n\n",
      "note": "One statement per row: thirty thousand round trips between Python and the server."
    },
    {
      "code": "    def executemany():\n        wh.cursor().executemany(insert, rows)\n\n",
      "note": "The same statement, handed over with all the rows at once; the driver sends them in batches."
    },
    {
      "code": "    def copy():\n        with wh.cursor().copy(\"COPY t FROM STDIN\") as cp:\n            for row in rows:\n                cp.write_row(row)\n\n",
      "note": "`COPY`: one command, then a stream of rows the server writes as they arrive."
    },
    {
      "code": "    timed(\"one INSERT per row\", one_statement_per_row)\n    timed(\"executemany\", executemany)\n    timed(\"COPY\", copy)",
      "note": "The three, in order."
    }
  ]
}
```

```
ana@vm:~/etl$ python insert_speed.py
one INSERT per row             2.41 s       12,437 rows a second
executemany                    0.48 s       63,095 rows a second
COPY                           0.04 s      711,766 rows a second
```

From one method to the next, **a factor of five, and then a factor of more than ten**: the order lines that
take two and a half seconds one statement at a time take a few hundredths of a second with `COPY`.
Nothing about the rows changed, and nothing about the database. What changed is how many times the
client and the server had to talk.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l19-speeds\" aria-label=\"Rows written per second by three methods, on a logarithmic scale, in one recording: one INSERT per row about 12 thousand, executemany about 63 thousand, COPY about 712 thousand.\"><text x=\"188.0\" y=\"42.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">one INSERT per row</text><rect x=\"200.0\" y=\"30.0\" width=\"21.3\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"229.3\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">12,437</text><text x=\"188.0\" y=\"86.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">executemany</text><rect x=\"200.0\" y=\"74.0\" width=\"180.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"388.0\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">63,095</text><text x=\"188.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">COPY</text><rect x=\"200.0\" y=\"118.0\" width=\"416.8\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"608.8\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">711,766</text><path d=\"M200.0 168.0 L650.0 168.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M200.0 168.0 L200.0 172.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"200.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10,000</text><path d=\"M425.0 168.0 L425.0 172.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"425.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100,000</text><path d=\"M650.0 168.0 L650.0 172.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"650.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1,000,000</text><text x=\"425.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">rows a second (log scale)</text></svg>", "caption": "Each step to the right of the scale is ten times faster. The rows were the same."}
```

Each `INSERT` is a round trip: the client sends a statement, the server parses it, plans it, runs
it and answers, and only then does the next one start. With thirty thousand rows that is thirty
thousand conversations, and almost all the time is spent in the conversation rather than in the
writing. `executemany` sends the statements in batches, so there are fewer waits. `COPY` sends one
command and then a stream of rows, and the server writes them as they arrive.

The difference grows with the table: one night of sales is a second either way, a year of them is the
difference between a load that finishes and one that does not. **A loader that writes row by row
works in testing and fails in production for no reason anyone can see in the code**. The stock loader
of lesson 3 uses `executemany`, which is right for a file of about a thousand lines a day; at a million
it would be the first thing to change.
