---
title: More clients, the same work
version: 1
---

The belief: **more connections, more throughput.** If eight clients get a thousand transactions a
second out of the server, ninety should get more. They do not, and the reason is arithmetic the
server cannot escape. It has a fixed number of processors, four on the machine these transcripts
come from, and a fixed disk. Once those are busy, a new client does not add work done; it adds a
place to wait.

## Measuring it

This script runs lesson 2's mix at seven client counts, twenty seconds each, and prints the two
numbers that matter from each run, throughput and average latency:

```sh
cat > ~/workload/curve.sh <<'SH'
#!/bin/sh
# Lesson 2's mix at a growing number of clients, twenty seconds each.
cd ~/workload
for c in 1 4 8 16 32 64 90; do
  pgbench -n -c "$c" -j 4 -T 20 \
    -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 \
    -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 \
    market 2>&1 |
  awk -v c="$c" '/^latency average/ { ms = $4 } /^tps/ { tps = $3 }
                 END { printf "%3d clients  %7.0f tps  %7.1f ms\n", c, tps, ms }'
done
SH
chmod +x ~/workload/curve.sh
```

It takes two and a half minutes, and the workload writes orders, so `~/reset-market.sh` at the end
of the lesson puts `market` back. On the computer this course was recorded on:

```
ana@vm:~$ ~/workload/curve.sh
  1 clients      489 tps      2.0 ms
  4 clients     1389 tps      2.9 ms
  8 clients     1334 tps      6.0 ms
 16 clients     1413 tps     11.3 ms
 32 clients     1436 tps     22.3 ms
 64 clients     1396 tps     45.9 ms
 90 clients     1481 tps     60.8 ms
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two charts over the same seven client counts, 1, 4, 8, 16, 32, 64 and 90. Left, throughput: 489 transactions a second with one client, 1389 with four, then flat between 1334 and 1481 up to ninety. Right, average latency: 2.0 milliseconds with one client, rising steadily to 60.8 with ninety.\"><text x=\"30\" y=\"24\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">throughput, transactions a second</text><path d=\"M30 230 L330 230\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M30 60 L30 230\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"50.0\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1</text><text x=\"45.0\" y=\"172.1\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--phosphor)\">489</text><text x=\"93.33333333333334\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">4</text><text x=\"88.33333333333334\" y=\"82.1\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--phosphor)\">1389</text><text x=\"136.66666666666669\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">8</text><text x=\"131.66666666666669\" y=\"87.6\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--phosphor)\">1334</text><text x=\"180.0\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">16</text><text x=\"175.0\" y=\"79.69999999999999\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--phosphor)\">1413</text><text x=\"223.33333333333334\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">32</text><text x=\"218.33333333333334\" y=\"77.4\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--phosphor)\">1436</text><text x=\"266.66666666666663\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">64</text><text x=\"261.66666666666663\" y=\"81.4\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--phosphor)\">1396</text><text x=\"310.0\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">90</text><text x=\"305.0\" y=\"72.9\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--phosphor)\">1481</text><path d=\"M50.0 181.1 L93.3 91.1 L136.7 96.6 L180.0 88.7 L223.3 86.4 L266.7 90.4 L310.0 81.9\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><circle cx=\"50.0\" cy=\"181.1\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"93.33333333333334\" cy=\"91.1\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"136.66666666666669\" cy=\"96.6\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"180.0\" cy=\"88.69999999999999\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"223.33333333333334\" cy=\"86.4\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"266.66666666666663\" cy=\"90.4\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"310.0\" cy=\"81.9\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"180.0\" y=\"262\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">clients</text><text x=\"390\" y=\"24\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">average latency, milliseconds</text><path d=\"M390 230 L690 230\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M390 60 L390 230\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"410.0\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1</text><text x=\"405.0\" y=\"216.14285714285714\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--amber)\">2.0</text><text x=\"453.3333333333333\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">4</text><text x=\"448.3333333333333\" y=\"213.95714285714286\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--amber)\">2.9</text><text x=\"496.6666666666667\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">8</text><text x=\"491.6666666666667\" y=\"206.42857142857142\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--amber)\">6.0</text><text x=\"540.0\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">16</text><text x=\"535.0\" y=\"193.55714285714285\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--amber)\">11.3</text><text x=\"583.3333333333334\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">32</text><text x=\"578.3333333333334\" y=\"166.84285714285716\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--amber)\">22.3</text><text x=\"626.6666666666666\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">64</text><text x=\"621.6666666666666\" y=\"109.52857142857144\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--amber)\">45.9</text><text x=\"670.0\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">90</text><text x=\"665.0\" y=\"73.34285714285716\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--amber)\">60.8</text><path d=\"M410.0 225.1 L453.3 223.0 L496.7 215.4 L540.0 202.6 L583.3 175.8 L626.7 118.5 L670.0 82.3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><circle cx=\"410.0\" cy=\"225.14285714285714\" r=\"3\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"453.3333333333333\" cy=\"222.95714285714286\" r=\"3\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"496.6666666666667\" cy=\"215.42857142857142\" r=\"3\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"540.0\" cy=\"202.55714285714285\" r=\"3\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"583.3333333333334\" cy=\"175.84285714285716\" r=\"3\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"626.6666666666666\" cy=\"118.52857142857144\" r=\"3\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"670.0\" cy=\"82.34285714285716\" r=\"3\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"540.0\" y=\"262\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">clients</text></svg>", "caption": "Lesson 2's mix at seven client counts. Throughput stops growing at about four clients, the number of processors; latency keeps growing."}
```

## Reading the curve

**Throughput.** One client gets 489 transactions a second: one request at a time, each waiting for
the last. Four get 1389, nearly three times as many, because four processors are now busy at once.
From there the line is flat: eight, sixteen, thirty-two, sixty-four and ninety clients all get
between 1334 and 1481. The server reached what four processors can do at about four clients,
and every client added after that took a share of the same work.

**Latency.** The average time per transaction goes the other way: 2.0 milliseconds with one client,
60.8 with ninety. Throughput stayed put, so the clients had to be waiting: mostly in the operating
system's queue for a processor, since four processes at a time is all four processors can run.
That is Little's law from queueing theory: the number of requests in flight equals
throughput times latency. At ninety clients and 1481 transactions a second, each one takes
about ninety divided by 1481 of a second, the 60.8 milliseconds in the table.

The bend is the useful number. Below it, more clients means more work done; above it, more clients
means the same work, slower for everybody. On this machine it sits at **about four**, the number of
processors, because lesson 2's mix is mostly work for the processor and the data fits in memory. A
mix that waits on the disk or on the network bends later, because a waiting process leaves the
processor free; a mix that fights over the same rows bends sooner. That is why the number comes from
measuring your own workload, and section 06 does it for the pool.

## Why raising `max_connections` does not help

Raising the limit to 500 changes where the line ends, not its shape. Every extra connection is a
process that the operating system has to schedule, with memory of its own, which competes for the
same four processors. Past the bend, more of them add no throughput, as the table shows, and they are
not free: the processors spend part of their time switching between processes, and the
server's shared structures — the lock tables, the list of running transactions every snapshot reads
— are walked more often. Lesson 15's horizon is computed from that list, too.

What the application actually needs is not ninety connections running at once. It needs ninety
**clients able to send work**, and four or eight connections actually doing it, with somewhere for
the rest to wait that costs less than a server process. That place is a connection pool.
