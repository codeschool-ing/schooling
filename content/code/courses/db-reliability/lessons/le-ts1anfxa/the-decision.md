---
title: Three questions before a promotion
version: 1
---

**Failover** is making a standby the primary because the primary failed. The command that does it
takes a second. The decision before it is the whole skill, and it comes down to three questions, in
this order:

1. **Is the primary really gone?** "I cannot reach it" is a fact about the path between you and the
   primary, not about the primary. A server that is alive and cut off from you is still taking writes
   from whoever can still reach it, and promoting a standby then makes two primaries.
2. **How much does the standby have?** Its position against the last one the primary is known to
   have reached is the data a promotion loses, and lesson 8's RPO says whether that is acceptable or
   whether it is worth waiting for the primary to come back.
3. **Will anything promote a second time?** Another standby, another person, a script: once one
   standby is the primary, every other path to a promotion has to be closed, and the old primary has
   to be kept from coming back as a primary.

**Switchover** is the planned version: the primary is healthy, and you move its role to a standby
on purpose, for maintenance or a test. It answers all three questions by construction, which is why
it is the right way to rehearse, and the last sections of this lesson do one.

This lesson does both **by hand**, on lesson 11's pair: the primary on 5432 and `standby1` on 5434.
A program that answers the three questions on its own is the subject of lesson 16, and what happens
when it answers the first one wrong is lesson 17.
