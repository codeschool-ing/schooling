---
title: Who takes the writes
version: 1
---

Every replicated system has to answer one question: **when the copies are changed, which copy is
changed first?** There are three answers, and every database you will use picks one of them.

| arrangement | how writes work | examples | what it costs |
| --- | --- | --- | --- |
| **single leader** | one copy, the leader or primary, takes every write and streams it to the followers | PostgreSQL, MySQL, MongoDB, each Kafka partition | the leader is a limit on writes; when it fails, a follower has to be promoted |
| **multi-leader** | several copies take writes, usually one per region, and exchange them | MySQL and PostgreSQL with extensions, CouchDB, DynamoDB global tables | two leaders can change the same row at once, and lesson 9's conflicts follow |
| **leaderless** | the client writes to several copies and reads from several, with quorums | Cassandra, ScyllaDB, the original Dynamo | lesson 8's quorums, and copies that are repaired in the background |

**Single leader is the default**, and the rest of this lesson uses it. Its weak moment is the failover,
when the leader dies and a follower takes over. Two things can go wrong there. A follower that was
behind becomes the leader, and the writes it had not received are lost, which lesson 8 showed is the
replication lag at the moment of failure. Or the old leader was not dead, only unreachable, and now
there are two leaders taking writes: **split brain**, the failure that the rest of the lesson's
reasoning about "three nodes" exists to prevent.

## Synchronous, asynchronous, and the middle

Lesson 8 compared a synchronous standby, where a commit waits for the copy, with an asynchronous one,
where it does not. Production systems mostly sit in between. PostgreSQL can wait for **any one of
several** standbys (`synchronous_standby_names = 'ANY 1 (s1, s2)'`), so one slow or dead standby does
not stop the writes. Kafka waits for a number of **in-sync replicas**, which the cluster later in this
lesson shows. Both keep one property: a write that was confirmed exists on at least two machines.
