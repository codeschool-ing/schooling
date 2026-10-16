---
title: Salting a hot key
version: 1
---

**When the small side does not fit in memory, the hot key has to be split by hand.** The trick is
called *salting*: add a second key, a random-looking number from 0 to n−1, to every row of the
large side, and join on both. The crawler's events are then spread over n partitions instead of
one. For every event to still find its visitor, the small side has to contain every visitor once per
salt value, so it is copied n times.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l08-salting\" aria-label=\"Two rows of partitions. Above, without a salt: the crawler v0000000 and all of its 960,905 events go to one partition, together with its one visitor row. Below, with eight salts: the events are split by salt 0 to 7 into eight partitions of about 120,000 each, and the visitor row is copied eight times, once into each of them.\"><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">join key: visitor_id</text><rect x=\"20.0\" y=\"36.0\" width=\"300.0\" height=\"70.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">v0000000</text><text x=\"170.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">960,905 events</text><rect x=\"340.0\" y=\"52.0\" width=\"120.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 visitor row</text><text x=\"20.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">join key: visitor_id + salt</text><rect x=\"20.0\" y=\"154.0\" width=\"80.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"60.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">v0000000 · 0</text><text x=\"60.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">~120,000 events</text><rect x=\"26.0\" y=\"226.0\" width=\"68.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">copy 0</text><rect x=\"106.0\" y=\"154.0\" width=\"80.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"146.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">v0000000 · 1</text><text x=\"146.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">~120,000 events</text><rect x=\"112.0\" y=\"226.0\" width=\"68.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"146.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">copy 1</text><rect x=\"192.0\" y=\"154.0\" width=\"80.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"232.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">v0000000 · 2</text><text x=\"232.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">~120,000 events</text><rect x=\"198.0\" y=\"226.0\" width=\"68.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"232.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">copy 2</text><rect x=\"278.0\" y=\"154.0\" width=\"80.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"318.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">v0000000 · 3</text><text x=\"318.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">~120,000 events</text><rect x=\"284.0\" y=\"226.0\" width=\"68.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"318.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">copy 3</text><rect x=\"364.0\" y=\"154.0\" width=\"80.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"404.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">v0000000 · 4</text><text x=\"404.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">~120,000 events</text><rect x=\"370.0\" y=\"226.0\" width=\"68.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"404.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">copy 4</text><rect x=\"450.0\" y=\"154.0\" width=\"80.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">v0000000 · 5</text><text x=\"490.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">~120,000 events</text><rect x=\"456.0\" y=\"226.0\" width=\"68.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">copy 5</text><rect x=\"536.0\" y=\"154.0\" width=\"80.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"576.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">v0000000 · 6</text><text x=\"576.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">~120,000 events</text><rect x=\"542.0\" y=\"226.0\" width=\"68.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"576.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">copy 6</text><rect x=\"622.0\" y=\"154.0\" width=\"80.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"662.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">v0000000 · 7</text><text x=\"662.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">~120,000 events</text><rect x=\"628.0\" y=\"226.0\" width=\"68.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"662.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">copy 7</text></svg>", "caption": "The large side is split by the salt; the small side is copied once per salt, so every piece still finds its match."}
```

The join of section 02 with eight salts, as `~/big/salting.py`:

```schooling-example
{
  "language": "python",
  "file": "salting.py",
  "parts": [
    {
      "code": "\"\"\"The skewed join of skew.py again, with the hot key spread over eight salts.\"\"\"\nimport time\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nfrom spread import spread\n\nspark = SparkSession.builder.appName(\"salting\").getOrCreate()\nspark.conf.set(\"spark.sql.autoBroadcastJoinThreshold\", -1)\nspark.conf.set(\"spark.sql.adaptive.enabled\", False)\nclicks = spark.read.parquet(\"data/silver/clicks\")\nvisitors = spark.read.parquet(\"data/silver/visitors\")\nSALTS = 8\n\n"
    },
    {
      "code": "salted_clicks = clicks.withColumn(\"salt\", F.pmod(F.xxhash64(\"event_id\"), F.lit(SALTS)))\n",
      "note": "**Each event gets a salt from 0 to 7**, from a hash of its id, so the crawler's 960,905 events become eight groups of about 120,000."
    },
    {
      "code": "salted_visitors = visitors.withColumn(\"salt\", F.explode(F.sequence(F.lit(0), F.lit(SALTS - 1))))\n\nstart = time.time()\nreturning = (salted_clicks.join(salted_visitors, [\"visitor_id\", \"salt\"])\n             .where(F.col(\"day\") > F.col(\"first_day\"))\n             .groupBy(\"device\").count())\nprint(sorted(tuple(row) for row in returning.collect()))\nprint(f\"{time.time() - start:.1f} s\")\nspread(spark)\n",
      "note": "**Each visitor is copied eight times, once per salt**, so that every salted event still finds its visitor. The small side grows eight times; the large side does not grow at all."
    }
  ]
}
```

**The salt comes from a hash of the event's id, not from `rand()`.** A random number would change if
a task were run again after a failure, and the retried task could send a row to a different
partition from the first attempt; a hash of the id gives the same salt every time. `pmod` keeps it
between 0 and 7 when the hash is negative.

```
ana@lab:~/big$ spark-submit salting.py
WARNING: Using incubator modules: jdk.incubator.vector
[('desktop', 4624211), ('mobile', 8687852), ('tablet', 699799)]
44.5 s
stage  tasks       rows read: min     median        max   KiB read: median    max   seconds: median   max
    5    200              182,150    184,362    305,838              2,413  3,245              0.29  2.81
```

| | max rows in a task | median rows | slowest task | job |
|---|---|---|---|---|
| no salt, section 02 | 1,086,798 | 123,862 | 1.72 s | 26.3 s |
| eight salts | 305,838 | 184,362 | 2.81 s | 44.5 s |

**The hot task shrank to under a third, and the job got slower.** Both halves are the price of the
method. The largest partition is now an eighth of the crawler plus its share of everyone else. But
the visitors table went from 1.7 million rows to 13.8 million, every one of them shuffled, and the
median task grew by half to read them.

**Salting pays when the hot task costs more than the copies do.** On this lab the hot task cost under
two seconds, and multiplying a 1.7-million-row table by eight cost eighteen. On a cluster where
the hot task runs for an hour and the rest for a minute, the same arithmetic comes out the other way.
Salt only the keys that are hot, and the copies shrink to almost nothing: the visitors other than the
crawler need one copy each, with salt 0, and only `v0000000` needs eight. That version is a few lines
longer and the one to write in production.
