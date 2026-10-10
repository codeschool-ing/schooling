---
title: What the screen did not say
version: 1
---

**The rule's fourth sentence says an order holds between one and six tickets.** From the outside, Lia
tested it the black-box way, at both edges: seven tickets, one too many, and no tickets at all, one too
few.

```
lia@lab:~/aurora$ python orders.py sat 15:00 35 35 35 35 35 35 35
refused: an order holds 1 to 6 tickets
lia@lab:~/aurora$ python orders.py sat 15:00
refused: an order holds 1 to 6 tickets
```

Both refused, with a clear message. By the screen, the rule holds. A black-box tester would mark both
cases as passed and move on.

## Looking inside

```
lia@lab:~/aurora$ python -m sqlite3 aurora.db "SELECT * FROM orders"
(1, 'thu 20:00', 3, 9000)
(2, 'sat 15:00', 2, 5600)
(3, 'sat 15:00', 7, 0)
(4, 'sat 15:00', 0, 0)
```

**Two more rows than there are orders.** Order 3 is the refused seven-ticket order, and order 4 is the
refused empty one, both stored with a total of zero. The screen said *refused*; the database says an order
for seven tickets exists.

Now read `place` in `orders.py` again, knowing what to look for. The first thing it does is write the row.
Only after that does it check the number of tickets, and when the check fails it returns the message
without removing what it wrote. Because every statement saves at once, the row stays.

## Why this matters to somebody outside

A row with a total of zero looks harmless. Whether it is depends on who reads the table, and that is
architecture knowledge, not code. At Cine Aurora, the nightly report that tells Célia how many seats are
left in each session adds up the `tickets` column:

```
lia@lab:~/aurora$ python -m sqlite3 aurora.db "SELECT session, sum(tickets) FROM orders GROUP BY session"
('sat 15:00', 9)
('thu 20:00', 3)
```

**The Saturday matinée shows nine seats sold.** Two were sold. The other seven belong to an order that was
refused. On a busy day the shop would stop offering seats that are free, and on a quiet one Célia would
plan staff for a crowd that never bought anything. Lesson 2's question about what stops a room being sold
past its capacity has a mirror image here: something that makes a room look fuller than it is.

## What found it

Not black box: the screen was right both times. Not white box on its own either: reading `place` shows
the order of the two steps, but not that a report somewhere adds up the column. **What found it was acting
as a customer and then checking where the consequences land**, which needed exactly two facts about the
architecture: that orders are stored in a table, and that a report reads it.

The defect report Lia wrote had the grey-box shape, and it is worth copying:

> Refused orders are stored. `python orders.py sat 15:00` followed by seven ages prints *refused*, and
> `SELECT * FROM orders` then shows an order of 7 tickets with a total of 0. The seats report counts them:
> the Saturday matinée shows 9 seats sold where 2 were. Expected: a refused order leaves no row.

Three commands, one expected result, and the consequence for a person who reads the report. That is the
whole case.
