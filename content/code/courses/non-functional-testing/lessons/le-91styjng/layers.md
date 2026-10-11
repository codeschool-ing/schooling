---
title: Four layers, and where to look first
version: 1
---

Lesson 8 measured how slow the box office is. This lesson finds where the time goes, and
"the server is slow" is not an answer, because a request passes through several things on its way
to an answer and any one of them can be the one that is full. **A bottleneck is the one resource
that, made faster, would make the whole request faster**; speeding up anything else changes
nothing a user can see.

It helps to think of a request as passing through four layers, each inside the one before it:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l09-layers\" aria-label=\"One request for GET /shows/990 traced through four layers, left to right. The client, curl, measured 11.5 ms from start to finish. Inside that, the network: the connection, the kernel queue of connections waiting to be accepted, and the packets of the answer. Inside that, the application, whose Server-Timing header said 10.7 ms in total. Inside that, the database, which took 10.2 ms counting the bookings. Under all four runs the infrastructure: processors, memory and disk, shared by the server and the load generator. Each layer is named with the tool that sees it: curl -w and nstat for the network, Server-Timing for the application, EXPLAIN QUERY PLAN for the database, top, vmstat and free for the infrastructure.\"><rect x=\"20.0\" y=\"30.0\" width=\"680.0\" height=\"230.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"32.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">client</text><text x=\"32.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">curl: 11.5 ms</text><text x=\"688.0\" y=\"46.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">curl -w</text><rect x=\"60.0\" y=\"82.0\" width=\"600.0\" height=\"168.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"72.0\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">network</text><text x=\"72.0\" y=\"114.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">connection, accept queue, packets</text><text x=\"648.0\" y=\"98.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">nstat</text><rect x=\"100.0\" y=\"134.0\" width=\"520.0\" height=\"106.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"112.0\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">application</text><text x=\"112.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Server-Timing total: 10.7 ms</text><text x=\"608.0\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">Server-Timing</text><rect x=\"140.0\" y=\"186.0\" width=\"440.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"152.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">database</text><text x=\"152.0\" y=\"218.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">db: 10.2 ms</text><text x=\"568.0\" y=\"202.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">EXPLAIN QUERY PLAN</text><rect x=\"20.0\" y=\"268.0\" width=\"680.0\" height=\"46.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\" stroke-dasharray=\"5 3\"></rect><text x=\"32.0\" y=\"284.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">infrastructure, under every layer</text><text x=\"32.0\" y=\"300.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">processors, memory, disk, shared with the load generator</text><text x=\"688.0\" y=\"284.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">top  vmstat  free</text></svg>", "caption": "Each layer holds the one inside it, so each layer's time includes the time of the layers within. The difference between two of them is the time spent in between."}
```

- **The client** sends the request and waits for the last byte of the answer. Its clock covers
  everything.
- **The network** carries it: the connection, the operating system's queue of connections waiting
  to be accepted, the packets each way. On one machine it is almost free; across the internet it
  is often the largest part.
- **The application** reads the request and builds the answer: here `app.py`, its lock and its
  call to the payment provider.
- **The database** answers the application's queries.

Underneath all four sits **the infrastructure**: the processors, the memory and the disk, shared by
everything on the machine, the load generator included.

## Subtract one clock from the next

The quickest way to place the time is to read a clock at two boundaries and subtract. `app.py`
already reports its own: every answer carries a `Server-Timing` header with the database time,
the payment time and the total, as lesson 1 showed. With the server running in the other
terminal:

```
ana@nft:~/boxoffice$ curl -si localhost:8000/shows/990 | grep Server-Timing
Server-Timing: db;dur=10.2, pay;dur=0.0, total;dur=10.7
ana@nft:~/boxoffice$ curl -si -X POST localhost:8000/bookings -d '{"show_id": 990, "seat": 12, "customer": "ana"}' | grep Server-Timing
Server-Timing: db;dur=15.7, pay;dur=40.1, total;dur=58.2
ana@nft:~/boxoffice$ curl -s -o /dev/null -w 'connect %{time_connect}  first byte %{time_starttransfer}  total %{time_total}\n' localhost:8000/shows/990
connect 0.000293  first byte 0.011364  total 0.011461
```

Read the three lines in order. Looking at show 990, the database took 10.2 ms of a server total of
10.7: **the database is nearly all of it**. The booking spent 15.7 ms in the database and 40.1 ms
paying, 55.8 ms of a total of 58.2; the 2.4 ms left over is code `Server-Timing` does not time,
the `INSERT` and the commit among it. A number that is not inside any named part is still a
number, and the subtraction is how you notice it.

The last line asks `curl` for its own clock, at three points. `time_connect` is when the
connection was open, 0.293 ms after the start; `time_starttransfer` is the first byte of the
answer, at 11.364 ms; `time_total` is the last, at 11.461 ms. Between the connection and the
first byte, the client was waiting for the server, so **the client and the server agree, and the
network adds almost nothing here**. When the client's time and the server's total disagree by a
lot, the difference was spent outside the application, and "Network and infrastructure" shows a
case where they do. `curl` has more of these points, `time_namelookup` for the DNS lookup and
`time_appconnect` for the TLS handshake among them; neither matters on `127.0.0.1` without TLS,
so neither appears here.

## The USE method

Clocks say which layer. To find which resource inside a layer is full, Brendan Gregg's **USE
method** asks three questions of every resource, hardware or software:

| | the question | for a processor |
|---|---|---|
| **utilisation** | how much of the time was it busy? | the `%CPU` of each process, the `id` (idle) figure falling |
| **saturation** | how much work was waiting for it? | more runnable threads than processors |
| **errors** | did it refuse or drop anything? | rarely, for a processor; often, for a queue or a network |

The resources are the obvious ones, processors, memory, disk and network, and the ones a program
makes for itself: **a lock, a pool of connections, a queue**. A software resource has no
`%CPU` and no counter in `top`, which is why it hides well: it saturates while every piece of
hardware looks idle.

Run a load and look at the processors while it runs. The line below starts eight workers in the
background for twelve seconds, with `&`, and two seconds later asks `top` for two snapshots two
seconds apart, keeping the line that sums up the processors and the lines of the two Python
programs. `-c` shows each command line, which is how the server is told from the generator, both
being `python3`. The first snapshot has nothing before it to compare with, so read the second:

```
ana@nft:~/boxoffice$ python3 measure.py 8 12 > load.txt & sleep 2; top -b -n 2 -d 2 -c -o %CPU | grep -E 'Cpu\(s\)|python3 [am]'; wait
%Cpu(s): 57.5 us, 40.0 sy,  0.0 ni,  2.5 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st 
     13 ana       20   0  906264  34448  11632 S 180.0   0.2   0:03.89 python3 app.py
     43 ana       20   0  616004  18308   9712 S   0.0   0.1   0:00.15 python3 measure.py 8 12
%Cpu(s): 56.7 us, 29.6 sy,  0.0 ni,  8.6 id,  3.2 wa,  0.0 hi,  1.1 si,  0.9 st 
     13 ana       20   0 1020912  33628  11632 S 212.5   0.2   0:08.14 python3 app.py
     43 ana       20   0  616004  18340   9712 S   6.5   0.1   0:00.28 python3 measure.py 8 12
ana@nft:~/boxoffice$ head -4 load.txt
8 workers, 12.0 s: 2206 requests, 183.5 per second
status: 200 x2206
ms          count    mean  median     p90     p95     p99     max
all          2206    43.5    41.4    65.1    74.2    92.5   126.4
```

In the second snapshot `python3 app.py` is using 212.5% of a processor, more than two of the
four, and `measure.py` 6.5%. The `%Cpu(s)` line says the machine was 8.6% idle. That line covers
the whole computer the transcripts were recorded on, which was doing other work at the same time,
so yours will show more idle; the per-process figures are the box office's own. **The server is
using the processors and the generator is not**: utilisation is high, in the application layer's
process. `Server-Timing` already said which part of it. The section after this one is about that
part.
