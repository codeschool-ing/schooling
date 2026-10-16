---
title: Virtual users, think time and ramp-up
version: 1
---

A virtual user is a loop with a pause in it. **It sends a request, waits for the answer, thinks
for a while, and starts again**, and a closed-model test is nothing more than many of those loops
running at once. This section builds one, small enough to read, in `~/loadtest` beside lesson 2's
`hammer.py`. Open it with `nano users.py` and paste the file with the copy button:

```schooling-example
{"language": "python", "file": "loadtest/users.py", "parts": [{"code": "# loadtest/users.py\n# A closed workload: USERS virtual users, each sending a request, waiting for\n# the answer, thinking for THINK seconds and starting again. They start one by\n# one over RAMP seconds, and only the SECONDS after the ramp are measured.\n# Usage: python3 users.py URL USERS THINK RAMP SECONDS\nimport sys, threading, time, urllib.request\n\nurl, users = sys.argv[1], int(sys.argv[2])\nthink, ramp, seconds = (float(a) for a in sys.argv[3:6])\ndone = []                        # one (time it finished, seconds it took, ok) per request\ninside = [0]                     # requests sent and not yet answered, right now\ncounts = []                      # inside[0], read ten times a second\nlock = threading.Lock()\nt0 = time.perf_counter()\n", "note": "Five arguments, all of them the model: how many virtual users, how long each one thinks between requests, how long the ramp takes, and how long to measure after it. `inside` is the number of requests on their way at this instant, and `counts` keeps a reading of it every tenth of a second."}, {"code": "def user(n):\n    time.sleep(n * ramp / users)\n    while time.perf_counter() < t0 + ramp + seconds:\n        start = time.perf_counter()\n        with lock:\n            inside[0] += 1\n        try:\n            with urllib.request.urlopen(url, timeout=10) as answer:\n                answer.read()\n            ok = True\n        except Exception:\n            ok = False\n        with lock:\n            inside[0] -= 1\n            done.append((time.perf_counter() - t0, time.perf_counter() - start, ok))\n        time.sleep(think)\n", "note": "One virtual user. It waits for its place in the ramp, then loops: send, **wait for the answer**, think, send again. That wait is the whole difference from `hammer.py` in lesson 2. A user cannot send its next request while its last one is unanswered, so the number of requests in flight can never exceed the number of users."}, {"code": "def count():\n    time.sleep(ramp)\n    while time.perf_counter() < t0 + ramp + seconds:\n        counts.append(inside[0])\n        time.sleep(0.1)\n\nthreads = [threading.Thread(target=user, args=(n,)) for n in range(users)]\nthreads.append(threading.Thread(target=count))\nfor thread in threads:\n    thread.start()\nfor thread in threads:\n    thread.join()\n", "note": "A second kind of thread, which does nothing but count how many requests are in flight, ten times a second, once the ramp is over. That count is measured directly, so it can be compared with what Little's law predicts from the other numbers."}, {"code": "measured = [d for d in done if ramp <= d[0] < ramp + seconds]\nx = len(measured) / seconds                       # throughput, requests a second\nr = sum(d[1] for d in measured) / len(measured)   # mean response time, seconds\nprint(f\"{users} users, think {think} s, ramp {ramp} s, measured for {seconds} s\")\nprint(f\"requests {len(measured)}, errors {sum(1 for d in measured if not d[2])}\")\nprint(f\"throughput X        {x:7.1f} requests/s\")\nprint(f\"response time R     {r * 1000:7.1f} ms (mean)\")\nprint(f\"in flight, counted  {sum(counts) / len(counts):7.1f} requests at a time\")\nprint(f\"X × R               {x * r:7.1f} requests at a time\")\nprint(f\"X × (R + think)     {x * (r + think):7.1f} users\")", "note": "Only the requests that finished after the ramp count, so the start-up does not dilute the result. `X` is the throughput and `R` the mean response time. The last three lines are the check in \"Little's law\": the count of requests in flight beside `X × R`, and the number of users beside `X × (R + think)`."}]}
```

The arguments are the model: `URL USERS THINK RAMP SECONDS`. With the box office running in the
first terminal, as in lesson 2, start with ten users who each think for half a second, ramp them
up over two seconds, and measure for ten:

```
ana@nft:~/loadtest$ python3 users.py http://127.0.0.1:8000/shows/990 10 0.5 2 10
10 users, think 0.5 s, ramp 2.0 s, measured for 10.0 s
requests 194, errors 0
throughput X           19.4 requests/s
response time R        14.0 ms (mean)
in flight, counted      0.2 requests at a time
X × R                   0.3 requests at a time
X × (R + think)        10.0 users
```

Ten users, each going round a loop of 14.0 ms of waiting on average and 500 ms of thinking, sent
19.4 requests a second between them. **The throughput was decided by the users, not by the server**: it
answered each request in a few milliseconds and then sat idle until somebody asked again. On
average only 0.2 requests were in flight at any moment.

## Think time

Think time is the pause between an answer and the user's next request, the seconds a real person
spends reading the page, choosing a seat, typing a name. It is the most important number in a
closed model, and the easiest to get wrong. **Set it to zero and every virtual user becomes a
program clicking as fast as the server answers**, which no person does:

```
ana@nft:~/loadtest$ python3 users.py http://127.0.0.1:8000/shows/990 100 0 5 30
100 users, think 0.0 s, ramp 5.0 s, measured for 30.0 s
requests 4200, errors 22
throughput X          140.0 requests/s
response time R       704.7 ms (mean)
in flight, counted     99.9 requests at a time
X × R                  98.7 requests at a time
X × (R + think)        98.7 users
```

A hundred users with no think time kept the server permanently full. On average 99.9 of them were
waiting for an answer at every count, the mean response time rose to 704.7 ms, 22 requests failed,
and the throughput was 140.0 requests a second, because that is what the server could finish. A hundred real
people thinking for four seconds each would have asked for about 25 requests a second. The two
tests have the same number of users and describe completely different loads.

Where does a realistic think time come from? From the same place as the requirement in lesson 1:
production logs, which show the gap between one request and the next from the same session, or
analytics, which show how long people stay on each page. Without either, a few seconds per page is
a defensible guess, written down as a guess. A fixed think time also makes every user tick in step,
so tools let it vary at random around its mean; JMeter's timers in lesson 4 do exactly that.

## Pacing

Think time is measured from the end of one request to the start of the next. **Pacing is measured
from the start of one iteration to the start of the next**: each virtual user begins a new pass
every N seconds, however long the last one took, and sleeps only for whatever is left. With
pacing, a slower server does not reduce the rate at which each user starts, until a pass takes
longer than N and there is nothing left to sleep. It is a way to hold a closed model nearer to a
rate, and `users.py` does not implement it; lesson 4 shows a JMeter timer that does.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l03-timeline\" aria-label=\"One virtual user over time, drawn twice. Above, with think time: each request is followed by its response time, then a fixed think time measured from the end of the answer, so a slow answer, drawn as the second, longer response, pushes every later request back. Below, with pacing: a new iteration starts at fixed intervals measured from start to start, and the sleep shrinks to fill whatever the response left, so the slow answer does not move the next start.\"><defs><marker id=\"l03-timeline-nf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20.0\" y=\"75.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">think time</text><rect x=\"120.0\" y=\"66.0\" width=\"40.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><path d=\"M160.0 75.0 L260.0 75.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\"></path><rect x=\"260.0\" y=\"66.0\" width=\"110.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><path d=\"M370.0 75.0 L470.0 75.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\"></path><rect x=\"470.0\" y=\"66.0\" width=\"40.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><path d=\"M510.0 75.0 L610.0 75.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\"></path><rect x=\"610.0\" y=\"66.0\" width=\"40.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"140.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">R</text><text x=\"210.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">Z</text><text x=\"315.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a slow answer pushes everything after it</text><text x=\"20.0\" y=\"165.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pacing</text><rect x=\"120.0\" y=\"156.0\" width=\"40.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><path d=\"M160.0 165.0 L252.0 165.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M120.0 181.0 L120.0 189.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"260.0\" y=\"156.0\" width=\"110.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><path d=\"M370.0 165.0 L392.0 165.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M260.0 181.0 L260.0 189.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"400.0\" y=\"156.0\" width=\"40.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><path d=\"M440.0 165.0 L532.0 165.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M400.0 181.0 L400.0 189.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"540.0\" y=\"156.0\" width=\"40.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><path d=\"M580.0 165.0 L672.0 165.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M540.0 181.0 L540.0 189.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M680.0 181.0 L680.0 189.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M122.0 199.0 L258.0 199.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l03-timeline-nf-ah-paper-dim)\" marker-start=\"url(#l03-timeline-nf-ah-paper-dim)\"></path><text x=\"190.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">start to start, fixed</text><text x=\"370.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the sleep shrinks instead</text></svg>", "caption": "Think time is counted from the end of an answer; pacing from the start of an iteration. Only pacing keeps a user's rate when the server slows."}
```

## Ramp-up

The fourth argument spreads the users' start over a number of seconds. **A ramp-up exists so that
the test does not open with a spike nobody asked for**: two hundred users starting in the same
instant send two hundred requests in the same instant, and the first seconds of the result describe
that burst instead of the load being tested. A ramp also lets caches, connection pools and the
interpreter warm up, and it shows the point where response times start to climb as users are added.

The measurement starts when the ramp ends. `users.py` counts only the requests that finished
afterwards, and every tool in this course has a way to separate the ramp from the steady part,
because averaging the two produces a number that described neither.

How long a ramp? Long enough that the users arrive at a rate the system meets in real life. For a
system that sees its traffic grow over a morning, a ramp of several minutes is cautious and honest.
For the 10:00 sale the arrival is the point, and that test is a spike from lesson 2 rather than a
load test with a short ramp.
