---
title: Conflicts, and the write that disappears
version: 1
---

PostgreSQL's replica never writes, so it never disagrees with the primary; it can only be behind.
**A system that lets both sides of a partition accept writes** has a harder problem: when the
partition heals, two copies hold two different values for the same thing, each of them a write that
somebody was told had succeeded.

That is the price of choosing availability for writes. A shopping cart is the classic case and the
reason Amazon's Dynamo was built this way: a buyer who cannot add to their cart because a data
centre is unreachable is a lost sale, so the cart accepts the write on whichever side the buyer
reaches, and the system reconciles later.

How it reconciles decides whether a write is lost. This program plays two partitioned writes and
two ways of merging each:

```schooling-example
{"language": "python", "file": "merge.py", "parts": [{"code": "# merge.py\n\"\"\"Two replicas accept writes during a partition. Then the partition heals.\"\"\"\n\n# A cart, kept as one value with the time it was written. Replica B's clock\n# runs 40 ms behind replica A's, which is well within what real clocks do.\na = {\"cart\": ([\"vinyl\"], 10.000)}            # written on A at 10.000 by A's clock\nb = {\"cart\": ([\"poster\"], 10.010 - 0.040)}   # written on B 10 ms LATER, read by B's clock\n\nwinner = max(a[\"cart\"], b[\"cart\"], key=lambda item: item[1])\nprint(\"last write wins:\", winner[0])", "note": "A buyer's cart is written on both sides of a partition: a record on A, and **ten milliseconds later**, a poster on B. Each replica stamps the write with its own clock, and B's is 40 ms slow. When they meet, **last write wins** keeps the write with the larger timestamp."}, {"code": "\n# The same two writes kept as additions to a set, which merges by union.\nprint(\"merge by union: \", sorted(set(a[\"cart\"][0]) | set(b[\"cart\"][0])))", "note": "The same two writes, understood as **adding an item**. Two sets of additions merge by taking everything in either."}, {"code": "\n# A counter of tickets sold. A sells 3 and B sells 2 while they cannot talk.\nplain_a, plain_b = 100 + 3, 100 + 2\nprint(\"one number, last write wins:\", max(plain_a, plain_b), \"sold, after\", 100 + 3 + 2, \"sales\")", "note": "A counter that was 100 before the partition, kept as one number. Each side adds its own sales to its copy, and when they meet only one of the two numbers can survive."}, {"code": "\n# The same counter as one entry per replica; each replica only adds to its own.\ncounts_a = {\"a\": 50 + 3, \"b\": 50}\ncounts_b = {\"a\": 50, \"b\": 50 + 2}\nmerged = {r: max(counts_a[r], counts_b[r]) for r in counts_a}\nprint(\"one entry per replica:\", merged, \"=\", sum(merged.values()), \"sold\")", "note": "The same counter kept as **one entry per replica**, each of which only its own replica ever increases. Merging takes the larger value of each entry, and the total is their sum. Section 09 explains why this cannot lose a sale."}]}
```

```
ana@lab:~/tickets$ python3 merge.py
last write wins: ['vinyl']
merge by union:  ['poster', 'vinyl']
one number, last write wins: 103 sold, after 105 sales
one entry per replica: {'a': 53, 'b': 52} = 105 sold
```

## Last write wins, and the clock that lies

**Last write wins**, LWW, keeps the value with the latest timestamp and discards the other. It is
the most common rule because it is the simplest, and two of its properties are in the first line
of the output:

- **One of the two writes is discarded.** The buyer added a record on one side and a poster on the
  other, and the cart now holds one of them. Nobody is told.
- **"Latest" means latest by somebody's clock.** The poster was written ten milliseconds **after**
  the record, but B's clock runs 40 ms slow, so its timestamp is earlier and **the earlier write
  won**. Clocks on different machines disagree by milliseconds as a matter of course, and by much
  more after a bad synchronisation. LWW turns that disagreement into lost data.

LWW is the right rule only when losing a concurrent write is acceptable, which is the case for a
value that is replaced as a whole and whose last version is the only one anybody wants: a user's
display name, the position of a playhead.

## The counter

The third line is worse because it looks plausible. A counter of tickets sold stood at 100; one
side sold three and the other two. Kept as one number, each side holds its own total, 103 and 102,
and whichever survives **forgets the other side's sales**. The box office reports 103 tickets sold
after selling 105, and every one of the five buyers has a valid ticket.

The fix in the last line, and the union in the second, are the subject of the next section: both
arrive at the right answer without asking which write came last, because they never needed to
know.
