---
title: The five things that go wrong, before any of the rules
version: 2
---

Lesson 2 named the anomalies before it named a normal form, because a rule you cannot see the point
of is a rule you cannot apply. The same order works here. These are the five ways two transactions
running at once produce an answer that neither of them would produce alone.

In each timeline, time runs downwards and the two columns are two connections.

## Dirty read

```localised
T1                                    T2
BEGIN
UPDATE products SET price = 5
                                      BEGIN
                                      SELECT price → 5      ← reads uncommitted work
ROLLBACK                              use the 5 for something
```

T2 read a value that never existed. T1 changed its mind, and the 5 was never true — but T2 has
already printed it, emailed it, or written it somewhere else.

This is the one everybody can name, and it is the one you are least likely to meet: it is forbidden
by default everywhere you will work, and PostgreSQL cannot produce it at all.

## Non-repeatable read

```localised
T1                                    T2
BEGIN
SELECT price → 10
                                      UPDATE products SET price = 12
                                      COMMIT
SELECT price → 12                     ← same row, same transaction, different answer
```

Nothing dirty happened: both values were committed and true when read. But T1 asked the same
question twice inside one transaction and got two answers, so any arithmetic that used both is
arithmetic over two different moments.

It matters most in the shape people do not notice they are writing — a report that runs six queries
and adds their results together. Between query two and query five the world moved, and the total
reconciles with nothing.

## Phantom read

```localised
T1                                    T2
BEGIN
SELECT count(*) FROM orders
  WHERE total > 100     → 12
                                      INSERT INTO orders (total) VALUES (500)
                                      COMMIT
SELECT count(*) FROM orders
  WHERE total > 100     → 13          ← a row appeared inside the range
```

The close relative of the last one, and the difference is worth keeping: a non-repeatable read is
**a row you already saw changing**, and a phantom is **a row you had not seen arriving**. They are
separated because preventing the first is cheap — hold on to the rows you touched — and preventing
the second means locking rows that do not exist yet, which is a harder problem.

## Lost update

```localised
T1                                    T2
BEGIN                                 BEGIN
SELECT stock → 10
                                      SELECT stock → 10
UPDATE SET stock = 9                  (both read 10, both subtract one)
                                      UPDATE SET stock = 9
COMMIT                                COMMIT
```

Two items sold. Stock says nine. One sale vanished and nothing in either transaction was wrong on
its own — each read a true value and wrote a correct consequence of it.

**This is the anomaly you will actually meet**, and it is not in the SQL standard's list of three,
which is part of why it goes unnamed for so long. It comes from the read-modify-write shape, where
a value is fetched into the application, changed there, and written back.

The first fix is to stop doing arithmetic outside the database:

```sql
UPDATE products SET stock = stock - 1 WHERE id = 7;
```

One statement, read and write in the same breath, and two of them run one after another because a
row is locked for the duration of the statement that writes it. The second fix, for when the
decision is genuinely made in the application, is the `locking` section.

## Write skew

```localised
T1                                    T2
BEGIN                                 BEGIN
SELECT count(*) FROM doctors
  WHERE on_call → 2                   SELECT count(*) FROM doctors
                                        WHERE on_call → 2
(two on call, so I may go off)        (two on call, so I may go off)
UPDATE doctors SET on_call = false    UPDATE doctors SET on_call = false
  WHERE id = 1                          WHERE id = 2
COMMIT                                COMMIT
```

Nobody is on call. Each transaction checked the rule, each check was true when it ran, and each
wrote a **different row** — so they never collided, and no lost update occurred.

This is the subtlest of the five and it gets its own section, because it is the one that survives
the isolation level most people assume protects them.

## The five, as one table

| anomaly | what happens |
|---|---|
| dirty read | you see work that was never committed |
| non-repeatable read | a row you read changes underneath you |
| phantom read | a row appears in a range you had already counted |
| lost update | two read-modify-writes, and one overwrites the other |
| write skew | two correct decisions that are wrong together |

Every one of them is a real possibility until something prevents it, and what prevents each is the
next section. Keep the names: the settings are defined in terms of them, so a level you cannot read
becomes a sentence you can.
