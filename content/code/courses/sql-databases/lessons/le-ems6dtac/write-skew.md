---
title: Write skew, the one snapshot isolation does not stop
version: 1
---

A hospital rule: **at least one doctor must be on call at all times.** Alice and Bob are both on
call and both want the evening off. The application checks the rule before letting anybody go.

```sql
BEGIN;
SELECT count(*) FROM doctors WHERE on_call;        -- 2, so one may leave
UPDATE doctors SET on_call = false WHERE id = 1;
COMMIT;
```

Correct code. Run it twice at the same time and the ward is empty.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"A timeline of two transactions running side by side, with time running downwards in five numbered steps. In step one, transaction T1 counts the doctors on call and gets two. In step two, transaction T2 runs the same count and also gets two, because it cannot see any change from T1. In step three T1 sets doctor one off call. In step four T2 sets doctor two off call. In step five both commit. Below, a note says that because the two transactions wrote two different rows, their writes never collided and no conflict was detected, yet each check was true when it ran and afterwards nobody is on call.\"><text x=\"44\" y=\"30\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">T1</text>\n<text x=\"380\" y=\"30\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">T2</text>\n<text x=\"16\" y=\"57\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text>\n<rect x=\"44\" y=\"40\" width=\"300\" height=\"34\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"54\" y=\"57\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SELECT count(*) WHERE on_call  =&gt;  2</text>\n<text x=\"16\" y=\"99\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2</text>\n<rect x=\"380\" y=\"82\" width=\"300\" height=\"34\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"390\" y=\"99\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SELECT count(*) WHERE on_call  =&gt;  2</text>\n<text x=\"16\" y=\"141\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text>\n<rect x=\"44\" y=\"124\" width=\"300\" height=\"34\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"54\" y=\"141\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">UPDATE doctors SET on_call=false id=1</text>\n<text x=\"16\" y=\"183\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4</text>\n<rect x=\"380\" y=\"166\" width=\"300\" height=\"34\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"390\" y=\"183\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">UPDATE doctors SET on_call=false id=2</text>\n<text x=\"16\" y=\"225\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">5</text>\n<rect x=\"44\" y=\"208\" width=\"300\" height=\"34\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"54\" y=\"225\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">COMMIT</text>\n<rect x=\"380\" y=\"208\" width=\"300\" height=\"34\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"390\" y=\"225\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">COMMIT</text>\n<line x1=\"14\" y1=\"258\" x2=\"706\" y2=\"258\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n<text x=\"14\" y=\"282\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Two different rows, so the writes never collided</text>\n<text x=\"14\" y=\"304\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Each check was true when it ran. Afterwards, nobody is on call.</text>\n</svg>", "caption": "Two transactions read the same rows, decide separately, and write different rows. No write conflict exists to detect, and the rule they were both checking is broken by the pair."}
```

## Why the obvious defences miss it

**`REPEATABLE READ` does not help.** Each transaction gets a consistent view of the data, and both
views are correct — two doctors really were on call when each of them looked. Snapshot isolation
detects transactions that write the same row. These wrote **different** rows, so there is nothing
to detect.

**Nor does a row lock on what you update.** Row 1 and row 2 are locked by different transactions
and neither waits for the other.

**Nor does a `CHECK` constraint.** A `CHECK` sees one row, and no single row is wrong: doctor 1 off
call is fine, doctor 2 off call is fine. The rule is about the set.

The shape, stated generally:

> **Read a set of rows, make a decision from what you read, then write a row that would have
> changed the decision.** Two transactions do this at once, each acting on a premise the other
> falsified.

## Where you will actually meet it

The doctors are a teaching example. These are not:

- **The last seat.** Count the bookings for a flight, find 199 of 200, insert one. Twice.
- **A balance across several rows.** Sum the transactions on an account, check it stays above zero,
  insert a withdrawal. Twice, from two devices.
- **A uniqueness rule enforced in the application.** `SELECT` to check the username is free, then
  `INSERT`. This is write skew, and it is why that pattern is wrong even inside a transaction.
- **Overlapping bookings.** Check that no reservation overlaps this room and time, then insert one.
  Two people book the same room for half past two.

Every one of them reads as a careful check. Every one of them is two transactions agreeing on a
fact that stops being true because of what the other one did.

## Three fixes, best first

**One — declare the rule.** The username case has an answer you already know from lesson 3: a
unique index. The check-then-insert disappears entirely, you insert and handle the violation, and
the guarantee holds against every connection at every isolation level.

The overlapping-booking case has one too, in PostgreSQL:

```sql
ALTER TABLE reservations ADD CONSTRAINT no_overlap
EXCLUDE USING gist (room_id WITH =, during WITH &&);
```

An exclusion constraint: no two rows may have the same room and overlapping time ranges. It is a
unique index generalised beyond equality, and it is the correct tool for an entire family of these
bugs.

**Two — make the reads conflict.** If the rule cannot be declared, lock what you read so that the
two transactions do collide:

```sql
BEGIN;
SELECT count(*) FROM doctors WHERE on_call FOR UPDATE;
…
```

`FOR UPDATE` locks the rows the `SELECT` returned, so the second transaction waits, and when it
proceeds it sees one doctor on call and refuses. The next section is about this. It works, it is
explicit, and it serialises the shifts of every doctor in the hospital behind one lock, which is a
cost worth seeing.

**Three — `SERIALIZABLE`.** PostgreSQL tracks what each transaction read as well as what it wrote,
and aborts one of a pair whose outcome no serial order could have produced:

```
ERROR:  could not serialize access due to read/write dependencies among transactions
HINT:  The transaction might succeed if retried.
```

It catches all of the shapes above, including the ones you did not think of, which is its real
argument — it is the only fix on this list that works against a bug you have not noticed yet.

The price is in that hint. **The transaction is refused and your application has to run it again**,
which is not optional and is not free to write. The `retrying` section is the other half of
choosing this, and choosing it without the other half means shipping an error page instead of a
bug.
