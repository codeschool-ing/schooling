---
title: What a managed database takes off your hands
version: 1
---

A **managed PostgreSQL service** runs the server for you: a cloud provider, or a company that does
only this, creates the machine, installs PostgreSQL, takes the backups, keeps a standby in another
data centre of the same region, and fails over to it when the primary dies. Everything lessons 2 to
20 built by hand is offered as a setting.

That is a real trade, and often a good one. It is also the place where the questions of this course
are most easily stopped being asked, because the answer seems to be "the provider does it". This
lesson is about what that answer actually covers, and it is the one lesson of the course you could
take on such a service instead of on your virtual machine: its transcripts are arithmetic, done in
`psql` on the lab's own server.

What changes, in the terms of this course:

| | on your own servers | on a managed service |
|---|---|---|
| base backups and the archive (lessons 3 to 5) | yours | the provider's, on a schedule you choose from a menu |
| point-in-time recovery (lesson 6) | into a server you name | into a **new** instance, with a new address |
| the standby and the failover (lessons 11 to 17) | yours, Patroni's | the provider's, usually one checkbox |
| finding the new primary (lesson 19) | your proxy or connection string | the provider's DNS name, repointed |
| superuser, `pg_wal`, the data directory | yours | **not** yours |
| a wrong `DELETE`, a dropped table, a leaked password | yours | **still yours** |

The last row is the one a contract does not change. The provider keeps the service up; whether the
rows in it are right is the customer's problem on every provider, and their agreements say so in
words.
