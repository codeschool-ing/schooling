---
title: Clients that wait
version: 1
---

Lesson 9 refused excess work with `429` and `503` and a `Retry-After`, and found that a refusal only
lowers the load if the caller listens. `load.py` did not: a refused worker asked again at once. Here
it is with an option to listen, `--polite`, which applies this lesson to the caller's side. Save it
over the old `load.py`:

```schooling-example
{"language": "python", "file": "load.py", "parts": [{"code": "# load.py\n\"\"\"A closed-loop load generator: each worker sends a request, waits, sends the next.\nWith --polite, a worker that is refused waits as long as Retry-After asks, and a\nrandom part of that again, before asking.\"\"\"\nimport argparse\nimport http.client\nimport random\nimport threading\nimport time\nfrom collections import Counter\nfrom urllib.parse import urlsplit", "note": "Lesson 1's load generator, with one addition."}, {"code": "\np = argparse.ArgumentParser()\np.add_argument(\"url\")\np.add_argument(\"-c\", \"--workers\", type=int, default=4)\np.add_argument(\"-d\", \"--seconds\", type=float, default=10)\np.add_argument(\"-m\", \"--method\", default=\"GET\")\np.add_argument(\"--events\", type=int, default=1)\np.add_argument(\"--polite\", action=\"store_true\")\nargs = p.parse_args()", "note": "`--polite` turns it on."}, {"code": "\nu = urlsplit(args.url)\nlatencies, statuses, lock = [], Counter(), threading.Lock()\ndeadline = time.monotonic() + args.seconds"}, {"code": "\n\ndef worker(n):\n    conn = http.client.HTTPConnection(u.hostname, u.port, timeout=10)\n    mine, seen, i = [], Counter(), n\n    while time.monotonic() < deadline:\n        path = u.path.replace(\"{event}\", str(i % args.events + 1))\n        i += args.workers"}, {"code": "        start = time.monotonic()\n        try:\n            conn.request(args.method, path, headers={\"Content-Length\": \"0\"})\n            r = conn.getresponse()\n            r.read()\n        except OSError as e:\n            seen[type(e).__name__] += 1\n            conn.close()\n            conn = http.client.HTTPConnection(u.hostname, u.port, timeout=10)\n            continue"}, {"code": "        mine.append(time.monotonic() - start)\n        seen[r.status] += 1\n        if args.polite and r.status in (429, 503):\n            wait = float(r.getheader(\"Retry-After\") or 1)\n            time.sleep(wait * random.uniform(1, 2))", "note": "**A polite worker that is refused waits** as long as `Retry-After` says, times a random factor between one and two, before its next request. The time is measured before the wait, so the latencies are still the box office's."}, {"code": "    with lock:\n        latencies.extend(mine)\n        statuses.update(seen)\n\n\nstarted = time.monotonic()\nthreads = [threading.Thread(target=worker, args=(n,)) for n in range(args.workers)]\nfor t in threads:\n    t.start()\nfor t in threads:\n    t.join()\nelapsed = time.monotonic() - started\n\nlatencies.sort()\n\n\ndef pct(q):\n    return latencies[min(len(latencies) - 1, int(q * len(latencies)))] * 1000\n\n\ntotal = sum(statuses.values())\nprint(f\"requests  {total} in {elapsed:.1f} s = {total / elapsed:.1f} per second\")\nif latencies:\n    print(f\"latency   p50 {pct(0.50):.1f} ms  p95 {pct(0.95):.1f} ms\"\n          f\"  p99 {pct(0.99):.1f} ms  max {latencies[-1] * 1000:.1f} ms\")\nprint(\"status    \" + \"  \".join(f\"{k}: {v}\" for k, v in sorted(statuses.items(), key=str)))"}]}
```

A policy with backoff and jitter, for a caller that was told how long to wait: wait that long, plus
a random fraction more, so that a thousand refused buyers do not all come back in the same second.

Now the overloaded box office of lesson 9, with 8 slots instead of 32 so that the waiting happens at
the door, and 128 workers buying for twenty seconds. First as before, then polite:

```
ana@lab:~/tickets$ docker compose up -d payments
 Container tickets-payments-1 Recreate 
 Container tickets-payments-1 Recreated 
 Container tickets-payments-1 Starting 
 Container tickets-payments-1 Started 
ana@lab:~/tickets$ MAX_IN_FLIGHT=8 docker compose up -d app
 Container tickets-replica-1 Running 
 Container tickets-redis-1 Running 
 Container tickets-db-1 Running 
 Container tickets-app-1 Recreate 
 Container tickets-app-1 Recreated 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-db-1 Waiting 
 Container tickets-replica-1 Waiting 
 Container tickets-replica-1 Healthy 
 Container tickets-db-1 Healthy 
 Container tickets-app-1 Starting 
 Container tickets-app-1 Started 
ana@lab:~/tickets$ python3 load.py -m POST 'http://localhost:8080/events/{event}/tickets' --events 50 -c 128 -d 20
requests  8797 in 20.4 s = 432.1 per second
latency   p50 252.6 ms  p95 712.3 ms  p99 1054.2 ms  max 1811.5 ms
status    201: 1493  503: 7304
ana@lab:~/tickets$ python3 load.py -m POST 'http://localhost:8080/events/{event}/tickets' --events 50 -c 128 -d 20 --polite
requests  3587 in 21.9 s = 163.7 per second
latency   p50 48.1 ms  p95 109.7 ms  p99 136.7 ms  max 190.6 ms
status    201: 1949  503: 1638
```

| | impatient | polite |
|---|---|---|
| sold | 1,493 | 1,949 |
| refused | 7,304 | 1,638 |
| median answer | 253 ms | 48 ms |
| 99th percentile | 1,054 ms | 137 ms |

**Same box office, same number of buyers, and 31% more tickets sold.** The impatient workers spent
the box office's one CPU on being refused: 7,304 times in twenty seconds, each one a connection, a
thread and a reply that sold nothing, while the sales waited behind them. The polite workers stayed
away for a second or two when they were told to, the refusals fell to under a quarter, and the sales that
were admitted ran at the speed of a box office that is busy rather than besieged.

That is backpressure working end to end: the box office says it is full, and the caller hears it.
Lesson 9 built the first half; this lesson is the second.
