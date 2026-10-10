---
title: Retrying without doing it twice
version: 1
---

**A timeout is not a failure. It is an unknown outcome, and an unknown outcome is safe to retry only
if doing the thing twice has the same effect as doing it once.** That property is called
**idempotence**. Setting dock 4 at Batel to "empty" is idempotent: set it twice and it is still
empty. Adding a fare to a customer's bill is not: add it twice and the customer pays twice.

The wrong picture is that a retry repeats a request that failed. Often the request did not fail at
all. It did its work, and the reply was lost on the way back, which is one of the three silences of
the previous section.

## Retrying well

Three habits make retries safe for the system being retried against:

- wait before trying again, and wait longer each time, doubling the wait on each attempt; this is
  called **exponential backoff**, and it gives a struggling service room to recover;
- add randomness to the wait, called **jitter**, so that a thousand clients that failed at the
  same moment do not all come back at the same moment;
- give up after a few attempts, and say so loudly, rather than retrying for ever.

## Making the write safe to repeat

The program below is a payment service that has a bad network: it records each charge and then loses
the reply, twice in a row, before a third reply gets through. The fare is 450 cents, a price
invented for the example. A client retries with backoff, once against a service that inserts a row
on every request, and once against a service that remembers the **request id** the client sent and
refuses to charge the same id twice. Save it as `retry.py`:

```schooling-example
{"language": "python", "file": "spread/retry.py", "parts": [
{"code": "# spread/retry.py\nimport random\nimport sqlite3\nimport time\n\nrandom.seed(3)\ndb = sqlite3.connect(\":memory:\")\ndb.execute(\"CREATE TABLE charges (request TEXT UNIQUE, ride TEXT, cents INTEGER)\")\n\n\n", "note": "A ledger in memory, with a column for the request id that the database will not let repeat."},
{"code": "def charge(request, ride, cents, safe):\n    if safe:            # a request id the ledger has seen is a repeat, not a charge\n        db.execute(\"INSERT OR IGNORE INTO charges VALUES (?, ?, ?)\", (request, ride, cents))\n    else:\n        db.execute(\"INSERT INTO charges (ride, cents) VALUES (?, ?)\", (ride, cents))\n    if lost.pop(0):     # the charge was made; the reply did not come back\n        raise TimeoutError\n\n\n", "note": "The payment service. Safe or not, it records the charge first and then loses the reply, as long as `lost` says so. The unsafe version inserts a new row every time; the safe one inserts only if the request id is new, in one statement."},
{"code": "for safe in (False, True):\n    print(\"request id checked:\", \"yes\" if safe else \"no\")\n    db.execute(\"DELETE FROM charges\")\n    lost = [True, True, False]\n", "note": "The client, run twice. Each run loses the first two replies and delivers the third."},
{"code": "    for attempt in range(1, 5):\n        try:\n            charge(\"req-0001\", \"R000123\", 450, safe)\n            print(f\"  attempt {attempt}: ok\")\n            break\n        except TimeoutError:\n            wait = 0.1 * 2 ** (attempt - 1) * random.uniform(0.5, 1)\n            print(f\"  attempt {attempt}: no reply, waiting {wait:.2f} s\")\n            time.sleep(wait)\n", "note": "Up to four attempts. After each silence the wait doubles, 0.1 s, 0.2 s, 0.4 s, and is then multiplied by a random factor between a half and one, so that clients which failed together do not all retry together."},
{"code": "    rows, cents = db.execute(\"SELECT count(*), sum(cents) FROM charges\").fetchone()\n    print(f\"  rows in the ledger: {rows}, total {cents} cents\")\n", "note": "What the ledger holds for one ride, after the client was told \"ok\" once."}
]}
```

```
ana@lab:~/roda/spread$ python retry.py
request id checked: no
  attempt 1: no reply, waiting 0.06 s
  attempt 2: no reply, waiting 0.15 s
  attempt 3: ok
  rows in the ledger: 3, total 1350 cents
request id checked: yes
  attempt 1: no reply, waiting 0.07 s
  attempt 2: no reply, waiting 0.16 s
  attempt 3: ok
  rows in the ledger: 1, total 450 cents
```

Both clients saw the same thing: two silences, then `ok`. Without a request id the ledger holds three
charges and 1350 cents for one ride, and nothing in the client's output says so. With one, it holds
one charge of 450 cents.

The work is done by two things together. The client makes up the request id **once**, for the charge
it means to make, and sends the same id on every retry of it; a new id on each attempt would make
every retry look new. And the service lets the database refuse the duplicate: the `UNIQUE` column
and `INSERT OR IGNORE` decide in one statement. Checking first and inserting afterwards would be two
steps, and two retries arriving together can both pass the check before either inserts.

The same idea appears wherever a request might arrive twice. Payment providers commonly accept an
idempotency key with each request for exactly this reason. And lesson 8 meets it from the other
side. A stream consumer that crashes after doing its work, and before recording that it did, reads
the same messages again; writing their results so that a repeat changes nothing is what makes that
harmless.
