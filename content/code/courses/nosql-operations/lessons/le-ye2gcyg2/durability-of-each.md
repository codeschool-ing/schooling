---
title: How much each one loses, and what it costs
version: 1
---

The two previous sections killed the process. **What a process crash loses and what a machine
crash loses are different amounts**, and the setting that decides the second, `appendfsync`, only
shows its value on the day the power goes.

## Two places a write can be

When Redis appends a command to the log, it calls `write()`, and the bytes land in the operating
system's memory, its page cache. They reach the disk when the operating system flushes them, or when
Redis asks with `fsync()`. A killed Redis process leaves the page cache intact: the kernel still
writes those bytes out, which is why the `docker kill` in the previous section lost nothing even
though less than a second had passed. A machine that loses power loses the page cache too, and with
it every write that was not yet flushed.

The lab cannot pull its own power cord, so the last column of this table is what Redis's
documentation states, **not something this lesson ran**:

| setting | Redis asks for a flush | the process is killed | the machine loses power |
| --- | --- | --- | --- |
| snapshots only (`save` rules) | when a snapshot is written | every write since the last snapshot | every write since the last snapshot |
| `appendfsync always` | after every write, before the reply | nothing | nothing acknowledged |
| `appendfsync everysec` | once a second, in the background | nothing | about the last second of writes |
| `appendfsync no` | never; the operating system decides | nothing | whatever the operating system had not flushed, typically up to 30 seconds on Linux |
| no persistence | never | everything | everything |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"A time axis with writes arriving steadily and the power failing at the right-hand end. Three rows. Snapshots only: the last snapshot was taken minutes before the failure, and every write after it is lost. Append-only file with everysec: only the writes of the last second are lost. Append-only file with always: nothing acknowledged is lost.\"><line x1=\"170\" y1=\"30\" x2=\"640\" y2=\"30\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"178\" y1=\"25\" x2=\"178\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"197\" y1=\"25\" x2=\"197\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"216\" y1=\"25\" x2=\"216\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"235\" y1=\"25\" x2=\"235\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"254\" y1=\"25\" x2=\"254\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"273\" y1=\"25\" x2=\"273\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"292\" y1=\"25\" x2=\"292\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"311\" y1=\"25\" x2=\"311\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"330\" y1=\"25\" x2=\"330\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"349\" y1=\"25\" x2=\"349\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"368\" y1=\"25\" x2=\"368\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"387\" y1=\"25\" x2=\"387\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"406\" y1=\"25\" x2=\"406\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"425\" y1=\"25\" x2=\"425\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"444\" y1=\"25\" x2=\"444\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"463\" y1=\"25\" x2=\"463\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"482\" y1=\"25\" x2=\"482\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"501\" y1=\"25\" x2=\"501\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"520\" y1=\"25\" x2=\"520\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"539\" y1=\"25\" x2=\"539\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"558\" y1=\"25\" x2=\"558\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"577\" y1=\"25\" x2=\"577\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"596\" y1=\"25\" x2=\"596\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"615\" y1=\"25\" x2=\"615\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"170\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">writes, one tick each</text><line x1=\"650\" y1=\"20\" x2=\"650\" y2=\"230\" stroke=\"var(--amber)\" stroke-width=\"2\" stroke-dasharray=\"4 3\"></line><text x=\"650\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">power lost</text><text x=\"20\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">snapshots only</text><rect x=\"170\" y=\"75\" width=\"130\" height=\"20\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"300\" y=\"75\" width=\"340\" height=\"20\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"640\" y=\"109\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lost: everything since the snapshot</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">everysec</text><rect x=\"170\" y=\"130\" width=\"440\" height=\"20\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"610\" y=\"130\" width=\"30\" height=\"20\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"640\" y=\"164\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lost: about one second</text><text x=\"20\" y=\"195\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">always</text><rect x=\"170\" y=\"185\" width=\"470\" height=\"20\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"640\" y=\"219\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lost: nothing acknowledged</text><text x=\"300\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">last snapshot</text><line x1=\"300\" y1=\"70\" x2=\"300\" y2=\"95\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line></svg>", "caption": "What each setting loses when the machine itself loses power. A killed process loses less, because the operating system still writes out what it was given."}
```

## What `always` costs

`always` sounds like the obvious choice until it is measured. `redis-benchmark` ships in the image;
`-t set` runs only `SET`, `-n` is the number of requests and `-c` the number of clients sending them
at once, 50 unless you say otherwise. The `aof` container from the previous section, first with
`everysec`:

```
ana@vm:~$ docker exec redis redis-cli CONFIG SET appendfsync everysec
OK
ana@vm:~$ docker exec redis redis-benchmark -t set -n 100000 --csv
"test","rps","avg_latency_ms","min_latency_ms","p50_latency_ms","p95_latency_ms","p99_latency_ms","max_latency_ms"
"SET","87950.75","0.354","0.064","0.295","0.767","1.167","3.447"
ana@vm:~$ docker exec redis redis-benchmark -t set -n 20000 -c 1 --csv
"test","rps","avg_latency_ms","min_latency_ms","p50_latency_ms","p95_latency_ms","p99_latency_ms","max_latency_ms"
"SET","32733.22","0.028","0.008","0.023","0.071","0.103","1.567"
```

And with `always`:

```
ana@vm:~$ docker exec redis redis-cli CONFIG SET appendfsync always
OK
ana@vm:~$ docker exec redis redis-benchmark -t set -n 100000 --csv
"test","rps","avg_latency_ms","min_latency_ms","p50_latency_ms","p95_latency_ms","p99_latency_ms","max_latency_ms"
"SET","38124.29","1.201","0.256","1.087","2.063","3.583","16.751"
ana@vm:~$ docker exec redis redis-benchmark -t set -n 20000 -c 1 --csv
"test","rps","avg_latency_ms","min_latency_ms","p50_latency_ms","p95_latency_ms","p99_latency_ms","max_latency_ms"
"SET","2686.37","0.364","0.168","0.319","0.655","1.375","8.143"
```

On the lab, with 50 clients, **`always` served `38124.29` writes a second against `87950.75`**. With one
client, the case of a program that waits for each reply before sending the next, it fell from
`32733.22` to `2686.37`, because every single write now waits for the disk. With 50 clients the loss is
smaller because Redis flushes once for all the writes that arrived together.

These figures are this machine's on this run, a virtual machine with four processors on a virtual
disk, shared with other work. Your numbers will differ, and they depend above all on how long your
disk takes to complete a flush, which on a laptop's SSD, a cloud volume and a spinning disk are
different by orders of magnitude. **Run the same four lines on the machine that will serve
production** before deciding. The ratio is the finding, not the figures.

## Choosing

`everysec` is the default because it is the cheap middle: a process crash loses nothing and a power
loss about a second. For the shop, that second matters only for data whose loss is an incident and
which lives nowhere else, and those are few: the idempotency keys of lesson 12, perhaps a stock
counter. Lesson 15 adds the other half of the answer, a copy on another machine, and shows that the copy has
a window of its own.
