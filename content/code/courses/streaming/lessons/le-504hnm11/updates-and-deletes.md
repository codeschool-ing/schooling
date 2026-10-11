---
title: Updates, deletes and what the log remembers of a row
version: 1
---

**An update's `before` is only as complete as PostgreSQL's WAL makes it**, and by default the WAL
does not keep the old row. That surprises people who expect a change event to be a diff. Sell a
copy of `bk-02` in Recife, then take `bk-08` out of the Natal shop's range altogether:

```
ubuntu@stream:~/work$ psql pontofinal -c "UPDATE stock SET qty = qty - 1 WHERE shop = 'recife' AND book = 'bk-02'"
```

The snapshot filled offsets 0 to 39 of `pf.public.stock`, so these are 40 onwards. Read three:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic pf.public.stock --partition 0 --offset 40 --max-messages 3 --formatter-property print.key=true
```

Three messages for two statements, and each one says something different:

- **The update, offset 40**: `op` `u`, the new row in `after`, and `before` is `null`. The WAL
  recorded the new row and nothing about the old one, so a reader knows Recife now has 2 copies and
  cannot tell from the event that it had 3.
- **The delete, offset 41**: `op` `d`, `after` is `null`, and `before` has the key and **a `qty` of
  0** — which is not what the row held. With the default setting, the WAL keeps only the key of a
  deleted row; Debezium fills the other columns, declared `NOT NULL`, with a placeholder. A reader
  that sums `before.qty` to work out what was removed gets a wrong number and no error.
- **Offset 42 is a tombstone**: the same key, and a value of `null`. It is not a second delete.

## REPLICA IDENTITY

What the WAL keeps of an old row is a property of the table, its **replica identity**. `DEFAULT`
keeps the primary key's columns, and only for an update that changes the key or a delete. `FULL`
keeps the whole old row, every time:

```
ubuntu@stream:~/work$ psql pontofinal -c "ALTER TABLE stock REPLICA IDENTITY FULL"
```

The same kind of sale again, and now `before` is the row as it was. The difference between `before`
and `after` is the sale itself — Recife went from 2 to 1 — so a consumer can compute what changed
without keeping a copy of the table:

```
ubuntu@stream:~/work$ psql pontofinal -c "UPDATE stock SET qty = qty - 1 WHERE shop = 'recife' AND book = 'bk-02'"
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Offsets 40 to 43 of the topic pf.public.stock, as captured in this lesson. Offset 40, an update with the default replica identity: before is null, after has Recife's bk-02 at qty 2. Offset 41, a delete of Natal's bk-08: before has the key and a qty of 0 that is a placeholder, after is null. Offset 42, a tombstone: the same key and a null value. Offset 43, an update after REPLICA IDENTITY FULL: before has qty 2 and after qty 1.\" data-fig=\"l14-before-after\"><text x=\"98\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">offset 40</text><rect x=\"20\" y=\"45\" width=\"156\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"98\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">update, DEFAULT</text><text x=\"98\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">before: null</text><text x=\"98\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">after: qty 2</text><text x=\"98\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the old row is unknown</text><text x=\"270\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">offset 41</text><rect x=\"192\" y=\"45\" width=\"156\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">delete, DEFAULT</text><text x=\"270\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">before: qty 0</text><text x=\"270\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">after: null</text><text x=\"270\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">placeholder, not the real 3</text><text x=\"442\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">offset 42</text><rect x=\"364\" y=\"45\" width=\"156\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"442\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">tombstone</text><text x=\"442\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">key: natal, bk-08</text><text x=\"442\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">value: null</text><text x=\"442\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">key only: for compaction</text><text x=\"614\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">offset 43</text><rect x=\"536\" y=\"45\" width=\"156\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"614\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">update, FULL</text><text x=\"614\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">before: qty 2</text><text x=\"614\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">after: qty 1</text><text x=\"614\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">the whole old row</text></svg>", "caption": "What each event says about the row before the change depends on the table's replica identity, not on Debezium."}
```

**FULL costs WAL**: every update and delete now writes the
old row as well, which on a wide, busy table is a large share of the database's write volume. Turn
it on for the tables whose consumers need the old values, not for the whole database.

| replica identity | `before` on update | `before` on delete | extra WAL |
|---|---|---|---|
| `DEFAULT` (primary key) | `null` | the key; other columns filled with placeholders | none |
| `FULL` | the whole old row | the whole old row | the old row, on every update and delete |
| `NOTHING` | — | — | none; PostgreSQL refuses the `UPDATE` or `DELETE` itself while the table is in a publication that publishes them |

## Tombstones and compaction

The `null` after the delete is for Kafka, not for you. Lesson 3 showed **compaction**: on a topic
with `cleanup.policy=compact`, Kafka eventually keeps only the latest message for each key. A table
mirrored into a compacted topic is a natural fit — the topic converges to one message per row, the
current one — but a delete event is still a message, so compaction would keep it forever. **A
tombstone, a key with a `null` value, is how a producer tells compaction to drop the key
entirely**, and Debezium writes one after every delete; `tombstones.on.delete=false` turns them off
for topics that are never compacted.

The topics in this lesson were created by the broker with its defaults, so they use
`cleanup.policy=delete`, and the tombstone is just one more message. A consumer has to expect it:
code that does `json.loads(msg.value())["op"]` stops with a `TypeError` on the first `None`.
Compacting the CDC topics, and creating them with the partitions you want before the connector
starts, is what a production setup does, and Connect can do it for you with the
`topic.creation.*` settings. It was not done in this lab.
