---
title: The price, measured and multiplied out
version: 1
---

`pgbench` runs a small banking workload as fast as it can: here four clients for ten seconds, printing
the average time per transaction and the transactions per second. First with the standby asynchronous,
before the reload of the last section:

```
ana@vm:~$ pgbench -c 4 -T 10 -n bench | grep -E "latency average|tps"
latency average = 1.610 ms
tps = 2484.004983 (without initial connection time)
```

Then synchronous, with `synchronous_commit` at its default, `on`:

```
ana@vm:~$ pgbench -c 4 -T 10 -n bench | grep -E "latency average|tps"
latency average = 1.969 ms
tps = 2031.340162 (without initial connection time)
```

Then the two ends of the scale, set for `pgbench`'s sessions only through `PGOPTIONS`:

```
ana@vm:~$ PGOPTIONS='-c synchronous_commit=remote_apply' pgbench -c 4 -T 10 -n bench | grep -E 'latency average|tps'
latency average = 2.019 ms
tps = 1981.525766 (without initial connection time)
ana@vm:~$ PGOPTIONS='-c synchronous_commit=off' pgbench -c 4 -T 10 -n bench | grep -E 'latency average|tps'
latency average = 0.837 ms
tps = 4776.640810 (without initial connection time)
```

| `synchronous_commit` | average latency | transactions a second |
|---|---|---|
| `off` | 0.837 ms | 4777 |
| asynchronous standby, `on` | 1.610 ms | 2484 |
| synchronous standby, `on` | 1.969 ms | 2031 |
| synchronous standby, `remote_apply` | 2.019 ms | 1982 |

Waiting for the standby's flush cost **about a third of a millisecond a transaction, close to a fifth
of the throughput.** Waiting for its replay as well added only a twentieth of a millisecond more,
because a standby with nothing else to do replays as soon as it has flushed. Ten-second runs move by a
few percent from one to the next, so read the gaps rather than the last digit; yours will differ with
your disk. And this is the cheapest it will ever be: the standby here is on the same machine, the
network between them is a memory copy, and this kernel cannot add an artificial delay to simulate one.

`off` is the other surprise: it took half the time of the asynchronous run, because the primary does not
even wait for its own disk. It loses the last fraction of a second of commits if the primary crashes,
**with or without a standby**, which is acceptable for a page-view counter and nothing else.

## Multiplied out to real distances

Every synchronous commit pays **one round trip** to the standby, on top of the standby's own disk
flush. The round trip is set by distance, not by hardware:

| standby | typical round trip | added to every commit |
|---|---|---|
| same machine (this lab) | well under 0.1 ms | the third of a millisecond above, mostly the standby's flush |
| same data centre | a fraction of a millisecond | about the same |
| another data centre in the same city or region | 1 to 5 ms | a few milliseconds |
| another continent | around 100 ms or more | a tenth of a second, at least |

A transaction that commits once pays it once; an application that commits in a loop, row by row, pays
it per row, and a nightly import of a million rows that took two minutes would take over a day against
a standby on another continent. That is why synchronous standbys are usually **close**, and the copies
far away are asynchronous, which lesson 20 builds on.

The other cost is not latency at all, and it is the subject of the next section.
