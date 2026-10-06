---
title: A dimension changes, and the facts do not
version: 1
---

A fact does not change once it has happened. The sale of 8 January 2024 sold one book, at one
price, in one shop, and that stays true forever. **A dimension describes something that goes on
existing**, and it changes: a customer moves, gets promoted to a better loyalty tier, has their name
corrected. The shop's log of such changes, for customer number one:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT changed_at, field, old_value, new_value FROM staging.customer_changes WHERE customer_id = 1 ORDER BY changed_at"
┌──────────────────────────┬─────────┬───────────┬───────────┐
│        changed_at        │  field  │ old_value │ new_value │
│ timestamp with time zone │ varchar │  varchar  │  varchar  │
├──────────────────────────┼─────────┼───────────┼───────────┤
│ 2024-01-08 17:21:54-03   │ tier    │ reader    │ regular   │
│ 2025-01-30 14:20:27-03   │ tier    │ regular   │ patron    │
└──────────────────────────┴─────────┴───────────┴───────────┘
```

A reader until 8 January 2024, a regular until 30 January 2025, and a patron since. Three
descriptions of one person, each true for a while.

Lesson 1 measured what happens when the warehouse keeps only the last one: 1,404 orders of 2024
counted in a state their buyers had not moved to yet. The same thing happens with the tier, and the
tier is a sharper case, because it is *meant* to be analysed: the loyalty programme exists to make
readers into regulars and regulars into patrons, and the manager wants to know what each tier buys.

Kimball called these **slowly changing dimensions**, SCD: dimensions whose attributes change now and
then, not with every transaction. The changes are slow; deciding what to do with them is not, and the
decision is made **per attribute**. A customer's tier, city and name each get their own answer, and
the answers are numbered:

| type | what happens on a change | the past |
|---|---|---|
| 0 | nothing: the original value is kept | frozen at the start |
| 1 | the value is overwritten | rewritten to look like today |
| 2 | a new row is added for the new version | kept, version by version |
| 3 | the old value moves to a "previous" column | one step of it kept |

Types 4 and 6, which section 10 covers, combine these. The rest of this lesson builds each one on
the shop's customers and asks it the same question.
