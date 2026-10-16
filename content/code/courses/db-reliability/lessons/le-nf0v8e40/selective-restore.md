---
title: Getting one table back without restoring the rest
version: 1
---

Most restores in real life are not disasters. They are a mistake: a `DELETE` with the wrong
`WHERE`, run against production at four in the afternoon. The database is fine, the server is
fine, and twelve thousand rows are missing. Restoring the whole dump over the database would
bring them back and **destroy everything written since the dump**, which is usually worse than the
mistake.

Make the mistake. Save a report first, so there is something to compare against afterwards:

```
ana@vm:~$ psql -X -A -t shop -f verify.sql > before.txt
ana@vm:~$ psql shop -c "DELETE FROM orders WHERE customer_id IN (SELECT id FROM customers WHERE city = 'Curitiba')"
DELETE 12500
```

Every order from a customer in Curitiba is gone. The dump from earlier in this lesson still holds
them, and the table of contents makes it possible to take only what is needed, into a database of
its own, without touching the shop:

```
ana@vm:~$ createdb scratch
ana@vm:~$ pg_restore -d scratch -t orders -t customers shop.dump
ana@vm:~$ echo $?
0
ana@vm:~$ psql scratch -c "\d orders"
                          Table "public.orders"
   Column    |           Type           | Collation | Nullable | Default 
-------------+--------------------------+-----------+----------+---------
 id          | bigint                   |           | not null | 
 customer_id | bigint                   |           | not null | 
 total_cents | integer                  |           | not null | 
 placed_at   | timestamp with time zone |           | not null | 
Check constraints:
    "orders_total_cents_check" CHECK (total_cents > 0)
```

`-t` restores the named tables and their rows, and **nothing that hangs off them**: no primary key,
no index, no foreign key, no identity default. The `CHECK` survived because it is part of the
table's definition rather than a separate entry. For a side copy that is exactly right, because
nobody is going to write to it, and a restore of only the data you need is a restore that finishes
sooner.

Now copy the missing rows across. `\copy` is `psql`'s own command: it runs `COPY` on the server and
reads or writes the file on your side of the connection, so it needs no special rights.

```
ana@vm:~$ psql scratch -c "\copy (SELECT o.* FROM orders o JOIN customers c ON c.id = o.customer_id WHERE c.city = 'Curitiba') TO 'curitiba.csv' CSV"
COPY 12500
ana@vm:~$ psql shop -c "\copy orders FROM 'curitiba.csv' CSV"
COPY 12500
ana@vm:~$ psql -X -A -t shop -f verify.sql > after.txt
ana@vm:~$ diff before.txt after.txt && echo identical
identical
ana@vm:~$ dropdb scratch
```

Twelve thousand five hundred rows out of the side copy and into the shop, with their original ids,
and the report says the shop is exactly as it was before the `DELETE`. Then the side copy goes.

## What made that easy, and what usually does not

It worked cleanly because nothing else changed between the dump and the repair. On a real system,
the hours between the last dump and the mistake contain new orders, edits to old ones, and other
rows that point at the deleted ones. **A selective restore brings back the rows as they were at
the dump**, and anything those rows went through afterwards is lost, so the repair is a query
somebody has to write and check rather than a command. The side-by-side copy is what makes that
possible at all: the old rows and the current ones, in two databases, joinable by id.

When the mistake is newer than the last dump, a dump cannot help. Lesson 6 restores the whole
database to the second before the `DELETE`, and does this repair from that instead.
