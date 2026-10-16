---
title: Backups that are not entirely yours
version: 1
---

The provider's backups are lessons 5 and 6, run for you: a nightly base backup, the log archived
continuously, and point-in-time recovery to any moment inside a **retention window** you choose,
commonly a week to a month. Three things about them follow from the rest of this course:

1. **A restore makes a new database.** Point-in-time recovery creates a new instance from the
   backups, with its own address; the old one keeps running with the mistake in it. Your runbook
   (lesson 24) needs the steps for pointing the application at the new one, and the time it takes,
   measured, is your RTO.
2. **They live in the same account.** The backups, the archive and the database are all reachable by
   whoever holds the account's administrative credentials, and deleting the instance often deletes its
   automatic backups with it. That is lesson 10's ransomware scenario with a different door: the copy
   that has to survive must be somewhere those credentials cannot reach. A logical dump (lesson 2),
   taken on your own schedule and stored elsewhere, is the usual answer, and it is the one backup on
   a managed service that is completely yours.
3. **Nobody restores them for you to check.** Lesson 7's drill is as necessary here as anywhere: a
   restore into a new instance, a check of the rows, a stopwatch. The only change is that the server
   costs money by the hour while it exists, so delete it afterwards.

## The questions to ask before signing

- What availability does the agreement promise, and what counts as "unavailable"?
- Is the standby synchronous? How long does a failover take, measured by you?
- How long is the retention window, and what happens to backups when an instance is deleted?
- Can backups be copied to another region, or another account?
- What can you not do: which extensions, which settings, superuser?
- How do you get your data out, all of it, if you leave?
