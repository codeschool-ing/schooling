---
title: State is what the log adds up to
version: 1
---

**The current state of anything is the result of applying its events, in order, to an empty
start.** The stock of a book in a shop is the last count, plus every delivery since, minus every
sale since. A program that keeps that number in a table is keeping a running answer to a question
it could always answer again from the log. Functional programmers call this a **fold**: walk a
list, carrying one value, and change the value at each element.

Ponto Final counts the shelves before the shops open. Here is the morning in Recife and Olinda for
one book, as events. Save it as `~/work/stock.log`:

```json
{"type": "stock-counted", "id": "rec-count-0302", "at": "2026-03-02T08:50:00-03:00", "shop": "recife", "book": "bk-03", "qty": 4}
{"type": "stock-counted", "id": "oli-count-0302", "at": "2026-03-02T08:52:00-03:00", "shop": "olinda", "book": "bk-03", "qty": 2}
{"type": "book-sold", "id": "rec-000004", "at": "2026-03-02T09:00:41-03:00", "shop": "recife", "book": "bk-03", "qty": 1}
{"type": "book-sold", "id": "oli-000009", "at": "2026-03-02T09:02:10-03:00", "shop": "olinda", "book": "bk-03", "qty": 2}
{"type": "stock-received", "id": "rec-recv-0117", "at": "2026-03-02T09:30:00-03:00", "shop": "recife", "book": "bk-03", "qty": 6}
{"type": "book-sold", "id": "rec-000031", "at": "2026-03-02T09:41:56-03:00", "shop": "recife", "book": "bk-03", "qty": 2}
{"type": "stock-received", "id": "oli-recv-0118", "at": "2026-03-02T09:45:00-03:00", "shop": "olinda", "book": "bk-03", "qty": 3}
{"type": "book-sold", "id": "rec-000040", "at": "2026-03-02T09:52:13-03:00", "shop": "recife", "book": "bk-03", "qty": 1}
```

Each line is one event, which is exactly the format `minilog.py` writes, so this file is a log the
last section's code can read. Three kinds of event: a **count** says how many copies are on the
shelf, a **delivery** adds copies and a **sale** takes them away.

The program that folds it reads the log with `minilog.py`'s own `read`, so keep both files in
`~/work`. Save this as `~/work/balance.py`:

```schooling-example
{
  "file": "balance.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"balance.py: the stock of each book in each shop, folded from a log of events.\n\n    python balance.py LOG [--trace]\n\"\"\"\nimport json\nimport sys\n\nfrom minilog import read\n",
      "note": "`read` is imported from the previous section's file, so this program reads the log exactly as any other reader does."
    },
    {
      "code": "\ndef apply(stock, event):\n    key = (event[\"shop\"], event[\"book\"])\n    if event[\"type\"] == \"stock-counted\":\n        stock[key] = event[\"qty\"]\n    elif event[\"type\"] == \"stock-received\":\n        stock[key] = stock.get(key, 0) + event[\"qty\"]\n    elif event[\"type\"] == \"book-sold\":\n        stock[key] = stock.get(key, 0) - event[\"qty\"]\n    return key\n",
      "note": "**One event, one change.** A count replaces the number; a delivery and a sale move it. The key is the pair of shop and book, so Recife's copies and Olinda's are separate rows."
    },
    {
      "code": "\nstock = {}\nfor offset, line in read(sys.argv[1], 0):\n    key = apply(stock, json.loads(line))\n    if \"--trace\" in sys.argv:\n        print(f\"{offset:>2}  {key[0]:<7} {key[1]}  {stock[key]:>3}\")",
      "note": "The fold: an empty table, every event from offset 0, and with `--trace` the row each event changed, as it was after the change."
    },
    {
      "code": "for (shop, book), qty in sorted(stock.items()):\n    print(f\"{shop:<7} {book}  {qty:>3}\")",
      "note": "The table at the end: one row per shop and book."
    }
  ]
}
```

Run it:

```
ubuntu@stream:~/work$ python balance.py stock.log
olinda  bk-03    3
recife  bk-03    6
```

Recife counted 4, sold 1, received 6, sold 2 and sold 1, and has 6. Olinda counted 2, sold 2 and
received 3, and has 3. Nothing stored those two numbers; they were worked out from the eight
events, and they will be worked out the same way every time the program runs.

## A table and a stream are two views of one thing

Now ask for the trace:

```
ubuntu@stream:~/work$ python balance.py stock.log --trace
 0  recife  bk-03    4
 1  olinda  bk-03    2
 2  recife  bk-03    3
 3  olinda  bk-03    0
 4  recife  bk-03    9
 5  recife  bk-03    7
 6  olinda  bk-03    3
 7  recife  bk-03    6
olinda  bk-03    3
recife  bk-03    6
```

Each trace line is one change to the table: at offset 4, the row `recife bk-03` became 9. Read the
trace top to bottom and you have **a stream of changes**; keep only the last line for each key and
you have **the table**. That is the idea people call the **stream–table duality**, and it runs both
ways:

- a **table is a stream folded up**: apply the changes in order and keep the latest value per key;
- a **stream is a table's history**: write down every change to the table, in order, and you have
  a log from which the table can be rebuilt.

Both directions turn up later as tools. Kafka can keep only the latest record per key in a topic,
which turns a stream into a table on disk (lesson 3, compaction). Kafka Streams calls a folded
stream a `KTable` and backs it with exactly such a log (lesson 13). And change data capture reads a
database's own record of its changes and turns its tables back into streams (lesson 14).

## The table is a cache

**If the log is kept, the table can be thrown away**, because running the fold again rebuilds it.
That changes what a bug costs. A stock system that subtracted returns instead of adding them has a
wrong table, and in a system that only kept the table, the right numbers are gone. With the log,
the fix is to correct `apply` and fold again from offset 0.

The reverse does not hold. From `recife bk-03 6` nobody can say whether that was 4 − 1 + 6 − 2 − 1
or a fresh count of 6, or which sale happened when. **The events contain the state; the state does
not contain the events.** The price of that is space, since the log grows with every sale while the
table stays one row per book, and lesson 3 is where Kafka decides how much of a log to keep.
