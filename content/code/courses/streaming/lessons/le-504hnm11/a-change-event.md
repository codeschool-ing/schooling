---
title: What a change event says
version: 1
---

**Every message Debezium writes is an envelope: the row before, the row after, what happened, and
where in the database it happened.** The first ones in `pf.public.stock` are not changes at all.
When a connector starts with an empty slot it takes a **snapshot**: it reads every row the
published tables hold, in one consistent transaction, and writes each as an event, so a reader of
the topic starts with the whole table rather than only with what changes from now on. Read the
first one, and let `jq` lay it out:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic pf.public.stock --from-beginning --max-messages 1 | jq .
```

The fields, from the top:

| field | what it holds |
|---|---|
| `before` | the row as it was; `null` here, because a snapshot has nothing before it |
| `after` | the row as it is now: Recife holds three copies of `bk-01` |
| `source` | where it came from: the connector's version, the database, schema and table, the transaction id and the **LSN**, its position in the WAL |
| `source.snapshot` | `first_in_data_collection` on the first row of a table's snapshot, `true` on the rest, `last` on the very last, and `false` on everything that comes after |
| `op` | what happened: `r` for a snapshot read, `c` create, `u` update, `d` delete |
| `ts_ms` | when Debezium processed it, in milliseconds since 1970; `source.ts_ms` is when the database did |

**The two `ts_ms` are event time and processing time**, lesson 9's two clocks, one inside the other.
The difference between them is how far behind the connector is running. Their values on your
machine are different from these, as are `txId` and `lsn`, and nothing in this lesson depends on
them.

## The key

The message's value is the envelope. Its **key** is the row's primary key, on its own:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic pf.public.stock --from-beginning --max-messages 3 --formatter-property print.key=true --formatter-property print.value=false
```

Everything that ever happens to Recife's `bk-01` has that key, so it goes to the same partition and
is read in the order it was committed. A consumer that keeps the latest `after` for each key holds a
copy of the table; that is lesson 2's table–stream duality, with PostgreSQL as the table.

## A change as it happens

The snapshot is history. Now make a change and watch it arrive. A new book reaches the catalogue:

```
ubuntu@stream:~/work$ psql pontofinal -c "INSERT INTO books VALUES ('bk-09', 'Iracema', 3290)"
```

`books` had eight rows, so its snapshot took offsets 0 to 7 and the insert is offset 8. Read that one
message and only the fields that matter here:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic pf.public.books --partition 0 --offset 8 --max-messages 1 | jq -c '{op, before, after}'
```

`op` is `c`, `before` is `null` because the row did not exist, and `after` is the row as inserted.
**Nothing in the website's code mentions Kafka**, and nothing has to: the `INSERT` could have come
from a migration, a person at a `psql` prompt or a program written ten years ago, and it would be
on the topic just the same. That is the dual write closed — there is one write, and the event is
derived from the database's own record of it.

Notice the price, which is `cents` as an integer. The JSON converter writes what PostgreSQL's
`integer` holds. A `numeric` column would arrive by default as a base64-encoded byte string,
Debezium's way of keeping its exact precision; the connector's `decimal.handling.mode` can make it
a string or a double instead. **It is the first thing to check when a column looks like garbage on
the topic**, and the reason money in this course is always integer cents.
