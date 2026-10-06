---
title: Fake
version: 1
---

A **fake** is a working implementation of a collaborator that takes a shortcut production cannot
take: it keeps data in memory instead of a database, writes files to a temporary folder instead of
cloud storage, or delivers e-mail into a list instead of an SMTP server. Unlike a stub, it has real
behaviour. Ask it twice and it remembers the first time.

`shipquote`'s fake stands in for the table where orders are stored:

```python
class FakeOrders:
    """Orders kept in a list: the real table's behaviour, without the table."""

    def __init__(self):
        self.rows = []

    def add(self, email, cents):
        self.rows.append((email, cents))
        return len(self.rows)
```

It keeps rows in a list and hands out ids starting at 1, the way an `INTEGER PRIMARY KEY` would.
That is enough for `place`, which only needs `add` to store an order and return its id. The test
of the refusal from section 03 reads `orders.rows` afterwards to check nothing was stored, which a
stub could not offer, because a stub does not keep anything.

## Why a fake, and not the real table

The real table would work: lesson 1's integration tests already use SQLite in a temporary
directory. But `place` is about the order of two actions, store then notify, and the rule that a
refusal does neither. None of that depends on SQL. A fake keeps those tests in the fast layer and
makes them independent of a schema they do not exercise.

**A fake is code, and code can be wrong.** If `FakeOrders.add` returned ids starting at 0, tests
using it would pass while production behaved differently. The defence is the same one section 10
applies to stubs: **run the same tests against the fake and the real implementation**, so they are
kept in agreement by something other than memory. For a store, that means a small set of tests,
parametrised over both, asking what every implementation must do: an added order can be found, the
first id is 1, two orders get two ids.

## Fakes worth knowing about

Some fakes are so common they ship as products:

| real collaborator | well-known fake |
|---|---|
| an SMTP server | a local server that keeps messages for inspection (MailHog, Mailpit) |
| cloud object storage | a local server speaking the same API (MinIO for S3) |
| a relational database | the same engine in a container, started per test run |
| the clock | a clock object the test advances by hand |

The last row comes back in lesson 3: `shipquote`'s dispatch rule depends on the time, and a test
that depends on the real clock passes or fails with the hour of the day.
