---
title: Three shapes on the box office
version: 1
---

Three of the five shapes fit in a minute each, and running them against the box office shows the
thing a table cannot: **the same request, on the same machine, takes twenty milliseconds or twelve
seconds depending only on how many others arrive with it.** Every run asks for `GET /shows/990`,
the show page from lesson 1 that counts its bookings among almost three hundred thousand rows.

Start the box office in one terminal, from `~/boxoffice`, and leave it running:

```sh
cd ~/boxoffice && python3 seed.py && python3 app.py
```

Then type the runs below in a second terminal (`multipass shell nft`), in `~/loadtest`. Wait for
each one to print its last line before starting the next: a run that ended with requests still
inside the server leaves them there for a few seconds more.

## A steady load

Ten requests a second for five seconds, which the box office should carry without noticing:

```
ana@nft:~/loadtest$ python3 hammer.py http://127.0.0.1:8000/shows/990 10:5
second  sent  done  errors  median ms  max ms
     0    10    10       0         23      68
     1    10    10       0         20      25
     2    10    10       0         19      30
     3    10    10       0         29      78
     4    10    10       0         23      33
0 answers came back after second 4; the last at 4.9 s
```

Every request came back, none failed, and the median stayed between 19 and 29 ms, close to what a
single request took in lesson 1. **`done` equals `sent` in every second**: the server answered as
fast as the requests arrived. That is what a passing load test looks like in miniature, and it is
the baseline the other two runs are read against.

## A spike

Three seconds at ten a second, two seconds at two hundred, then three at ten again:

```
ana@nft:~/loadtest$ python3 hammer.py http://127.0.0.1:8000/shows/990 10:3 200:2 10:3
second  sent  done  errors  median ms  max ms
     0    10    10       0         25      55
     1    10    10       0         21      25
     2    10    10       0         22      37
     3   200    53       0       1000    4160
     4   200    70      10       2496   12051
     5    10    93       0        923    3138
     6    10    83       0        439    2071
     7    10    81       0        227    1093
50 answers came back after second 7; the last at 16.5 s
```

Read it a column at a time. In second 3 the box office was sent 200 requests and answered 53; in
second 4, 70. The rest waited, and the median for requests sent in second 4 is 2496 ms, more than a
hundred times the steady run's. Ten of them failed. Then look at seconds 5 to 7, **where the load is
back to ten a second and the times are still not**: 923, 439 and 227 ms at the median, because the
server was still working off the queue the spike had left. Fifty answers came back after the
schedule had ended, the last at 16.5 s into an eight-second run.

This is the half of a spike test that a quick glance at the peak misses. A customer who arrived at
second 6, at an ordinary moment, waited around half a second for a page that takes twenty
milliseconds, and the requirement from lesson 1 would have failed for them.

## A stress staircase

Two seconds at each of six rates, from 40 a second to 240:

```
ana@nft:~/loadtest$ python3 hammer.py http://127.0.0.1:8000/shows/990 40:2 80:2 120:2 160:2 200:2 240:2
second  sent  done  errors  median ms  max ms
     0    40    39       0         20      64
     1    40    41       0         21      45
     2    80    75       0         22      95
     3    80    73       0        126    5416
     4   120    76       0        466   11404
     5   120    69       3        583   15105
     6   160    83      16       1437   14110
     7   160    90      20       2545   15135
     8   200   100      29       4017   15133
     9   200   113      17       2778   13625
    10   240   139      23       3171   14105
    11   240    79      26       2331   12064
703 answers came back after second 11; the last at 25.0 s
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-stress\" aria-label=\"The stress run drawn second by second. The requests sent climb in steps from 40 to 240 a second. The answers that came back follow them up to 75 a second at second 2, then stop following: between 69 and 139 a second for the rest of the run, whatever was sent. Errors start at second 5 with 3, and are between 16 and 29 a second from second 6 on.\"><path d=\"M90.0 240.0 L570.0 240.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M90.0 30.0 L90.0 240.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M86.0 240.0 L90.0 240.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M86.0 198.0 L90.0 198.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"198.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">50</text><path d=\"M90.0 198.0 L570.0 198.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M86.0 156.0 L90.0 156.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"156.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100</text><path d=\"M90.0 156.0 L570.0 156.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M86.0 114.0 L90.0 114.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"114.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">150</text><path d=\"M90.0 114.0 L570.0 114.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M86.0 72.0 L90.0 72.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"72.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">200</text><path d=\"M90.0 72.0 L570.0 72.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M86.0 30.0 L90.0 30.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">250</text><path d=\"M90.0 30.0 L570.0 30.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"110.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"150.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"190.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"230.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"270.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"310.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"350.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"390.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7</text><text x=\"430.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8</text><text x=\"470.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">9</text><text x=\"510.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><text x=\"550.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">11</text><text x=\"330.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">second of the run</text><text x=\"56.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">per second</text><rect x=\"300.0\" y=\"237.5\" width=\"20.0\" height=\"2.5\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"340.0\" y=\"226.6\" width=\"20.0\" height=\"13.4\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"380.0\" y=\"223.2\" width=\"20.0\" height=\"16.8\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"420.0\" y=\"215.6\" width=\"20.0\" height=\"24.4\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"460.0\" y=\"225.7\" width=\"20.0\" height=\"14.3\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"500.0\" y=\"220.7\" width=\"20.0\" height=\"19.3\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"540.0\" y=\"218.2\" width=\"20.0\" height=\"21.8\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M90.0 206.4 L130.0 206.4 L130.0 206.4 L170.0 206.4 L170.0 172.8 L210.0 172.8 L210.0 172.8 L250.0 172.8 L250.0 139.2 L290.0 139.2 L290.0 139.2 L330.0 139.2 L330.0 105.6 L370.0 105.6 L370.0 105.6 L410.0 105.6 L410.0 72.0 L450.0 72.0 L450.0 72.0 L490.0 72.0 L490.0 38.4 L530.0 38.4 L530.0 38.4 L570.0 38.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M110.0 207.2 L150.0 205.6 L190.0 177.0 L230.0 178.7 L270.0 176.2 L310.0 182.0 L350.0 170.3 L390.0 164.4 L430.0 156.0 L470.0 145.1 L510.0 123.2 L550.0 173.6\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><circle cx=\"110.0\" cy=\"207.2\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"150.0\" cy=\"205.6\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"190.0\" cy=\"177.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"230.0\" cy=\"178.7\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"270.0\" cy=\"176.2\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"310.0\" cy=\"182.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"350.0\" cy=\"170.3\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"390.0\" cy=\"164.4\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"430.0\" cy=\"156.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"470.0\" cy=\"145.1\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"510.0\" cy=\"123.2\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"550.0\" cy=\"173.6\" r=\"3\" fill=\"var(--phosphor)\"></circle><path d=\"M588.0 60.0 L610.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\"></path><text x=\"616.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sent</text><path d=\"M588.0 84.0 L610.0 84.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"616.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">done: the throughput</text><rect x=\"593.0\" y=\"102.0\" width=\"12.0\" height=\"12.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"616.0\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">errors</text><text x=\"588.0\" y=\"147.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">from second 3 the</text><text x=\"588.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">answers stop following</text><text x=\"588.0\" y=\"172.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what was sent</text></svg>", "caption": "What the stress run sent, what came back, and what failed, second by second. The gap between the dashed line and the solid one is a queue growing inside the server."}
```

Up to 80 a second the server keeps up. **From second 3 the `done` column stops following `sent`**:
it stays between 69 and 139 answers a second while the load doubles and then triples. The gap
between the two is a queue, and the medians show it growing, from 126 ms in second 3 to over two
seconds by second 7. Errors start in second 5 with 3, and from there run between 16 and 29 a
second. Seven hundred and three answers were still arriving after the schedule ended, the last at
25.0 s.

So the breaking point of `GET /shows/990` on this machine sits somewhere around 80 requests a
second, and the manner is the bad one from "Five tests, five questions": nothing refuses the
excess quickly, every request joins the queue, the times climb into seconds, and errors arrive on
top of them. A number like that comes from one short run on a shared machine, and yours will
differ. Lesson 8 is about how to read it with more care than "about 80".

## The soak that is not here

A soak test is this generator with one stage, `10:28800`, left overnight. It is not run in this
lesson; nothing about the box office should change at ten requests a second, and finding out
takes eight hours. What a soak test watches is not in this output either: the server's memory,
its open files, the size of its database. Those are measurements of the server rather than of the
responses, and lesson 22 collects them.
