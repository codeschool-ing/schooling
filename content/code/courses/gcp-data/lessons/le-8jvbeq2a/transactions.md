---
title: A read-write transaction, and reads that may be a little old
version: 1
---

**Spanner gives a database spread over many machines the transactions of a database on one.** A
read-write transaction reads, decides and writes, and either all of its writes happen or none do,
with the same guarantee whether the rows are on one server or on servers in three regions. Google's
word for the guarantee is **external consistency**: if one transaction commits before another starts,
every reader sees them in that order, everywhere. It is a stronger promise than most distributed
databases make, and it is the reason Spanner exists.

**The wrong idea is that this is free, or slow.** It is neither. Spanner pays for it with a clock:
TrueTime, Google's time service, gives every server the current time with a known bound on its error,
and a commit waits out that bound before it is visible, so that no two commits can be ordered wrongly.
Google documents the bound as a few milliseconds. Across regions the commit also waits for a majority
of the replicas to agree, which is the real cost, and the reason a multi-region instance writes more
slowly than a regional one. **None of the clock can be seen in the emulator**, which has one process
and one clock; what can be practised is the programming model, which is the same.

## Taking stock and writing the order

**Placing an order is the textbook transaction**: read how many bananas are left, refuse if there are
not enough, take them, and write the order, with nobody else able to take the same bananas halfway.

```schooling-example
{"language": "python", "file": "order.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Place one order: check the stock, take it, write the order, in one transaction.\n\n    python3 order.py CUSTOMER PRODUCT UNITS TOTAL_CENTS\n\"\"\"\nimport sys\n\nfrom google.api_core.exceptions import NotFound\nfrom google.cloud import spanner\nfrom google.cloud.spanner_v1 import param_types\n\ndb = spanner.Client(project='planner-dev').instance('quitanda').database('shop')\n", "note": "The docstring says how to run it. `NotFound` is the error Spanner raises when a row's parent does not exist."}, {"code": "customer, product, units, cents = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])\nP = {'c': customer, 'p': product, 'u': units, 'cents': cents}\nT = {'c': param_types.STRING, 'p': param_types.STRING, 'u': param_types.INT64,\n     'cents': param_types.INT64}\n\n", "note": "**Every value reaches the SQL as a parameter**, `@c`, `@p`, `@u` and `@cents`, with its Spanner type, and never pasted into the string."}, {"code": "def place(t):\n    rows = list(t.execute_sql('SELECT Units FROM Stock WHERE Product = @p', params=P, param_types=T))\n    if rows[0][0] < units:\n        raise ValueError(f'{product}: {rows[0][0]} left, {units} asked')\n", "note": "**The read happens inside the transaction**, so the row is locked until the commit and nobody else can take the same units in between. Raising an exception inside the function rolls the transaction back."}, {"code": "    t.execute_update('UPDATE Stock SET Units = Units - @u WHERE Product = @p', params=P, param_types=T)\n    inserted = t.execute_sql(\n        \"INSERT INTO Orders (CustomerId, Day, TotalCents) \"\n        \"VALUES (@c, CURRENT_DATE('America/Sao_Paulo'), @cents) THEN RETURN OrderId\",\n        params=P, param_types=T)\n    return list(inserted)[0][0]\n\n", "note": "**Two writes, one transaction.** The order's `OrderId` comes from the column's `DEFAULT`, the bit-reversed sequence, and `THEN RETURN` hands it back. Both writes become visible together at the commit, or neither does."}, {"code": "try:\n    print('order', db.run_in_transaction(place), 'placed')\nexcept (ValueError, NotFound) as refused:\n    print('refused, nothing written:', str(refused).split(', request_id')[0])\n", "note": "`run_in_transaction` commits when the function returns, and retries it from the start if Spanner aborts it. The message is cut before the request id the client library appends."}]}
```

```
ana@laptop:~/gcp$ python3 order.py c-17 banana 4 2760
order 7773212956841476096 placed
ana@laptop:~/gcp$ python3 order.py c-17 banana 8 5520
refused, nothing written: banana: 6 left, 8 asked
ana@laptop:~/gcp$ python3 order.py c-99 banana 1 690
refused, nothing written: 404 Insert failed because key was not found in parent table:  Parent Table: Customers  Child Table: Orders  Key: {String("c-99")}
```

**Three runs, three outcomes.** The first took four of the ten bananas and wrote order number
`7773212956841476096`, a bit-reversed value from the sequence. The second asked for eight of the six
left and was refused by the program, before anything was written. The third named a customer that
does not exist, so the `INSERT` broke the parent rule of the previous section, and the transaction's
`UPDATE` of the stock, which had already run inside it, was rolled back with it:

```
ana@laptop:~/gcp$ gcloud spanner databases execute-sql shop --instance=quitanda --sql='SELECT CustomerId, OrderId, Day, TotalCents FROM Orders'
CustomerId  OrderId              Day         TotalCents
c-17        7773212956841476096  2026-10-30  2760
ana@laptop:~/gcp$ gcloud spanner databases execute-sql shop --instance=quitanda --sql="SELECT Units FROM Stock WHERE Product = 'banana'"
Units
6
```

**One order, and six bananas**: ten less the four of the first run, and nothing from the third. That
is the all-or-nothing promise, and it held for a write that was refused after other writes in the same
transaction had already succeeded.

## Reads that may be a little old

**A strong read sees every transaction committed before it started**, and it is the default. Spanner
also offers **stale reads**: a read at a timestamp in the past, given exactly or as a bound, which
returns the database as it was at that moment. A stale read does not have to find out whether a more
recent write exists, so any replica that is up to that timestamp can answer it, including one in
another zone or region, without asking the replica that leads the split. That makes it faster and
cheaper wherever the data has replicas far from the reader.

`stale.py`:

```python
#!/usr/bin/env python3
"""Three reads of the same row: strong, at a past timestamp, and a bounded time ago."""
import datetime
import time

from google.cloud import spanner

db = spanner.Client(project='planner-dev').instance('quitanda').database('shop')
SQL = "SELECT Units FROM Stock WHERE Product = 'banana'"


def set_units(n):
    with db.batch() as batch:
        batch.update('Stock', ['Product', 'Units'], [('banana', n)])
    return batch.committed


first = set_units(6)
time.sleep(3)
set_units(40)

reads = {
    'strong': {},
    'at the first commit': {'read_timestamp': first},
    'exactly 2 seconds ago': {'exact_staleness': datetime.timedelta(seconds=2)},
}
for label, options in reads.items():
    with db.snapshot(**options) as snap:
        print(f'{label:<22} {list(snap.execute_sql(SQL))[0][0]}')
```

**It sets the stock twice, three seconds apart, then reads it three ways.** `batch.committed` is the
commit timestamp the first write returned, which is how a program keeps a moment to read at later.

```
ana@laptop:~/gcp$ python3 stale.py
strong                 40
at the first commit    6
exactly 2 seconds ago  6
```

**`strong` saw the second write, and the two stale reads saw the first.** A read 2 seconds ago is
before the second write and after the first, so it returns 6. Quitanda's catalogue pages show how many
units are in stock, and a number fifteen seconds old is good enough there; the checkout, which takes
the units, reads strongly inside its transaction, as `order.py` does.

**Several reads at one moment are a read-only transaction.** A report that reads `Orders` and then
`Stock` and wants them to agree with each other opens one snapshot for both, `db.snapshot(multi_use=True)`
in the Python client, and every read inside it sees the database at the same timestamp. It takes no
locks and blocks no writer, which is why a long report belongs in one rather than in a read-write
transaction, where its reads would hold locks for as long as it ran.

## Where the emulator falls short: one transaction at a time

`two.py`:

```python
#!/usr/bin/env python3
"""Two read-write transactions at once, on different rows. How long does each take?"""
import threading
import time

from google.cloud import spanner

db = spanner.Client(project='planner-dev').instance('quitanda').database('shop')
start = time.monotonic()
first_has_read = threading.Event()
slow_attempts = quick_attempts = 0


def slow(t):
    global slow_attempts
    slow_attempts += 1
    list(t.execute_sql("SELECT Units FROM Stock WHERE Product = 'banana'"))
    first_has_read.set()
    time.sleep(3)
    t.execute_update("UPDATE Stock SET Units = Units + 1 WHERE Product = 'banana'")


def quick(t):
    global quick_attempts
    quick_attempts += 1
    t.execute_update("UPDATE Stock SET Units = Units + 1 WHERE Product = 'rice-5kg'")


def second():
    first_has_read.wait()
    db.run_in_transaction(quick)
    print(f'rice-5kg committed after {time.monotonic() - start:.1f} s, on attempt {quick_attempts}')


other = threading.Thread(target=second)
other.start()
db.run_in_transaction(slow)
print(f'banana committed after {time.monotonic() - start:.1f} s, on attempt {slow_attempts}')
other.join()
```

**Two transactions on two different rows**, which on Spanner lock nothing in common and both commit
in about the three seconds the slower one sleeps:

```
ana@laptop:~/gcp$ python3 two.py
banana committed after 3.0 s, on attempt 1
rice-5kg committed after 7.2 s, on attempt 3
```

**The banana took its three seconds, and the rice took more than seven, on its third attempt.** The
emulator aborted the quick transaction twice while the slow one was open, and the client library
retried it each time, with a pause that grows between attempts. The emulator's documentation lists
this among its limits: it allows one read-write transaction at a time, however unrelated the rows,
and a second one that overlaps it is aborted. Spanner proper would have run both at once and
committed the rice in a fraction of a second. **The lesson to
keep is the retry**, not the delay: `run_in_transaction` re-runs the whole function when a transaction
is aborted, on the emulator and on Spanner alike, so the function must be safe to run twice. Reading
inside the function, as `order.py` does, is what makes it safe; a value read before the transaction
and reused inside it would be the bug.
