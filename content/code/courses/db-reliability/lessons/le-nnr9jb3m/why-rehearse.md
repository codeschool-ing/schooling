---
title: Why kill a healthy primary
version: 1
---

Lesson 1 said a backup is a claim until it is restored. A failover is the same kind of claim: the
cluster manager is configured, the proxy follows it, the application reconnects, and none of that is
known until a primary has died with an application running against it. The only question is whether
that first time is chosen or not.

A **rehearsal** (in some teams a *game day*) chooses it: a failure caused on purpose, at a time
everybody agreed, with people watching and a way back ready. It finds what lesson 22's incident would
have found, on a day when finding it costs nothing:

- a setting that is right on two nodes and wrong on the third, which lesson 15 met with `ALTER SYSTEM`;
- an application that does not reconnect, or reconnects and keeps a stale address;
- an alert that does not fire, or fires to a channel nobody reads any more;
- a runbook step that names a server which was renamed last year;
- the real number of seconds, which is never the one in the design document.

And it trains people. The person who has killed a primary on a Tuesday afternoon reads a failover's
log at three in the morning without having to learn it there.

Lesson 7 did this for restores: a drill on a schedule, with a stopwatch, written down. This lesson does
it for the failover, on lesson 16's cluster, with lesson 19's HAProxy in front and `orders.sh` as the
customers.
