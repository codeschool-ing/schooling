---
title: Choosing per operation, not per system
version: 1
---

**The useful question is never "is our system consistent or available?". It is "for this one
operation, what does it cost if two copies disagree for a while, and who pays?"** The same library,
on the same database, gives that question different answers several times a day, and a design that
picks one answer for everything is either slow where it did not need to be or wrong where it could
not afford to be.

The belief to drop is that consistency is a property you buy once, with a database. The previous
section already showed the databases themselves refusing to decide for you: PostgreSQL, DynamoDB and
Cassandra all let the caller choose, per query. The decision has moved into your code, and it is
made one operation at a time.

## The library's operations, one by one

| operation | if two copies disagree | the choice | how, in this lesson's terms |
|---|---|---|---|
| lend the last copy | two members are promised one book | consistency; refuse when unsure | the primary only, with the conditional `UPDATE` |
| pay a fine | money taken twice, or not recorded | consistency, and every ACID letter | one transaction at the primary, refused while the link is down |
| place a hold | two holds arrive in an order nobody saw | availability | accept at any branch; order the queue by time when the link returns |
| show "available" in the online catalogue | the page says 1 for a few seconds after the copy went | latency | read from a replica, or from lesson 8's read model |
| count "popular this week" | a count off by a few | latency, and no transaction at all | a fire-and-forget increment |

Look at what decides each row. Lending and fines are wrong in a way a person has to repair: a phone
call, a refund. Holds are wrong in a way a rule can repair, because a queue ordered by arrival time
gives the same answer whichever branch heard first. **When a rule can settle the conflict without a
person, availability is usually cheap; when only a person can, pay for consistency.** The catalogue
page and the counter are the easy cases: nobody is harmed by a number that is a few seconds old.

The same reasoning applies on one machine, without any network. In `desks.py`, `BEGIN IMMEDIATE`
made every desk wait its turn for the whole file. That is right for lending and wasteful for
recording that somebody opened a page, and SQLite would make the page view queue behind the loan if
both went through the same habit.

## Writing the choice down

A choice made per operation should be visible per operation, beside the code that makes it, so the
next person can see it was a choice. Something as plain as this does the job:

```python
READS = {
    "lend": "primary",             # the last copy must not go out twice
    "pay_fine": "primary",         # money: refuse rather than guess
    "place_hold": "any branch",    # the queue is reordered by time later
    "catalogue_page": "replica",   # a few seconds stale is fine
}
```

Lesson 8 split reads from writes so that each side could be shaped for its job. This lesson adds the
other axis of that split: the write side of a lending library wants consistency, and most of the
read side can trade it for speed. Lesson 12 narrows it once more, to the smallest group of data that
has to change in one transaction, and gives that group a name.
