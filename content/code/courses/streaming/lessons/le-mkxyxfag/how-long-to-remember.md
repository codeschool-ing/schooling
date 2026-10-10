---
title: How long to remember an id
version: 1
---

**A table of processed ids grows by one row per event, for ever, unless something deletes from
it, and deleting from it reopens the door to the duplicates it was there to stop.** So every
deduplication has a window, chosen or not: the length of time an id is remembered. A duplicate
that arrives inside the window is caught; one that arrives after it is applied again.

After the crash in the second section, the table held one row for every sale ever applied:

```
ubuntu@stream:~/work$ python -m sqlite3 stock.db "SELECT count(*) FROM processed"
```

@@REMEMBER@@

Forty rows is nothing. Put numbers on Ponto Final instead: five shops at, say, two thousand sales a
day each is ten thousand ids a day, three and a half million a year. A sale id is ten characters;
with SQLite's own overhead and the index that makes the primary key work, call it fifty bytes a
row, so under 200 MB a year. That fits on any disk and would be fine to keep. A system with a
thousand times the traffic would hold 200 GB of ids and, worse, look one up on every event.

## Where duplicates actually come from

The window should be as long as the longest delay with which a duplicate can still arrive, and
that delay depends on what produces the duplicate:

| source of a duplicate | how late it can arrive |
|---|---|
| a producer retry after a lost acknowledgement | seconds, inside `message.timeout.ms` |
| a consumer crash between effect and commit | as long as the consumer is down |
| a rebalance that moves a partition mid-batch | seconds |
| a replay of the topic after a bug fix | as far back as the replay goes, up to retention |
| a restore of the database from a backup | the age of the backup |

The first three need a window of hours at most. The last two need the window to cover the whole
history being reprocessed, which is the honest argument for keeping ids **as long as the topic
keeps the events**: anything older cannot be replayed, because Kafka has already deleted it.

## Bounding it

A window is a delete with a date in it, so the table needs to know when each id was applied:

```sql
CREATE TABLE processed (sale TEXT PRIMARY KEY, applied_at TEXT NOT NULL);
DELETE FROM processed WHERE applied_at < datetime('now', '-7 days');
```

Run once a day, that keeps a week. Kept in memory instead of a table, the same idea is a set with
an expiry, which is what stream processors do for their own deduplication, and a crash empties it
unless it is checkpointed, which lesson 13 says how Flink does.

**The window is a risk you choose with numbers, not a detail.** A team that sets seven days should
be able to say why no duplicate can arrive after seven days, and what happens if a backup older
than that is restored. When that answer is weak, the stronger design is the one from the first
section, writes that repeat harmlessly, which need no memory at all, or the previous section's,
offsets in the database, which remember one number per partition instead of one per event.
