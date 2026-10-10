---
title: More than it can do
version: 1
---

Every system has a rate it can sustain, and sooner or later somebody asks for more: an on-sale at
ten in the morning, a bot buying a whole show, a retry storm after a short outage. The question of
this lesson is not how to make the box office faster. Lessons 1 to 3 did that. It is **what the box
office does when the demand is larger than any amount of capacity it has**.

Start by watching it fail. This is the box office exactly as lesson 8 left it, with no guard of any
kind, and lesson 1's `load.py` buying tickets with 8, 32 and then 128 workers:

```
ana@lab:~/tickets$ python3 load.py -m POST -d 10 'http://localhost:8080/events/{event}/tickets' --events 50 -c 8
requests  1129 in 10.0 s = 112.5 per second
latency   p50 70.1 ms  p95 102.9 ms  p99 134.7 ms  max 264.9 ms
status    201: 1129
ana@lab:~/tickets$ python3 load.py -m POST -d 10 'http://localhost:8080/events/{event}/tickets' --events 50 -c 32
requests  1073 in 10.2 s = 105.0 per second
latency   p50 295.3 ms  p95 487.5 ms  p99 595.8 ms  max 693.5 ms
status    201: 1073
ana@lab:~/tickets$ python3 load.py -m POST -d 10 'http://localhost:8080/events/{event}/tickets' --events 50 -c 128
requests  1149 in 11.0 s = 104.3 per second
latency   p50 950.8 ms  p95 2729.2 ms  p99 3928.7 ms  max 4936.2 ms
status    201: 1003  500: 146
ana@lab:~/tickets$ docker compose logs app --no-log-prefix | grep -m1 '"error"'
{"time": "2026-10-10T07:23:06.826+00:00", "level": "error", "message": "request failed", "host": "6e2c7859899e", "method": "POST", "route": "/events/{id}/tickets", "error": "OperationalError: connection failed: connection to server at \"172.19.0.5\", port 5432 failed: FATAL:  sorry, too many clients already", "trace_id": "5e0dd9e9d37e77e98439c79b0c1dbb15"}
ana@lab:~/tickets$ docker compose exec db psql -U tickets -tAc "SELECT count(*) FROM pg_stat_activity WHERE backend_type = 'client backend'"
52
```

Three things happen, and they happen in this order on every system.

**The rate stops growing.** 112, 105 and 104 sales a second: the box office's one CPU was already
busy at 8 workers. More workers bring no more sales.

**The waiting grows instead.** Each worker waits for its answer before asking again, so the requests
in flight are always the number of workers, and each one waits its turn. The median sale took 70 ms
with 8 workers, 295 ms with 32 and 951 ms with 128: roughly the number of workers divided by the
rate, which is Little's law, and lesson 11 comes back to it. Nothing is broken yet. Everything is
just slower.

**Then the overload moves somewhere else.** At 128 workers, 146 sales failed with a 500, and the
log says why: **PostgreSQL refused connections**, `too many clients already`. The box office answers
each connection nginx opens in a thread of its own, and each thread opens its own connection to the
database the first time it needs one. 128 workers make nginx open about 128 connections to the box
office, so about 128 threads ask for database connections, and PostgreSQL's default limit is 100.
After the run, with most of those threads gone, 52 connections were left, `psql`'s own included.

That last step is the one to remember. **A box office short of CPU turned into a database short of
connections**, and the error a buyer saw named neither. Overload spreads along whatever is not
bounded, and in this box office nothing was: not the threads, not the connections, not how often one
buyer may ask. The rest of the lesson puts a bound on each.
