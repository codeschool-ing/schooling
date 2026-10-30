---
title: Concurrency, and what one instance can carry
version: 1
---

Many function platforms taught a generation that one instance serves one request. **Cloud Run does
not: one instance serves up to 80 requests at the same time by default, and up to 1,000 if you
allow it.** That single setting, `max_instance_request_concurrency`, decides how many instances a
burst needs, and so most of the bill and most of the cold starts.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Twenty requests arrive at the same moment. With a concurrency of 1, Cloud Run needs twenty instances, drawn as twenty small boxes, each holding one request. With a concurrency of 80, one instance holds all twenty requests, and there is room for sixty more.\"><defs><marker id=\"l11-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">concurrency 1: twenty instances</text><rect x=\"30\" y=\"50\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"55\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"92\" y=\"50\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"117\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"154\" y=\"50\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"179\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"216\" y=\"50\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"241\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"278\" y=\"50\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"303\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"30\" y=\"106\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"55\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"92\" y=\"106\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"117\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"154\" y=\"106\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"179\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"216\" y=\"106\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"241\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"278\" y=\"106\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"303\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"30\" y=\"162\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"55\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"92\" y=\"162\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"117\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"154\" y=\"162\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"179\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"216\" y=\"162\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"241\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"278\" y=\"162\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"303\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"30\" y=\"218\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"55\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"92\" y=\"218\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"117\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"154\" y=\"218\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"179\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"216\" y=\"218\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"241\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"278\" y=\"218\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"303\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><path d=\"M360 30 L360 280\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"540\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">concurrency 80: one instance</text><rect x=\"420\" y=\"50\" width=\"240\" height=\"212\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"440\" y=\"66\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"482\" y=\"66\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"524\" y=\"66\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"566\" y=\"66\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"608\" y=\"66\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"440\" y=\"96\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"482\" y=\"96\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"524\" y=\"96\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"566\" y=\"96\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"608\" y=\"96\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"440\" y=\"126\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"482\" y=\"126\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"524\" y=\"126\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"566\" y=\"126\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"608\" y=\"126\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"440\" y=\"156\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"482\" y=\"156\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"524\" y=\"156\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"566\" y=\"156\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"608\" y=\"156\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">20 requests in one instance</text><text x=\"540\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">room for 60 more</text></svg>", "caption": "The same twenty requests. Full is measured in requests, so the concurrency setting decides how many instances start, how many start cold, and how many are billed."}
```

## Measuring it at home

The orders service of lesson 8 answers each request on a thread of its own, and `ORDERS_DELAY_MS`
makes `/orders` wait as if for a database. This program sends requests and times them. Save it as
`~/gcp/load.py`:

```python
# load.py
"""Send N requests to URL, at most C at a time, and report how long they took."""
import sys
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor

url, n, c = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])


def one(_):
    started = time.perf_counter()
    urllib.request.urlopen(url).read()
    return time.perf_counter() - started


started = time.perf_counter()
with ThreadPoolExecutor(max_workers=c) as pool:
    times = sorted(pool.map(one, range(n)))
total = time.perf_counter() - started
print(f'{n} requests, {c} at a time: {total:.2f} s in all, '
      f'median {times[n // 2]:.3f} s, slowest {times[-1]:.3f} s')
```

Start the service with a wait of 200 milliseconds per request, then send twenty requests three ways:
one at a time, twenty at once, and two hundred, eighty at a time:

```
ana@laptop:~/gcp$ docker run -d --name orders-slow -p 8080:8080 -e ORDERS_DELAY_MS=200 orders:1
866eca200a31325a6a0783e688c1e4e0a2a8c5bde59fe20cec787e064407833e
ana@laptop:~/gcp$ python3 load.py http://localhost:8080/orders 20 1
20 requests, 1 at a time: 4.07 s in all, median 0.202 s, slowest 0.223 s
ana@laptop:~/gcp$ python3 load.py http://localhost:8080/orders 20 20
20 requests, 20 at a time: 0.61 s in all, median 0.526 s, slowest 0.581 s
ana@laptop:~/gcp$ python3 load.py http://localhost:8080/orders 200 80
200 requests, 80 at a time: 2.21 s in all, median 0.209 s, slowest 2.062 s
```

On this laptop, **twenty requests one at a time took about four seconds, and twenty at once about
six tenths of a second**: the waits overlapped instead of adding up, because the requests were
waiting rather than computing, and waiting is the one thing threads share for free. One instance
carried all of it.

The other two numbers are the more useful ones. Twenty at once did not take 200 milliseconds each
but about half a second, and in the run of two hundred, eighty at a time, the median was still
about 200 milliseconds while **the slowest took two seconds**. The waiting was not the limit any
more; the program was. Python's `http.server` is a teaching server: it keeps a short queue of
connections waiting to be accepted, five by default, and a burst larger than that is turned away
and retried by the client, which is what a two-second request in a run of 200-millisecond ones
looks like. A production server such as gunicorn, lesson 19's, would carry more. **Concurrency on
Cloud Run is a ceiling; what one instance can actually carry is a property of your program**, and
this measurement is how you find it.

## What that means for the number of instances

Cloud Run starts a new instance when the ones running are full, and **full is measured in requests,
not in CPU**. With a concurrency of 1, the twenty simultaneous requests above would need twenty
instances, each started cold, each billed. With the default of 80, one instance takes them all and
the other nineteen never exist.

So the default is right for the common case, a service that spends most of each request waiting on
a database or another API. It is wrong in two cases, and both have a symptom:

- **the request computes**: resizing an image, rendering a PDF. Eighty of those on one vCPU take
  eighty times as long each, and latency climbs while the instance count stays at one. Lower the
  concurrency until each request has the CPU it needs; Cloud Run then starts more instances.
- **the program cannot handle concurrent requests**: a single-threaded server, or code with global
  state that is not safe across threads. Set the concurrency to 1, and accept the instances it
  costs, or fix the program.

**Measure before choosing**: run the service at home under `load.py` with the concurrency you plan
to allow, and watch what happens to the median and the slowest request. When the slowest pulls away
from the median, as it did above at eighty, the setting is above what the program can carry, and
Cloud Run would be better off starting a second instance.
