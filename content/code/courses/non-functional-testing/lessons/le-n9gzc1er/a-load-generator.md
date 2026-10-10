---
title: A load generator you can read
version: 1
---

Every load testing tool in this course does the same three things underneath its own vocabulary:
it sends requests on a schedule, it times each one, and it summarises what came back. **Before
any of them, you write one small enough to read in a minute**, so that when JMeter in lesson 4 or
k6 in lesson 5 reports a number, you already know what kind of machinery produced it.

It is 47 lines of Python, standard library only, and it takes the load shape as its arguments: a
list of stages, each a rate and a duration. Make a directory for it beside the box office:

```sh
mkdir -p ~/loadtest && cd ~/loadtest
```

Then `nano hammer.py`, and paste the file below with the copy button, which takes the program
without the notes:

```schooling-example
{"language": "python", "file": "loadtest/hammer.py", "parts": [{"code": "# loadtest/hammer.py\n# A tiny load generator. Each stage sends RATE requests a second for SECONDS\n# seconds, every request in a thread of its own, whether or not the earlier\n# ones have come back. Usage: python3 hammer.py URL RATE:SECONDS ...\nimport sys, threading, time, urllib.request\nfrom statistics import median\n\nurl = sys.argv[1]\nstages = [tuple(int(n) for n in s.split(\":\")) for s in sys.argv[2:]]\nresults = []                     # one (second sent, second done, ms, ok) per request\nlock = threading.Lock()\nt0 = time.perf_counter()\n", "note": "Standard library only, like the box office. The stages arrive as `RATE:SECONDS` pairs, so `10:3 200:2` means ten requests a second for three seconds, then two hundred a second for two. `t0` is the moment the run starts, and every time below is measured from it."}, {"code": "def one(second):\n    start = time.perf_counter()\n    try:\n        with urllib.request.urlopen(url, timeout=10) as answer:\n            answer.read()\n        ok = True\n    except Exception:            # an error status, a refused connection, a timeout\n        ok = False\n    end = time.perf_counter()\n    with lock:\n        results.append((second, int(end - t0), (end - start) * 1000, ok))\n", "note": "One request, timed from the moment it is sent to the moment the whole body has arrived. Anything that goes wrong counts as an error: a 4xx or 5xx status (which `urlopen` raises), a connection the server refused, or ten seconds with no answer. The lock stops two threads appending to the list at the same instant."}, {"code": "threads, second = [], 0\nfor rate, seconds in stages:\n    for _ in range(seconds):\n        for i in range(rate):\n            time.sleep(max(0, t0 + second + i / rate - time.perf_counter()))\n            thread = threading.Thread(target=one, args=(second,))\n            thread.start()\n            threads.append(thread)\n        second += 1\nfor thread in threads:\n    thread.join()\n", "note": "The schedule. Request `i` of a second is due at `i / rate` into it, and the loop sleeps until then and starts a thread for it. **It does not wait for the answer**, so a slow server does not slow the arrivals down: the next request goes out on time whatever happened to the last one. That is how people arrive at a box office, and lesson 3 gives it a name."}, {"code": "print(\"second  sent  done  errors  median ms  max ms\")\nfor s in range(second):\n    sent = [r for r in results if r[0] == s]\n    done = sum(1 for r in results if r[1] == s)\n    errors = sum(1 for r in sent if not r[3])\n    times = [r[2] for r in sent]\n    print(f\"{s:6}  {len(sent):4}  {done:4}  {errors:6}  {median(times):9.0f}  {max(times):6.0f}\")\nlate = sum(1 for r in results if r[1] >= second)\nprint(f\"{late} answers came back after second {second - 1};\"\n      f\" the last at {time.perf_counter() - t0:.1f} s\")", "note": "One line for every second of the schedule. `sent` and the two timings describe the requests sent in that second; `done` counts the answers that arrived in it, which is the throughput the server managed. The last line says how many answers were still arriving after the schedule had finished."}]}
```

Two things about it matter more than its size.

**It sends on a schedule and never waits for an answer.** Ten requests a second means one every
tenth of a second, each in a thread of its own, whether or not the previous one has come back. A
generator that sent the next request only after the last answer would slow down exactly when the
server did, and would report a pleasant number about a system that was drowning. Lesson 3 is
about that choice and its consequences.

**It runs on the same machine as the application it measures.** Every thread it starts costs
processor time the server could have used. At the rates in this lesson that cost is small, and "Adding processors"
at the end of this lesson pins the two to different processors to keep them apart. On a real test the
generator runs on a machine of its own, and lesson 4 shows how a tool spreads it over several.
