---
title: Why the mean misleads
version: 1
---

A load test does not hand back a response time. It hands back hundreds or thousands of them, one
per request, and every report you will ever read squeezes them into a few numbers. **Which few
numbers decides what the report can tell you**, and the one most people reach for first, the
average, is the one that tells you least about what the users waited.

The tools of lessons 4 to 7 each print their own summary. To see where those numbers come from,
this section uses a generator small enough to read in one sitting, written in Python with nothing
but the standard library. It sends requests from several threads at once, records every timing,
and prints the statistics a load test report prints, computed in the open.

Create it in `~/boxoffice` with `nano measure.py`. The copy button takes the whole file without
the notes.

```schooling-example
{"language": "python", "file": "boxoffice/measure.py", "parts": [{"code": "# boxoffice/measure.py\n# A small load generator: WORKERS threads ask boxoffice for shows, and book\n# seats now and then, for SECONDS, then report what a load test reports.\n#   python3 measure.py WORKERS SECONDS [BOOKING_SHARE]\nimport http.client, json, math, random, sys, threading, time\n\nworkers, seconds = int(sys.argv[1]), float(sys.argv[2])\nshare = float(sys.argv[3]) if len(sys.argv) > 3 else 0.0\nresults, lock = [], threading.Lock()\n", "note": "Standard library only, like the box office. Three arguments: how many workers send at once, for how many seconds, and what share of the requests are bookings (0.2 is one in five; leave it out and none are)."}, {"code": "def worker(n):\n    rnd = random.Random(n)\n    stop = time.perf_counter() + seconds\n    while time.perf_counter() < stop:\n        show = rnd.randint(981, 1000)\n        if rnd.random() < share:\n            kind, method, path = \"book\", \"POST\", \"/bookings\"\n            body = json.dumps({\"show_id\": show, \"seat\": rnd.randint(1, 300), \"customer\": f\"w{n}\"})\n        else:\n            kind, method, path, body = \"show\", \"GET\", f\"/shows/{show}\", None\n        start = time.perf_counter()\n        conn = http.client.HTTPConnection(\"127.0.0.1\", 8000, timeout=30)\n        try:\n            conn.request(method, path, body)\n            answer = conn.getresponse()\n            answer.read()\n            status = answer.status\n        except OSError:\n            status = \"failed\"\n        conn.close()\n        with lock:\n            results.append((kind, status, (time.perf_counter() - start) * 1000))\n", "note": "Each worker loops until time is up. It picks a show on sale, books a random seat or looks at the show, and times the request from just before it connects to just after the last byte of the answer. **It opens a new connection for every request**, as `curl` does; lesson 9 shows what changes when one connection is kept. A request that fails to connect is recorded as `failed` rather than dropped, because a failure the report never sees is a failure that did not happen."}, {"code": "def rank(ordered, p):\n    \"\"\"The nearest-rank percentile: the value at position ceil(p/100 * n).\"\"\"\n    return ordered[max(1, math.ceil(p / 100 * len(ordered))) - 1]\n", "note": "The percentile, by the nearest-rank method: sort the times, and the p-th percentile is the value at position p/100 × n, rounded up. \"Percentiles by hand\" works it with a pencil."}, {"code": "threads = [threading.Thread(target=worker, args=(n,)) for n in range(workers)]\nbegan = time.perf_counter()\nfor t in threads:\n    t.start()\nfor t in threads:\n    t.join()\nelapsed = time.perf_counter() - began\n", "note": "Start every worker, wait for all of them, and keep the real elapsed time, which is a little longer than the time asked for because the last requests finish after it."}, {"code": "print(f\"{workers} workers, {elapsed:.1f} s: {len(results)} requests, \"\n      f\"{len(results) / elapsed:.1f} per second\")\nstatuses = sorted({str(s) for _, s, _ in results})\nprint(\"status: \" + \", \".join(f\"{s} x{sum(str(r[1]) == s for r in results)}\" for s in statuses))\nprint(f\"{'ms':10} {'count':>6} {'mean':>7} {'median':>7} {'p90':>7} {'p95':>7} {'p99':>7} {'max':>7}\")\nfor label, kind in ((\"all\", None), (\"GET show\", \"show\"), (\"POST book\", \"book\")):\n    ms = sorted(t for k, _, t in results if kind in (None, k))\n    if ms:\n        cells = [sum(ms) / len(ms)] + [rank(ms, p) for p in (50, 90, 95, 99, 100)]\n        print(f\"{label:10} {len(ms):6} \" + \" \".join(f\"{c:7.1f}\" for c in cells))\n", "note": "The report: throughput, the count of each status code, then one row for all requests and one per operation, each with its mean, median, p90, p95, p99 and maximum."}, {"code": "ms = sorted(t for _, _, t in results)\nmean = sum(ms) / len(ms)\nnear = sum(abs(t - mean) <= 0.1 * mean for t in ms)\nprint(f\"within 10% of the mean: {near} of {len(ms)} requests\")\nprint(\"histogram, 20 ms bins\")\nfor low in range(0, 220, 20):\n    count = sum(low <= t < low + 20 for t in ms) if low < 200 else sum(t >= 200 for t in ms)\n    label = f\"{low:3}-{low + 20:3} ms\" if low < 200 else \"200 ms and up\"\n    print(f\"  {label}  {count:5} {'#' * math.ceil(50 * count / len(ms))}\".rstrip())", "note": "Two things a report rarely prints. How many requests took a time close to the mean, within 10% either side of it. And a histogram in 20 ms bins, with everything from 200 ms up in one bin, so the shape is visible in the terminal."}]}
```

Start the box office in one terminal, as in lesson 1, with `python3 app.py` in `~/boxoffice`.
In the second terminal, run eight workers for ten seconds, with one request in five a booking:

```
ana@nft:~/boxoffice$ python3 measure.py 8 10 0.2
8 workers, 10.4 s: 653 requests, 63.1 per second
status: 200 x520, 201 x105, 409 x28
ms          count    mean  median     p90     p95     p99     max
all           653   124.5    32.0   456.4   523.9   866.6  1071.0
GET show      520    36.0    27.4    56.5    71.0   105.2  1043.7
POST book     133   470.4   455.5   614.2   845.6  1020.0  1071.0
within 10% of the mean: 2 of 653 requests
histogram, 20 ms bins
    0- 20 ms     91 #######
   20- 40 ms    311 ########################
   40- 60 ms     75 ######
   60- 80 ms     26 ##
   80-100 ms     12 #
  100-120 ms      3 #
  120-140 ms      1 #
  140-160 ms      1 #
  160-180 ms      1 #
  180-200 ms      0
  200 ms and up    132 ###########
```

Read the table from the top. The ten seconds produced 653 requests. Of those, 520 were looks at a
show, 105 were bookings that succeeded and 28 were bookings of a seat somebody already had. The
row `all` says the mean response time was 124.5 ms and the median 32.0 ms.

**Those two numbers describe different requests, and neither describes the bookings.** The median
is the time half the requests stayed under: 32.0 ms, which is a look at a show on a busy machine.
The mean is pulled up by the 132 requests that took 200 ms or more, nearly all of them bookings,
and lands at 124.5 ms, where almost nothing happened. The line under the table counts how many
requests took within 10% of the mean, between about 112 and 137 ms: **2 of 653**. The histogram
shows the same thing as a shape. The tallest bar is 20 to 40 ms, the long bar at the bottom is
200 ms and up, and the bin from 120 to 140 ms, where the mean falls, holds one request.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" data-fig=\"l08-distribution\" aria-label=\"A histogram of 653 response times from one load test, in bins of 20 milliseconds. Most requests are on the left: 91 under 20 ms, 311 between 20 and 40, 75 between 40 and 60, then a thinning tail, and 132 requests at 200 ms or more, drawn as one bar on the far right. The median, 32.0 ms, sits inside the tallest bar. The mean, 124.5 ms, is a dashed line over the bin from 120 to 140 ms, which holds one request. The 95th percentile, 523.9 ms, lies inside the bar of 200 ms and up.\"><path d=\"M60.0 250.0 L580.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"63.0\" y=\"197.3\" width=\"46.0\" height=\"52.7\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"86.0\" y=\"188.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">91</text><rect x=\"115.0\" y=\"70.0\" width=\"46.0\" height=\"180.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"138.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">311</text><rect x=\"167.0\" y=\"206.6\" width=\"46.0\" height=\"43.4\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"190.0\" y=\"197.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">75</text><rect x=\"219.0\" y=\"235.0\" width=\"46.0\" height=\"15.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"242.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">26</text><rect x=\"271.0\" y=\"243.1\" width=\"46.0\" height=\"6.9\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"294.0\" y=\"234.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">12</text><rect x=\"323.0\" y=\"248.3\" width=\"46.0\" height=\"1.7\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"346.0\" y=\"239.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">3</text><rect x=\"375.0\" y=\"249.4\" width=\"46.0\" height=\"0.6\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"398.0\" y=\"240.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1</text><rect x=\"427.0\" y=\"249.4\" width=\"46.0\" height=\"0.6\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"450.0\" y=\"240.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1</text><rect x=\"479.0\" y=\"249.4\" width=\"46.0\" height=\"0.6\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"502.0\" y=\"240.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1</text><text x=\"554.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><text x=\"60.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"164.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><text x=\"268.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">80</text><text x=\"372.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">120</text><text x=\"476.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">160</text><text x=\"580.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200</text><text x=\"576.0\" y=\"282.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">response time, ms</text><path d=\"M610.0 250.0 L696.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"618.0\" y=\"173.6\" width=\"70.0\" height=\"76.4\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"653.0\" y=\"164.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">132</text><text x=\"653.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200+</text><text x=\"653.0\" y=\"205.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">p95</text><text x=\"653.0\" y=\"218.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">523.9</text><path d=\"M143.2 52.0 L143.2 44.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"149.2\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">median 32.0 ms</text><path d=\"M383.7 250.0 L383.7 106.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"389.7\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">mean 124.5 ms</text><text x=\"389.7\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">one request lives here</text></svg>", "caption": "Where 653 requests actually landed. The mean is the one place almost none of them did."}
```

A mean is the right statistic for a quantity that adds up, such as the total time a machine spent
busy. Response times are not like that. They arrive in clusters, here two: the quick reads and
the slow bookings. **A mean of two clusters is a point between them**, and a requirement written
against it can be met by making the fast requests faster while the slow ones get worse.

## The percentiles say who waited how long

The other columns are percentiles. The p95 of `all` is 523.9 ms: 95 of every 100 requests took
that long or less, and 5 took longer. The p99 is 866.6 ms, the time one request in a hundred went
past. The maximum, 1071.0 ms, is one request, the slowest of the run, and it moves a long way
between runs.

**Each percentile is a statement about people**, which is why lesson 1 wrote the requirement as
one. A visit to the booking page is several requests, not one. If it makes eight, and each has a
5% chance of being slower than the p95, the chance that all eight stay under it is 0.95 to the
eighth power, about 66%: **one visit in three meets at least one answer from the tail.** The tail is what a
busy user meets, not a rare accident.

## One row per operation

The two rows below `all` split the same requests by what they did:

| | count | mean | median | p95 |
|---|---|---|---|---|
| `GET show` | 520 | 36.0 | 27.4 | 71.0 |
| `POST book` | 133 | 470.4 | 455.5 | 845.6 |

They are two different services sharing one address. Looking at a show is fast, and booking is
slow by more than a factor of ten, because bookings wait for each other; lesson 9 finds where. The
`all` row averages a fast operation with a slow one in the proportion this test happened to send,
four to one. **Change the mix and the `all` row moves although nothing in the system changed**,
which is why lesson 1 named one operation per requirement.
