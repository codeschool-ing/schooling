---
title: Why a stream needs windows
version: 1
---

**A stream has no total, so every aggregate over it is an aggregate over a slice, and a window is
the rule that says which slice.** Lesson 1 named this as the first thing that changes when the
period never closes. This lesson makes it concrete enough to compute by hand.

The tempting answer is a running total: keep adding, and print the sum whenever somebody asks. It
works, and for some questions it is right; lesson 2's stock per book is exactly that, a fold over
every sale ever. It fails for every question that has a period in it. "Sales this morning",
"sales in the last ten minutes" and "how long did that customer browse" all name a stretch of
time, and a running total has forgotten where any stretch began. Subtracting one running total
from an earlier one works until a late sale arrives and belongs to the earlier side.

A window is a rule that, given an event's time, says which slices it belongs to. **Every window
in this lesson is defined on event time**, the `at` inside the sale, for the reasons lesson 9 spent
itself on: the slice "09:05 to 09:10" means sales that happened then, not sales that arrived then.
Lesson 9's `per_minute.py` already used one without the name: its buckets were windows of one
minute, or of sixty.

## Four shapes

The four kinds differ in two things: whether a slice has a fixed length, and whether slices overlap.

| window | fixed length | overlap | an event belongs to | typical question |
|---|---|---|---|---|
| tumbling | yes | no | exactly one window | sales per five minutes |
| hopping | yes | yes | size ÷ advance windows | sales in the last ten minutes, every five |
| sliding | yes | yes | every window that holds it | the most sales in any five minutes |
| session | no | no | one window per burst of activity | how long each visit lasted |

The lesson takes them in that order, with one program and one fixed list of ten sales, so that
every number can be checked with a pencil. Then it adds keys, because Ponto Final asks most of
these questions per shop, and finishes with the question the program cannot answer on its own:
**when is a window's result final?**

## The ten sales

The same ten sales feed every section. They are listed in the order they arrived, and that
matters in exactly one place:

| # | happened | shop | cents |
|---|---|---|---|
| 1 | 09:00:40 | recife | 3990 |
| 2 | 09:02:10 | natal | 5490 |
| 3 | 09:03:55 | olinda | 2990 |
| 4 | 09:05:00 | recife | 7900 |
| 5 | 09:06:20 | natal | 4490 |
| 6 | 09:12:30 | caruaru | 6200 |
| 7 | 09:13:05 | recife | 3500 |
| 8 | 09:08:50 | natal | 8990 |
| 9 | 09:14:10 | olinda | 2990 |
| 10 | 09:21:00 | recife | 5490 |

Sale 8 happened at 09:08:50 and arrived after sale 7, which happened at 09:13:05: a small version
of Natal's morning in lesson 9. Sale 4 sits exactly on 09:05:00, which is the edge of a
five-minute window and will show where edges go. Everything else is ordinary.
