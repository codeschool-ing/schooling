---
title: The query that no longer fits
version: 1
---

On one database, "the three best-selling products" is a `GROUP BY` with an `ORDER BY` and a `LIMIT 3`.
On two shards, each shard can only answer for its own customers, so the router has to ask both and put
the answers together. The obvious way to do it is to send each shard the same query, `LIMIT 3` included,
and merge the two top threes. `--naive` does exactly that; without it, each shard sends the totals of
every product and the router adds them up:

```
ana@vm:~/lab/shards$ $R top --naive
beans    961
sugar    804
flour    614
ana@vm:~/lab/shards$ $R top
flour    990
beans    961
sugar    804
```

**The naive answer is wrong**, and it does not look wrong. Flour is the best seller overall, with 990
units; the naive version puts it third, with 614. On shard 1, flour was fourth, with 376 units, just
outside that shard's top three, so those 376 units never reached the router. Each shard answered its
own question correctly, and the sum of two correct partial answers was not the answer to the whole
question.

This is the general shape of the problem. **A query that used to be one plan inside one database
becomes a small distributed program**, written by you, and every operation in it has to be rethought:

| on one database | across shards |
| --- | --- |
| `ORDER BY … LIMIT 3` | each shard must send enough to be sure, often everything; the merge is yours |
| `avg(units)` | an average of averages is wrong unless the groups are the same size; send sums and counts |
| a `JOIN` on the shard key | still local, if both tables are sharded by the same key |
| a `JOIN` on anything else | rows from one shard meet rows from all the others, in the router |
| `UNIQUE (email)` | each shard only sees its own rows; two shards can each accept the same e-mail |
| one transaction | a change on two shards is two transactions, and one can fail; lesson 14 |
| page 50 of a sorted list | each shard returns 50 pages so the router can find the 50th |

## What people do instead

Sharding works when **the questions are shaped like the key**, and the rest of the design is about
making that true:

- **Choose the key by the most frequent query**, and accept that the others are slower. Orders by
  customer makes the customer's pages fast and the warehouse's daily list slow, and that is often fine.
- **Keep the data twice, keyed differently.** A small table of order id to customer, sharded by order
  id, turns "find order 1234" into two single-shard queries instead of forty. This is what a database
  means by a **global secondary index**, and keeping it in step with the orders is another eventually
  consistent copy, as lesson 9 described.
- **Send the questions about everybody somewhere else.** The best sellers, the monthly report and the
  search box rarely need to be answered by the shards at all. A copy built for reading, fed by events,
  answers them: lesson 13's read models, lesson 17's search index, or a data warehouse loaded every
  night.

None of this is needed on one database, which is the strongest argument for staying on one database
for as long as it is big enough.
