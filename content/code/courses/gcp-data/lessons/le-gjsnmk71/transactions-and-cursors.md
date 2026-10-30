---
title: Transactions, and pages read with a cursor
version: 1
---

**A Firestore transaction reads documents, decides, and writes, and its writes happen together or
not at all.** The rule that makes it safe is the one lesson 9's Spanner taught: read inside the
transaction, never before it, because the client library may run the function again. In Firestore it
is stricter still: every read in a transaction has to come before its first write, and a transaction
that finds another one has changed what it read is retried from the start, with the value as it now
is.

**The wrong idea is that a counter needs no transaction.** Reading the stock, subtracting and writing
it back looks like one step and is three, and two customers doing it at the same moment both read
10, both write 4, and twelve bananas leave a shop that had ten. A transaction is how two of them can
try and only one succeed.

## The last ten bananas

`stock.py`:

```python
#!/usr/bin/env python3
"""Two customers try to buy 6 of the last 10 bananas at the same moment."""
import threading

from google.cloud import firestore

db = firestore.Client(project='planner-dev')
stock = db.collection('stock').document('banana')
stock.set({'units': 10})
attempts = {'c-17': 0, 'c-18': 0}


@firestore.transactional
def buy(transaction, customer, units):
    attempts[customer] += 1
    left = stock.get(transaction=transaction).get('units')
    if left < units:
        return f'{customer}: refused, {left} left'
    transaction.update(stock, {'units': left - units})
    transaction.set(db.collection('customers').document(customer).collection('orders').document(),
                    {'product': 'banana', 'units': units})
    return f'{customer}: bought {units}, {left - units} left'


def shopper(customer):
    print(buy(db.transaction(), customer, 6), f'(attempt {attempts[customer]})')


threads = [threading.Thread(target=shopper, args=(c,)) for c in attempts]
for t in threads:
    t.start()
for t in threads:
    t.join()
print('units now', stock.get().get('units'))
```

**Two threads, two customers, six bananas each, ten in stock.** Each runs the same transaction, and
`attempts` counts how many times the function ran for each:

```
ana@laptop:~/gcp$ python3 stock.py
c-18: bought 6, 4 left (attempt 3)
c-17: refused, 4 left (attempt 4)
units now 4
ana@laptop:~/gcp$ python3 stock.py
c-18: bought 6, 4 left (attempt 1)
c-17: refused, 4 left (attempt 2)
units now 4
```

**Each run, one customer bought six and the other was refused, with four left.** In the first run
the two transactions collided more than once: each read ten, found at commit time that the other
had touched the same document, and was run again, until `c-18` committed on its third attempt and
`c-17`, on its fourth, read four and refused. In the second run `c-18` committed at once and `c-17`
needed one retry. Which customer wins, and after how many attempts, is a matter of timing. **The stock never went below zero**, and that is the whole point:
the arithmetic is right on every interleaving, not only on the lucky one.

**Server client libraries, which Python's is, take locks** on what a transaction reads, which is how
the second transaction learnt that its read had gone stale; Google's documentation describes the
mobile and web SDKs as optimistic instead, retrying when the commit finds a conflict. Both retry, and
the same rule covers both: the function must be safe to run twice.

**A document that every order writes is a hotspot of its own.** Firestore documents a sustained rate
of about one write per second to a single document. A stock counter written by every order at the
evening peak is past that, which is why a high-traffic counter is spread over several documents,
**distributed counters** in Google's own guide, that a read adds up.

**A batch is the transaction without the reads.** `seed.py` wrote seventy-three documents in one
batch, and they became visible together, all or none, which is everything a transaction promises
about writes. What a batch cannot do is read: there is nothing to decide with, so it never needs a
retry and never meets contention over what it read. Writes that do not depend on what is currently
stored, such as loading the day's new products, belong in a batch; anything that reads before it
writes, such as the stock, needs the transaction.

## Pages, with a cursor and not an offset

**A query reads in index order, so a page is a position in the index.** The way to ask for the next
page is to hand Firestore the last document of the previous one, a **cursor**, and say "start after
this". The index is then read from that point, and nothing before it is touched.

`pages.py`:

```python
#!/usr/bin/env python3
"""Page through every order, ten at a time, with a cursor."""
from google.cloud import firestore

db = firestore.Client(project='planner-dev')
query = db.collection_group('orders').order_by('day').order_by('total_cents').limit(10)

page, last = 1, None
while True:
    docs = list((query.start_after(last) if last else query).stream())
    if not docs:
        break
    print(f'page {page}: {len(docs):>2} orders, {docs[0].get("day")} to {docs[-1].get("day")}')
    page, last = page + 1, docs[-1]
```

```
ana@laptop:~/gcp$ python3 pages.py
page 1: 10 orders, 2026-10-02 to 2026-10-05
page 2: 10 orders, 2026-10-05 to 2026-10-11
page 3: 10 orders, 2026-10-11 to 2026-10-15
page 4: 10 orders, 2026-10-15 to 2026-10-18
page 5: 10 orders, 2026-10-21 to 2026-10-27
page 6:  3 orders, 2026-10-28 to 2026-10-29
```

**Fifty-three orders in six pages**, each page starting where the last ended. The query orders by
`day` and then `total_cents`, so that two orders on the same day still have a fixed order and the
cursor knows exactly where it stopped. On Google Cloud two order-bys are a composite index of their
own, and the emulator, as the previous section found, did not ask for it.

**An offset is the other way to page, and it is billed.** `offset(40).limit(10)` returns ten documents
and, by the pricing page's own example, charges a read for each skipped document as well: page five
costs fifty reads instead of ten, and page one hundred a thousand. A cursor costs ten reads on every
page. The emulator returns the same documents either way, and there is no bill on the laptop to show
the difference, which is why it is written down here rather than measured.
