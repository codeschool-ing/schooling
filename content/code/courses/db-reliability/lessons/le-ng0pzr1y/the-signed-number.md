---
title: The number somebody signed
version: 1
---

A recovery objective is worth something only if it was agreed **before** the incident, by somebody
with the authority to accept the loss, knowing what it costs to do better. During the incident is the
worst possible time to discover that the business assumed zero and the setup delivers a day.

The agreement fits on one page. For the shop it could look like this:

| system | failure | RPO | RTO | how it is met | last measured | agreed by |
|---|---|---|---|---|---|---|
| orders | disk or server lost | 1 min | 1 h | archive, `archive_timeout` 60 s; nightly differential | drill of 10 Oct: replay 55 s | head of operations |
| orders | a mistaken change | 0 | 4 h | point-in-time recovery to a separate server, repair from the copy | lesson 6 procedure, rehearsed quarterly | head of operations |
| newsletter list | any | 24 h | 3 days | nightly `pg_dump` | restored 2 Oct | marketing lead |

Each column is there for a reason:

- **failure**, because one setup has different numbers for different failures, as the first
  section of this lesson said;
- **how it is met**, because a promise with no mechanism behind it is a wish;
- **last measured**, because the RTO in particular decays as the data grows, and the date says how
  much to trust it;
- **agreed by**, a name, because "the business" does not sign anything. A person does, and that
  person decides, on the day, whether the four hours of a careful repair are worth more than the
  minutes of a fast replacement.

## The cost curve

Tighter numbers cost more, and not linearly. Going from a day of loss to an hour is a setting
(`archive_timeout`, lesson 4). Going from an hour to a few seconds is a streaming receiver or a
replica (lessons 4 and 11). Going from seconds to **zero** needs synchronous replication (lesson
12), which makes every commit wait for a second server and makes the database slower for every user,
every day, to protect against one kind of failure. An RTO follows the same shape: hours is a restore
from backup, minutes is a standby ready to promote, seconds is automatic failover with everything
lessons 15 to 19 bring.

That curve is what to put in front of the person who said "none and none". Not a lecture: three
options, each with its number and its price, and a signature beside the one chosen.
