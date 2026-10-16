---
title: The order that disappeared
version: 1
---

Let the frozen process carry on, as the suspended machine would when its host resumes it:

```
ana@vm:~$ pkill -CONT -f 'patroni/pg1[.]yml'
ana@vm:~$ patronictl -c ~/patroni/pg1.yml list
+ Cluster: shop (7697125163435731023) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Replica | streaming |  2 |         0 |
| pg2    | 127.0.0.1:5442 | Leader  | running   |  2 |           |
| pg3    | 127.0.0.1:5443 | Replica | streaming |  2 |         0 |
+--------+----------------+---------+-----------+----+-----------+
ana@vm:~$ grep -h -E "demot|rewind" ~/patroni/pg1.log | tail -n 4
2026-10-16 01:58:31,184 INFO: pg_rewind exit code=0
2026-10-16 01:58:31,184 INFO:  stderr=pg_rewind: servers diverged at WAL location 0/4C4EF30 on timeline 1
pg_rewind: rewinding from last common checkpoint at 0/2000110 on timeline 1
pg_rewind: Done!
ana@vm:~$ psql -h 127.0.0.1 -p 5441 -U postgres -XAt shop -c "SELECT id, customer_id FROM orders WHERE id > 50000 ORDER BY id"
50029|72
```

Patroni woke up, found that the leader key named `pg2`, and did the right thing from there:
demoted its PostgreSQL, **rewound it** to where the two histories split, and made it a replica of
`pg2`. The cluster is healthy again, three nodes on timeline 2.

The last query is the cost. On `pg1` there is one order above 50000 now: `pg2`'s. **Order 50001,
which `pg1` accepted and confirmed to the application, is gone.** `pg_rewind` did its job, and its job
is to throw away whatever the old primary wrote after the split. Nothing reported it, nothing put it
anywhere, and the customer who placed it was told it succeeded.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A timeline from left to right with three lanes. Top lane, pg1's Patroni: running, then frozen from the freeze until the thaw. Middle lane, pg1's PostgreSQL: primary the whole time until the thaw, then rewound into a replica. Bottom lane, pg3: replica until the leader key expires about 30 seconds after the freeze, then primary. Between the key's expiry and the thaw, both pg1 and pg3 are primaries; that stretch is marked two primaries, and the writes pg1 takes in it are discarded by the rewind.\"><defs><marker id=\"l17w-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">pg1's Patroni</text><text x=\"20\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">pg1's PostgreSQL</text><text x=\"20\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">pg3</text><rect x=\"160\" y=\"40\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"210.0\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">running</text><rect x=\"260\" y=\"40\" width=\"300\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"410.0\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">frozen</text><rect x=\"560\" y=\"40\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">running</text><rect x=\"160\" y=\"100\" width=\"400\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">primary</text><rect x=\"560\" y=\"100\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">replica</text><rect x=\"160\" y=\"160\" width=\"240\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">replica</text><rect x=\"400\" y=\"160\" width=\"300\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"550.0\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">primary</text><path d=\"M260 22 L260 38\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M260 72 L260 98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M260 132 L260 158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M260 192 L260 202\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"260\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">freeze</text><path d=\"M400 22 L400 38\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M400 72 L400 98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M400 132 L400 158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M400 192 L400 202\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"400\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">key expires</text><path d=\"M560 22 L560 38\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M560 72 L560 98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M560 132 L560 158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M560 192 L560 202\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"560\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">thaw</text><path d=\"M402 214 L558 214\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17w-am)\" marker-start=\"url(#l17w-am)\"></path><text x=\"480.0\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\" font-weight=\"600\">two primaries</text><text x=\"480.0\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">rewound: its writes discarded</text></svg>", "caption": "A frozen Patroni and a working PostgreSQL. Between the key's expiry and the thaw, two servers take writes, and the rewind afterwards throws away the old primary's."}
```

That is split-brain's real price, and it is worse than an outage: **a confirmed write, silently
lost**, which no monitoring screen shows and which surfaces weeks later as a customer with a receipt
for an order the shop never had. Its lines are still in the old primary's log until the rewind
removes them, and the only way to recover them afterwards would have been to save a copy of the
old primary's data directory before letting it rejoin.
