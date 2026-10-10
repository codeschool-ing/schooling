---
title: Same events, different order, different answer
version: 1
---

**A fold gives the right answer only if it sees the events in the order they happened.** That
sounds obvious, and most people still expect the damage of a reordering to be small and visible:
a number off by one, or an error. The experiment below gives neither. It gives a wrong number that
looks right.

Suppose the Recife stock count, taken at 08:50, reaches the log last instead of first. That is not
far-fetched: the count was typed into a tablet in the stockroom, and the tablet had no signal until
somebody carried it to the front. Make that log by moving the first line to the end, and fold it:

```
ubuntu@stream:~/work$ (tail -n +2 stock.log; head -1 stock.log) > late.log
```

`tail -n +2` is every line from the second, and `head -1` is the first; the parentheses run both
and send them to one file. The eight events in `late.log` are the same eight, byte for byte, and
the answer for Recife is 4 instead of 6. **Nothing failed and nothing warned.** 4 is a plausible
stock, and it is exactly what the count said at 08:50, which is the problem: it is the state of
the shelf at 08:50, applied at the end of the morning, wiping out a delivery and three sales.

The trace shows how it got there:

```
ubuntu@stream:~/work$ python balance.py late.log --trace
```

The second line says Recife had **−1** copies, which no shelf has ever held. A system that reacted
to state as it changed would have reacted to that: a stock alert, an order to the supplier, a
website marking the book unavailable. So a reordering corrupts the answer at the end and every
answer on the way there, and the second is worse, because other systems have already acted on it.

## Which events care about order

Not every pair of events does. A delivery of 6 and a sale of 2 give the same total in either order,
because adding and subtracting **commute**: 4 + 6 − 2 and 4 − 2 + 6 are both 8. A count does not
commute with anything, because it replaces the number instead of moving it.

| applied first | then | result | the other way round |
|---|---|---|---|
| received 6 | sold 2 | +4 | +4, the same |
| counted 4 | sold 1 | 3 | 4, the sale lost |
| counted 4 | received 6 | 10 | 4, the delivery lost |

It is tempting to conclude that events should be designed to commute, and where it is cheap, that
is a good instinct: a total of sales by shop is a sum, and a sum does not care about order. But a
stock count is a real thing that happens in a real shop, and it means *the shelf has 4 now*. Turning
it into an addition would mean the counter has to know the stock before counting, which is the
number the count exists to correct. **Some facts are about absolute values, and those need order.**

The intermediate −1 shows that even commuting events are not entirely safe. The total comes out
right in the end, but a reader who looks in the middle sees a state that never existed. A stream
processor is always in the middle; it never sees the end. Lessons 9 to 11 come back to this from
the other side, with events that arrive late by hours and results that have to be corrected after
somebody has read them.

So order matters. The next section asks how much of it: whether every event in the log has to be
in order with every other, or something much weaker will do.
