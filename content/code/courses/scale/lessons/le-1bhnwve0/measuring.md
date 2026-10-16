---
title: Measuring before changing anything
version: 1
---

**A change made to a system you have not measured is a guess with a deployment attached.** So the
first thing to do with the box office is to find out what it does now: how many requests a second
it answers, how long each takes, and what happens to both when more are sent at once. `load.py`,
which you wrote in section 04, does all three.

## One worker, two paths

With one worker, `load.py` sends a request, waits for the answer and sends the next, for ten
seconds. First the cheap path, reading a show:

```
ana@lab:~/tickets$ python3 load.py -c 1 -d 10 http://localhost:8080/events/1
requests  10718 in 10.0 s = 1071.6 per second
latency   p50 0.9 ms  p95 1.3 ms  p99 2.0 ms  max 18.9 ms
status    200: 10718
```

Over a thousand reads a second, the middle one answered in under a millisecond. Then the expensive
path, buying a ticket, spread over the hundred shows by `--events 100` so that no two sales in a
row touch the same one:

```
ana@lab:~/tickets$ python3 load.py -m POST -c 1 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1189 in 10.0 s = 118.9 per second
latency   p50 7.8 ms  p95 12.5 ms  p99 14.2 ms  max 21.3 ms
status    201: 1189
```

About 119 sales a second, 7.8 ms each in the middle. Almost all of that is `sign()`, the
deliberately slow part of a sale; the update and the insert around it are a fraction of a
millisecond. A sale costs **nine times** what a read does, which is why the rest of this lesson
measures sales.

## Reading the four latencies

`load.py` prints four points of the distribution, and each answers a different question:

- **p50**, the median: half the requests were faster than this. It describes the typical one.
- **p95** and **p99**: the times below which 95 and 99 out of every hundred finished. They describe
  the slow ones, and they are what a busy user meets, because a page that makes twenty requests
  meets the p95 about once per page.
- **max**: the single slowest. Useful as a warning and useless as a target; one stall of the
  machine sets it.

**There is no average in that list on purpose.** An average of latencies mixes the fast majority
with the slow few and describes neither: a hundred requests at 10 ms and one at 2 seconds average
30 ms, a number no request took. Lesson 7 comes back to this when the box office reports its own
latencies.

## Adding workers

One worker leaves the box office idle while each answer travels back and the next request travels
in. More workers keep it busy. Here is the same sale with 1, 2, 4 and up to 64 workers sending at
once:

```
ana@lab:~/tickets$ python3 load.py -m POST -c 1 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1149 in 10.0 s = 114.8 per second
latency   p50 8.0 ms  p95 12.6 ms  p99 15.6 ms  max 25.0 ms
status    201: 1149
ana@lab:~/tickets$ python3 load.py -m POST -c 2 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1572 in 10.0 s = 157.1 per second
latency   p50 7.9 ms  p95 45.3 ms  p99 49.3 ms  max 55.3 ms
status    201: 1572
ana@lab:~/tickets$ python3 load.py -m POST -c 4 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1476 in 10.0 s = 147.5 per second
latency   p50 11.4 ms  p95 75.6 ms  p99 81.1 ms  max 93.5 ms
status    201: 1476
ana@lab:~/tickets$ python3 load.py -m POST -c 8 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1471 in 10.0 s = 146.5 per second
latency   p50 75.6 ms  p95 96.1 ms  p99 102.4 ms  max 179.6 ms
status    201: 1471
ana@lab:~/tickets$ python3 load.py -m POST -c 16 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1437 in 10.0 s = 143.3 per second
latency   p50 103.1 ms  p95 196.4 ms  p99 262.6 ms  max 333.8 ms
status    201: 1437
ana@lab:~/tickets$ python3 load.py -m POST -c 32 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1483 in 10.1 s = 146.3 per second
latency   p50 204.3 ms  p95 384.5 ms  p99 499.7 ms  max 783.7 ms
status    201: 1483
ana@lab:~/tickets$ python3 load.py -m POST -c 64 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1400 in 10.2 s = 137.8 per second
latency   p50 407.9 ms  p95 797.3 ms  p99 1778.3 ms  max 3179.8 ms
status    201: 1400
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Two charts of the same seven runs, with 1, 2, 4, 8, 16, 32 and 64 workers. On the left, tickets sold per second rise from 115 to 157 between one and two workers and then stay between 138 and 148. On the right, the median latency stays near 8 milliseconds up to two workers and then doubles each time the workers double, reaching 408 milliseconds at 64.\"><text x=\"205.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">tickets per second</text><path d=\"M70 40 L70 240\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M70 240 L340 240\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"64\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><text x=\"88.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"127.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"166.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"205.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><text x=\"244.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">16</text><text x=\"283.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">32</text><text x=\"322.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">64</text><path d=\"M88.0 125.2 L127.0 82.9 L166.0 92.5 L205.0 93.5 L244.0 96.7 L283.0 93.7 L322.0 102.2\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"88.0\" cy=\"125.2\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"88.0\" y=\"113.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">115</text><circle cx=\"127.0\" cy=\"82.9\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"127.0\" y=\"70.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">157</text><circle cx=\"166.0\" cy=\"92.5\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"166.0\" y=\"80.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">148</text><circle cx=\"205.0\" cy=\"93.5\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"205.0\" y=\"81.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">146</text><circle cx=\"244.0\" cy=\"96.69999999999999\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"244.0\" y=\"84.69999999999999\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">143</text><circle cx=\"283.0\" cy=\"93.69999999999999\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"283.0\" y=\"81.69999999999999\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">146</text><circle cx=\"322.0\" cy=\"102.19999999999999\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"322.0\" y=\"90.19999999999999\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">138</text><text x=\"205.0\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">workers</text><text x=\"555.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">median latency, ms</text><path d=\"M420 40 L420 240\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M420 240 L690 240\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"414\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"414\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">450</text><text x=\"438.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"477.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"516.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"555.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><text x=\"594.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">16</text><text x=\"633.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">32</text><text x=\"672.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">64</text><path d=\"M438.0 236.4 L477.0 236.5 L516.0 234.9 L555.0 206.4 L594.0 194.2 L633.0 149.2 L672.0 58.7\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"438.0\" cy=\"236.44444444444446\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"438.0\" y=\"224.44444444444446\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">8</text><circle cx=\"477.0\" cy=\"236.48888888888888\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"477.0\" y=\"224.48888888888888\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">8</text><circle cx=\"516.0\" cy=\"234.93333333333334\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"516.0\" y=\"222.93333333333334\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">11</text><circle cx=\"555.0\" cy=\"206.4\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"555.0\" y=\"194.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">76</text><circle cx=\"594.0\" cy=\"194.17777777777778\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"594.0\" y=\"182.17777777777778\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">103</text><circle cx=\"633.0\" cy=\"149.2\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"633.0\" y=\"137.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">204</text><circle cx=\"672.0\" cy=\"58.71111111111111\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"672.0\" y=\"46.71111111111111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">408</text><text x=\"555.0\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">workers</text><text x=\"360\" y=\"304\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the knee: past two workers, more load only makes the queue longer</text></svg>", "caption": "The same box office, one processor, more and more workers. Throughput stops at the knee; latency keeps going."}
```

Two things happen, and they are the shape every system has.

**Throughput rises, then stops.** From one worker to two it goes from 115 to 157 a second, because
the box office no longer waits for the network between requests. From then on it stays near 145,
with 4 workers or with 64. One processor's worth of time, which is what `cpus: 1` gives the
container, signs about 150 tickets a second, and nothing the load generator does changes that.

**Latency stays flat, then climbs in proportion.** Up to the point where throughput stops rising,
each request takes about as long as the work it needs. Past it, every extra worker is one more
request waiting for the processor, and the median doubles each time the workers double: 103 ms at
16, 204 at 32, 408 at 64. **The extra load did not make the box office do more; it made the queue
longer.** That is the knee of the curve, and finding it is the first measurement to make on any
system.

The numbers are tied together by a rule this course meets again in lesson 11: with 16 requests
always in the system and 143 leaving every second, each spends 16 ÷ 143 ≈ 0.11 seconds inside,
which is the latency printed. When throughput is flat, latency is just the number of requests
waiting divided by the rate they leave at.

## The bottleneck, named

The curve says the box office stopped keeping up near 150 sales a second. It does not say why, and
"the processor" is a guess until something confirms it. `docker stats` in a second terminal, while
a test with 16 workers runs, shows each container's share of a processor and its memory:

```
ana@lab:~/tickets$ docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
NAME            CPU %     MEM USAGE / LIMIT
tickets-lb-1    2.30%     2.77MiB / 15.72GiB
tickets-app-1   100.12%   25.68MiB / 15.72GiB
tickets-db-1    10.74%    59.79MiB / 15.72GiB
```

`100.12%` is one whole processor, all that `cpus: 1` allows, while the database uses a tenth of
one and nginx almost nothing. **The processor of the box office is the bottleneck**, and the next
two sections give it more processors in the two ways there are.
