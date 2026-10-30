---
title: High availability, a standby you cannot read
version: 1
---

**A regional Cloud SQL instance is two machines in two zones, and you only ever see one of them.** The
primary takes every read and every write. The standby, in another zone of the same region, has a disk
of its own that receives every write synchronously: a write is acknowledged only once it is on both
disks. If the primary or its zone fails, Cloud SQL starts the engine on the standby, over the copy of
the data it already has, and moves the instance's address to it. The application reconnects to the
same address and finds the same data.

**The wrong idea is that high availability is for scale.** It is not: the standby takes no
connections, so a database that is slow on a zonal instance is exactly as slow on a regional one, and
slightly slower to commit, because every write now waits for a second zone to answer. What it is for
is the day a zone loses power, a machine fails, or the primary stops answering its health checks.
Google documents that the failover is automatic in those cases and that it usually takes about a
minute, during which connections are refused. That timing is Google's, not this lab's; nothing on the
laptop fails over.

## What a failover is, in order

As Google's documentation on high availability describes it:

1. **Cloud SQL notices the primary is gone.** Each instance reports a heartbeat, and a primary that
   misses them for long enough is declared failed.
2. **The standby becomes the primary.** Its disk already holds every acknowledged write, so nothing
   committed is lost; transactions that were open when the primary died are rolled back by the engine
   when it starts, as after any crash.
3. **The address moves.** The instance keeps its private address and its connection name; what answers
   on them is now the machine in the other zone.
4. **A new standby is built** in a zone of the region, and the instance is highly available again
   when it is ready.

**The address does not change. What is behind it does.** So the work on the application's side is
to reconnect: every open connection breaks, and a client has to open new ones. A driver that retries
is fine. A connection pool that hands out dead connections until it is restarted is the usual way a
one-minute failover becomes a one-hour outage, and it is worth testing before the day it matters.

**The test is a command.** `gcloud sql instances failover quitanda-orders` makes a regional instance
fail over on purpose, which the command line's reference describes in one line, "Causes a
high-availability Cloud SQL instance to failover." Run on a quiet afternoon with the application
watching, it answers the question that matters: what the application does when the database goes away
for a minute. It was not run here.

## Turning it on

```
ana@laptop:~/gcp$ gcloud sql instances create --help | sed -n '/^     --availability-type=/,/This is the default/p'
     --availability-type=AVAILABILITY_TYPE
        Specifies level of availability. AVAILABILITY_TYPE must be one of:

         regional
            Provides high availability and is recommended for production
            instances; instance automatically fails over to another zone within
            your selected region.
         zonal
            Provides no failover capability. This is the default.
```

**`zonal` is the default**, so an instance is highly available only when somebody asked for it. The
lesson 6 command with `--availability-type=regional` creates one, and `--secondary-zone` chooses the
standby's zone where the default choice is not wanted. An existing zonal instance can be made
regional with `gcloud sql instances patch quitanda-orders --availability-type=regional`, and the
documentation says that change restarts the instance. None of these was run here.

## What it costs, and what it does not cover

**It is the lesson 6 instance twice**, the machine and the disk both, because there are two of each:

```
ana@laptop:~/gcp$ python3 -c 'h = 730; print(round((2 * 0.062 + 8 * 0.0105) * h + 100 * 0.255, 2), round((2 * 0.1239 + 8 * 0.021) * h + 100 * 0.51, 2), round(20 * 30 * 0.14, 2), round(130 * 0.12, 2))'
177.34 354.53 84.0 15.6
```

**177.34 for the zonal instance, 354.53 for the regional one**, from the prices of lesson 6's last
section. The other two numbers on that line are for the sections after this one.

**High availability protects against a machine or a zone.** It does not protect against a mistake: a
`DELETE` without a `WHERE` is written to both disks, synchronously, before the commit returns, and the
standby holds it as faithfully as the primary does. It does not protect against the loss of a whole
region either, since both zones are in it. The first is what backups and point-in-time recovery are
for, two sections on; the second is a replica in another region, which the next section reaches.
