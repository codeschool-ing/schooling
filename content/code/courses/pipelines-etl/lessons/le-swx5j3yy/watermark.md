---
title: The watermark
version: 1
---

"Since the last run" has to be written down somewhere, and **the place it is written is called the
watermark**: the highest `updated_at` the pipeline has already loaded. Ana keeps hers in the
warehouse, one row per source, beside the tables it describes:

```
-- Every version of a row an incremental extraction has seen, with the moment
-- it was extracted. Nothing is ever updated here; a later version is a new row.
CREATE SCHEMA IF NOT EXISTS raw;
CREATE TABLE IF NOT EXISTS raw.orders_changes (
  order_id integer, shop_id integer, customer_id integer, ordered_at timestamptz,
  status text, updated_at timestamptz, extracted_at timestamptz NOT NULL);
CREATE TABLE IF NOT EXISTS raw.customers_changes (
  customer_id integer, name text, email text, city text, state text,
  created_at timestamptz, updated_at timestamptz, extracted_at timestamptz NOT NULL);
CREATE TABLE IF NOT EXISTS etl_state (
  source    text PRIMARY KEY,
  watermark timestamptz NOT NULL);
```

Each night the extraction reads its watermark, asks the source for everything above it, loads the
rows and moves the watermark up to the newest row it loaded:

```schooling-example
{
  "language": "python",
  "file": "incremental.py",
  "parts": [
    {
      "code": "\"\"\"Copy the rows of a shop table that changed since the last run.\"\"\"\nimport sys\n\nimport psycopg\nfrom psycopg import sql\n\n"
    },
    {
      "code": "table = sys.argv[1]                                  # orders or customers\nlookback = int(sys.argv[2]) if len(sys.argv) > 2 else 0   # minutes to re-read\nsource = f\"shop.{table}\" + (f\"+{lookback}m\" if lookback else \"\")\ntarget = sql.Identifier(\"raw\", f\"{table}_changes\" + (f\"_{lookback}m\" if lookback else \"\"))\n\n",
      "note": "One script for any table and any lookback. Each combination keeps its own watermark under its own name, so the lesson can run two of them side by side and compare."
    },
    {
      "code": "with psycopg.connect(\"dbname=wh\") as wh, psycopg.connect(\"dbname=shop\") as shop:\n    wh.execute(sql.SQL(\"CREATE TABLE IF NOT EXISTS {} (LIKE raw.{})\").format(\n        target, sql.Identifier(f\"{table}_changes\")))\n",
      "note": "The target is made in the shape of `raw.orders_changes` if it does not exist yet."
    },
    {
      "code": "    found = wh.execute(\"SELECT watermark FROM etl_state WHERE source = %s FOR UPDATE\",\n                       (source,)).fetchone()\n    since = found[0] if found else None\n\n",
      "note": "**Read the watermark, and lock its row.** `FOR UPDATE` means a second copy of this script started by mistake waits here instead of extracting the same rows at the same time."
    },
    {
      "code": "    shop.execute(\"SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY\")\n    until = shop.execute(sql.SQL(\"SELECT max(updated_at) FROM {}\").format(\n        sql.Identifier(table))).fetchone()[0]\n    query = sql.SQL(\"SELECT *, now() FROM {} WHERE updated_at <= %s\").format(sql.Identifier(table))\n    params = [until]\n    if since is not None:\n        query += sql.SQL(\" AND updated_at > %s::timestamptz - make_interval(mins => %s)\")\n        params += [since, lookback]\n    rows = shop.execute(query, params).fetchall()\n\n",
      "note": "One snapshot of the shop. The new watermark is the newest `updated_at` the snapshot holds, and the query asks for everything after the old one and up to the new one, so the two never disagree about where the window ends."
    },
    {
      "code": "    if rows:\n        insert = sql.SQL(\"INSERT INTO {} VALUES ({})\").format(\n            target, sql.SQL(\", \").join([sql.Placeholder()] * len(rows[0])))\n        wh.cursor().executemany(insert, rows)\n\n",
      "note": "Every row goes in as a new row, with the moment it was extracted. Nothing in `raw` is updated."
    },
    {
      "code": "    wh.execute(\"\"\"INSERT INTO etl_state VALUES (%s, %s)\n                  ON CONFLICT (source) DO UPDATE SET watermark = excluded.watermark\"\"\",\n               (source, until))\n",
      "note": "**The watermark moves in the same transaction as the rows.** Either both are written or neither is, so a crash between them cannot leave a watermark that claims rows the warehouse never got."
    },
    {
      "code": "print(f\"{source}: {len(rows)} rows since {since:%m-%d %H:%M:%S}, watermark now {until:%m-%d %H:%M:%S}\"\n      if since else f\"{source}: {len(rows)} rows, the first run, watermark now {until:%m-%d %H:%M:%S}\")"
    }
  ]
}
```

After two nights:

```
ana@vm:~/etl$ psql -d wh -c "SELECT * FROM etl_state ORDER BY source"
     source      |       watermark        
-----------------+------------------------
 shop.customers  | 2026-03-01 22:21:41-03
 shop.orders     | 2026-03-02 23:59:47-03
 shop.orders+60m | 2026-03-02 23:59:47-03
(3 rows)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l04-watermark\" aria-label=\"Three nights on a line of updated_at times. On the first night the extraction reads everything up to 23:50:30 on 1 March and the watermark is set there. On the second it reads the 261 rows between that watermark and 23:59:47 on 2 March, and the watermark moves to 23:59:47. On the third it reads the 301 rows up to 23:51:38 on 3 March.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M40.0 210.0 L690.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"365.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">updated_at of the shop's orders</text><text x=\"20.0\" y=\"51.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">night 1</text><rect x=\"90.0\" y=\"40.0\" width=\"240.0\" height=\"22.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">17,195 rows</text><path d=\"M330.0 64.0 L330.0 206.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M325.0 198 L335.0 198 L330.0 208 Z\" stroke=\"none\" stroke-width=\"1.2\" fill=\"var(--amber)\"></path><text x=\"330.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 Mar 23:50:30</text><text x=\"20.0\" y=\"101.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">night 2</text><rect x=\"330.0\" y=\"90.0\" width=\"160.0\" height=\"22.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"410.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">261 rows</text><path d=\"M490.0 114.0 L490.0 206.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M485.0 198 L495.0 198 L490.0 208 Z\" stroke=\"none\" stroke-width=\"1.2\" fill=\"var(--amber)\"></path><text x=\"490.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 Mar 23:59:47</text><text x=\"20.0\" y=\"151.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">night 3</text><rect x=\"490.0\" y=\"140.0\" width=\"160.0\" height=\"22.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">301 rows</text><path d=\"M650.0 164.0 L650.0 206.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M645.0 198 L655.0 198 L650.0 208 Z\" stroke=\"none\" stroke-width=\"1.2\" fill=\"var(--amber)\"></path><text x=\"650.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 Mar 23:51:38</text><text x=\"338.0\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">watermark</text></svg>", "caption": "Each night reads the window between the last watermark and the newest row in its snapshot, and the watermark moves only when those rows have been loaded."}
```

## Three choices in that script that are not obvious

**The new watermark comes from the data, not from the clock.** `max(updated_at)` inside the
snapshot is the newest change the extraction actually read. Using the time the job started instead
would claim rows that were not yet visible to it — and the slow till in the next section is
exactly such a row.

**The window is closed at both ends.** The query asks for `updated_at > old` *and*
`updated_at <= new`, where `new` was read in the same snapshot. A row committed a millisecond after
the snapshot is not in it and is above `new`, so the next night picks it up. Without the upper
bound the two could disagree, and a row could be loaded and then skipped.

**The watermark and the rows commit together.** If the load fails, the watermark has not moved and
tomorrow reads the same window again. If the watermark were saved first, a crash between the two
would lose the window for good. **A watermark that runs ahead of the data is a hole nobody can
see**, and keeping both in one transaction is what makes it impossible.
