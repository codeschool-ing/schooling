---
title: The primary key, and the hotspot a counter makes
version: 1
---

**Spanner keeps every table sorted by its primary key and cuts it into ranges of keys, called splits,
which it spreads over its servers.** A split is a contiguous run of rows, from one key to another, and
each split is served by one server at a time, which takes its writes. When a split grows too large or
too busy, Spanner cuts it in two and can move the halves to different servers. That is how one
database spreads over many machines: by key range, with the boundaries chosen and moved by Spanner, on
its own, as the data and the load change.

**The wrong idea is that any unique key will do, as it does in PostgreSQL.** In a single-server
database a key that counts up, 1, 2, 3, is the best key there is: compact, ordered and cheap to index.
In Spanner it is the worst. Every new row has a key greater than every existing one, so every insert
lands at the very end of the table, in the last split, on one server, while the others wait for work.
That is a **hotspot**, and it caps the write rate of the whole table at what one server can take,
however many nodes the instance pays for.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A table cut into four splits by key range, each served by a different server, A to D. Above, with a counter as the key, every new row has the highest key and all of them arrive in split 4, on server D, while A, B and C take no writes. Below, with a UUID or a bit-reversed sequence, new rows arrive in all four splits.\" data-fig=\"l09-hotspot\"><defs><marker id=\"ah-l09-hotspot\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"30\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">key = a counter: 1, 2, 3 …</text><rect x=\"30\" y=\"60\" width=\"155\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"107\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">split 1</text><text x=\"107\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">server A</text><rect x=\"195\" y=\"60\" width=\"155\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"272\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">split 2</text><text x=\"272\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">server B</text><rect x=\"360\" y=\"60\" width=\"155\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"437\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">split 3</text><text x=\"437\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">server C</text><rect x=\"525\" y=\"60\" width=\"155\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"602\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">split 4</text><text x=\"602\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">server D</text><line x1=\"560\" y1=\"140\" x2=\"560\" y2=\"110\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l09-hotspot)\"></line><line x1=\"582\" y1=\"140\" x2=\"582\" y2=\"110\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l09-hotspot)\"></line><line x1=\"604\" y1=\"140\" x2=\"604\" y2=\"110\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l09-hotspot)\"></line><line x1=\"626\" y1=\"140\" x2=\"626\" y2=\"110\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l09-hotspot)\"></line><text x=\"30\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lowest keys</text><text x=\"690\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">every new row: the highest key, one server</text><text x=\"30\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">key = UUID v4 or bit-reversed sequence</text><rect x=\"30\" y=\"205\" width=\"155\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"107\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">split 1</text><text x=\"107\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">server A</text><rect x=\"195\" y=\"205\" width=\"155\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"272\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">split 2</text><text x=\"272\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">server B</text><rect x=\"360\" y=\"205\" width=\"155\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"437\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">split 3</text><text x=\"437\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">server C</text><rect x=\"525\" y=\"205\" width=\"155\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"602\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">split 4</text><text x=\"602\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">server D</text><line x1=\"107\" y1=\"285\" x2=\"107\" y2=\"255\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l09-hotspot)\"></line><line x1=\"272\" y1=\"285\" x2=\"272\" y2=\"255\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l09-hotspot)\"></line><line x1=\"437\" y1=\"285\" x2=\"437\" y2=\"255\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l09-hotspot)\"></line><line x1=\"602\" y1=\"285\" x2=\"602\" y2=\"255\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l09-hotspot)\"></line><text x=\"360\" y=\"297\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">new rows land in every split</text></svg>", "caption": "The same four splits, two kinds of key. Which split serves which keys is drawn for illustration; the emulator has no splits at all."}
```

## Measured on key order, which is what splits are cut from

**The emulator has no splits**, so what can be measured here is the thing splits are cut from: the
order of the keys. The program below writes 800 rows into each of the three key-only tables of the
schema, then 200 more, and asks where the 200 new rows sit in the table's sorted order, quarter by
quarter. On Spanner the quarters would be the neighbourhoods different splits cover, and the question
is whether new rows land in all of them or in one.

```schooling-example
{"language": "python", "file": "keys.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Where do new rows land in a table's key order? Three tables, three kinds of key.\n\nEach table gets 800 rows, then 200 more, and the program counts how many of the\n200 fall in each quarter of the table's key order as it stands afterwards.\n\"\"\"\nfrom google.cloud import spanner\n\ndb = spanner.Client(project='planner-dev').instance('quitanda').database('shop')\n\n", "note": "The client finds the emulator through `SPANNER_EMULATOR_HOST`, from lesson 1's variables, and the instance and database are the ones the previous section created."}, {"code": "NEXT_KEY = {\n    'ByCounter': 'n',\n    'ByUuid': 'GENERATE_UUID()',\n    'BySequence': 'GET_NEXT_SEQUENCE_VALUE(SEQUENCE OrderSeq)',\n}\n\n", "note": "**The three kinds of key, as SQL expressions.** `n` is the counter itself, 1 to 1,000. `GENERATE_UUID()` is Spanner's UUID version 4. The sequence is the bit-reversed one the schema declared."}, {"code": "def insert(table, first, last):\n    sql = (f'INSERT INTO {table} (Id) SELECT {NEXT_KEY[table]} '\n           f'FROM UNNEST(GENERATE_ARRAY({first}, {last})) AS n THEN RETURN Id')\n    return db.run_in_transaction(lambda t: [row[0] for row in t.execute_sql(sql)])\n\n", "note": "**One `INSERT … SELECT` writes a whole batch**, one row per number in `GENERATE_ARRAY`, and `THEN RETURN Id` hands back the keys it wrote. DML runs inside a read-write transaction, which `run_in_transaction` opens and commits."}, {"code": "for table in NEXT_KEY:\n    insert(table, 1, 800)\n    new = set(insert(table, 801, 1000))\n    with db.snapshot() as snap:\n        keys = [row[0] for row in snap.execute_sql(f'SELECT Id FROM {table} ORDER BY Id')]\n    quarters = [sum(k in new for k in keys[q * 250:(q + 1) * 250]) for q in range(4)]\n    print(f'{table:<11} lowest key {str(keys[0]):<36}  new rows per quarter {quarters}')\n", "note": "**800 old rows, then 200 new ones**, then the whole table in key order, which is the order Spanner stores it in. Each quarter is 250 consecutive keys, and the count is how many of the new rows fell in it."}]}
```

```
ana@laptop:~/gcp$ python3 keys.py
ByCounter   lowest key 1                                     new rows per quarter [0, 0, 0, 200]
ByUuid      lowest key 00001fbc-2bb1-4ca4-a8e9-776be37d8b7c  new rows per quarter [49, 54, 48, 49]
BySequence  lowest key 9007199254740992                      new rows per quarter [50, 50, 50, 50]
```

**The counter put all 200 new rows in the last quarter**, past every key that existed. The other two
spread them over the four. A UUID version 4 is 122 random bits, so its new rows land wherever chance
puts them, and the counts differ a little on every run. A **bit-reversed sequence** is a counter whose
bits are written in reverse order, so consecutive numbers land far apart: 1, 2 and 3 become numbers
at the middle of the range, a quarter of the way up and three quarters. Consecutive values spread evenly by
construction, which is the 50, 50, 50, 50.

## The three ways out, and what each costs

| key | where new rows land | what it costs |
|---|---|---|
| a counter, or a timestamp first | the end of the table, one split | the write rate of one server |
| a UUID version 4, `GENERATE_UUID()` | anywhere | 36 bytes as text, and no order to read by |
| a bit-reversed sequence | spread evenly | a number that means nothing, with no order either |

**Both ways out give up the order of creation**, and that is the trade. A query for "the latest
orders" can no longer read the end of the key range; it needs an index on a column such as `Day`,
which is a second table Spanner keeps sorted by that column. An index whose key starts with a
timestamp is a hotspot of its own, so Google's "Schema design best practices" page suggests putting
something before the timestamp in an index too, such as the customer.

**The other way out is to choose a key that is not the creation order at all.** Quitanda's `Orders`
table is keyed by `(CustomerId, OrderId)`, so the first part of the key is the customer: orders from
many customers land in many places, and one customer's orders sit together, which the next section
turns into an advantage. In this lesson `CustomerId` is a readable `c-17`; in production it would be a
UUID, so that new customers spread as well.

**The emulator cannot show any of this go wrong.** A hotspot is a measurement of load on a server, and
there is one server and no load. On Google Cloud the Key Visualizer in the console draws the key
ranges of a table against time, coloured by how busy each is, and a counter key shows there as one
bright line along the top edge. That is the tool to look at in a real instance, and it was not run
here.
