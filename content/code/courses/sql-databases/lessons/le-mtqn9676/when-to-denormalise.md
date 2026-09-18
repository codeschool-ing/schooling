---
title: When to break it on purpose
version: 1
---

Denormalisation is putting back a redundancy the forms removed, deliberately, in exchange for
something. It is a real technique and it is the most commonly misused idea in this lesson, because
it is also what somebody says when they did not want to make another table.

The difference is one word: **measured**.

## The trade being made

Every split this lesson performed made writing safer and reading longer. A question that was one
table is now a join, and at some scale, on some query, that cost stops being free.

Denormalisation buys the read back by storing something that could have been computed or followed:

| what you store | instead of | what it costs |
|---|---|---|
| a `comment_count` on the post | counting the comments | every insert and delete must maintain it |
| the author's name on the post | joining to the author | renaming an author touches every post |
| a total on the order | summing the lines | a line changing must update the order |
| a whole pre-built report table | the query that built it | it is stale from the moment it is written |

Every row of that table is a copy of one fact in two places, which is the defect the entire
relational model exists to remove. You are trading a **guaranteed** correctness property for a
**measured** performance one, and the trade is only honest if the measurement is real.

## The test

Before denormalising, all four of these:

**1. Is the query actually slow?** Slow in production, on production-sized data, with a real
execution plan — not slow in somebody's intuition. Lessons 9 and 10 are about how to know. A join
on an indexed foreign key over ten thousand rows is not slow, and a very large share of proposed
denormalisation is aimed at joins that cost less than a millisecond.

**2. Have you tried an index?** Almost every "the join is slow" turns out to be a missing index on
the foreign key. An index is a change nobody has to remember afterwards; a duplicated column is a
change everybody has to remember forever. Lesson 9.

**3. Have you tried the query?** `EXISTS` instead of counting, a narrower `SELECT`, doing it in one
statement instead of in a loop. The N+1 problem in lesson 11 is the single most common cause of
"the database is slow" and it is not fixed by denormalising anything.

**4. Do you know what will keep it correct?** This is the one people skip. If `comment_count` is
stored, *what* increments it — application code, a trigger, a scheduled repair job? What happens
when a comment is deleted by a route nobody remembered? **A denormalised value with no mechanism
keeping it true is not a performance optimisation, it is a bug with a schedule.**

Only past all four is it a decision rather than a reflex.

## And when the answer is yes

It genuinely is, sometimes. The shapes that justify it:

**A count on a very hot read path.** A post's comment count, rendered on every page view, where
counting means scanning a large table. Maintained by a trigger, because a trigger cannot be
forgotten by the next program to write a comment.

**A total that is part of a document.** An invoice's total, stored on the invoice. This one is
usually not really denormalisation — see the next section — but it is where the argument starts.

**A reporting table rebuilt on a schedule.** Analytics against a normalised transactional schema is
often genuinely too slow, and the answer is a separate table, or a separate database, rebuilt
nightly. **The key property is that nothing writes to it by hand**: it is derived, wholly, by a job
that can be run again. Being rebuilt is what makes it safe to be redundant.

**A materialised view**, which is the database's own name for that idea and is worth knowing
exists: a query whose result is stored and refreshed on command. Lesson 7.

## What makes it defensible

Whatever you denormalise, three things:

**Write down that it is derived.** In a comment on the column, in the migration, somewhere a person
will see. A column that looks authored and is actually derived is a trap for the next person, who
will update it by hand and be right to think that was allowed.

**Have one mechanism that maintains it, and only one.** A trigger, or one code path that everything
goes through. Two mechanisms is the state in which they disagree.

**Be able to rebuild it from the truth.** If `comment_count` can be recomputed by counting, you can
check it, repair it, and prove the drift. If it cannot be recomputed, it is not derived — it is a
second source of truth, and you no longer have a database, you have two.

## The order, one last time

> **Normalise first. Measure. Then, if the measurement says so, denormalise the specific thing the
> measurement pointed at, and write down how it stays true.**

Denormalising before measuring is not a performance decision at all. It is the anomalies from the
start of this lesson, chosen on purpose, in exchange for nothing.
