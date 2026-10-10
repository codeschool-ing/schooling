---
title: Vertical scaling, a bigger machine
version: 1
---

**Vertical scaling gives the same program a bigger machine**: more processors, more memory, faster
storage. Nothing in the program changes, which is its great virtue. It is usually the first thing
to try and very often the right one.

On a real server it means a new machine, or stopping a virtual one and starting it again with a
larger size. In the lab, Docker can change a running container's share of the processors on the
spot. The box office starts with `cpus: 1`; here it gets two, then four, with the same test as
before, 16 workers buying tickets for a hundred shows:

```
ana@lab:~/tickets$ docker update --cpus 2 tickets-app-1
tickets-app-1
ana@lab:~/tickets$ python3 load.py -m POST -c 16 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  3159 in 10.1 s = 314.1 per second
latency   p50 50.2 ms  p95 91.4 ms  p99 104.9 ms  max 159.6 ms
status    201: 3159
ana@lab:~/tickets$ docker update --cpus 4 tickets-app-1
tickets-app-1
ana@lab:~/tickets$ python3 load.py -m POST -c 16 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  4345 in 10.0 s = 433.2 per second
latency   p50 35.8 ms  p95 66.0 ms  p99 85.5 ms  max 155.1 ms
status    201: 4345
ana@lab:~/tickets$ nproc
4
```

From one processor to two, sales go from 143 a second (the 16-worker run of the last section) to
314. **A little more than double**, and the extra is an artefact of the cap rather than a gift: a
container limited to one processor is paused for the rest of each tenth of a second once its
threads have used up their share, and sixteen busy threads use it up in bursts. With two, it is
paused less often.

From two to four, sales go to 433, not to 628. `nproc` gives the reason: **the machine has four
processors**, and the box office was not the only thing using them. The load generator, nginx and
PostgreSQL share the same four. Giving one container all of them took processor time from the
others, and the database and the load generator started to be part of the bottleneck. On a
virtual machine with two processors the step from two to four cannot be measured at all, because
there are not four to give.

## What a bigger machine buys

- **No change to the program.** The same code, the same database connection, the same
  everything. The box office has no idea it was moved.
- **No new kind of failure.** One machine fails in the ways one machine fails. Nothing has to agree
  with anything else across a network.
- **Every part of the work gets faster**, including the parts that cannot be divided, which
  section 09 shows is exactly what horizontal scaling cannot do.

## Where it ends

Vertical scaling has four limits, and each arrives at a different size:

- **The largest machine sold.** Cloud providers rent machines with hundreds of processors and
  terabytes of memory, and past that there is nothing to buy. Long before that,
- **the price stops being proportional.** A machine twice the size usually costs more than twice
  as much near the top of a range, and the top sizes are the scarcest.
- **One machine is one failure.** A bigger machine is a bigger thing to lose. When it stops,
  everything on it stops, and a bigger one takes longer to replace.
- **Changing size means a restart**, on most real platforms. `docker update` did it live; a
  virtual machine in a cloud usually has to be stopped, resized and started, which is an outage
  you schedule.

And there is a limit in the program, not the machine. **A program has to be able to use the
processors it is given.** The box office can, because `ThreadingHTTPServer` runs each connection in
a thread and `sign()` lets other threads run while it computes. A program that does its work on a
single thread would have stayed at one processor's worth whatever the machine had, and the step
from two to four would have shown nothing at all. Section 10 puts a number on that.
