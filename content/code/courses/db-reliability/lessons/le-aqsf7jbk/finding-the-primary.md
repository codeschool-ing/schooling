---
title: The application has an address, not a primary
version: 1
---

Every failover so far ended with a sentence like "the new primary is on 5434". The application did not
read it. It has a connection string with an address in it, and after the failover that address is a
dead server, a read-only replica, or, worst, an old primary that came back. Lesson 15 put this off to
here; Patroni chose a new leader in lesson 16 and told nobody but etcd.

There are four places to put the knowledge of where the primary is, and each moves a different thing
when it changes:

| approach | what moves at a failover | what the application does |
|---|---|---|
| **client-side**: several hosts in the connection string | nothing | tries each host and keeps the one that accepts writes |
| **proxy**: HAProxy or similar, in front | the proxy's choice of backend | connects to one fixed address |
| **virtual IP**: an address that moves between machines | the address itself | connects to one fixed address |
| **DNS**: a name that is repointed | a DNS record | connects to a name, and must look it up again |

All four share the part that matters most: **connections open at the moment of a failover are
broken**, and no address trick repairs them. What the application does next, reconnect and retry or
show an error, is the application's code, and it is the last section's subject.

This lesson builds the first two on lesson 16's cluster, three Patroni nodes on ports 5441 to 5443
with `pg1` the leader, and explains the other two, which need more than one machine to show honestly.
