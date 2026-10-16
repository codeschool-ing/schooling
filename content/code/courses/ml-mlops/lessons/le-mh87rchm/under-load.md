---
title: A busy afternoon, on purpose
version: 1
---

One request at a time says how fast the service is when nobody else is using it. **What members
feel is how fast it is when everybody is**, and the only way to know that before they do is to make
the traffic yourself. This program sends a number of requests with several in flight at once, for
member ids drawn at random, the way pages opening across the shop would. Save it as `load.py`:

```python
"""load.py: send the service many requests at once, as a busy afternoon would.

    python load.py 2000 8      # 2,000 requests, 8 at a time
"""
import random
import sys
import time
import urllib.error
import urllib.request
from collections import Counter
from concurrent.futures import ThreadPoolExecutor

total, at_once = int(sys.argv[1]), int(sys.argv[2])
members = random.Random(9).choices(range(1, 4601), k=total)


def ask(member_id):
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:8000/lapse/{member_id}") as answer:
            return answer.status
    except urllib.error.HTTPError as refused:
        return refused.code


started = time.perf_counter()
with ThreadPoolExecutor(at_once) as pool:
    statuses = Counter(pool.map(ask, members))
seconds = time.perf_counter() - started
print(f"{total} requests in {seconds:.1f} s, {total / seconds:.0f} a second; "
      f"status {dict(sorted(statuses.items()))}")
```

`ThreadPoolExecutor(at_once)` keeps that many requests waiting on the service at any moment, and
`urllib` is Python's own HTTP client, so the program needs nothing installed. A 404 arrives as an
exception in `urllib`, and the program counts it as the answer it is.

Then a program to read the log the service wrote. Save it as `latency.py`:

```python
"""latency.py: what requests.log says about speed and errors.

    python latency.py          # every request logged
    python latency.py 600      # only the last 600
"""
import sys

import pandas as pd

from project import ROOT

log = pd.read_json(ROOT / "requests.log", lines=True)
if len(sys.argv) > 1:
    log = log.tail(int(sys.argv[1]))
errors = (log["status"] >= 500).sum()
print(f"{len(log)} requests, {errors} errors; status {log['status'].value_counts().sort_index().to_dict()}")
ms = log["ms"]
print(f"mean {ms.mean():6.1f} ms")
for q in (50, 95, 99):
    print(f"p{q}  {ms.quantile(q / 100):6.1f} ms")
print(f"max  {ms.max():6.1f} ms")
```

**An error is a status of 500 or above, and a 404 is not one.** A 404 here is the service correctly
refusing a member it has nothing fresh for; counting refusals as errors would make the error rate
rise every time the online store left more people out, and would teach whoever reads it to ignore
the number. With the service still running, 2,000 requests, eight at a time:

```
ana@dev:~/ml$ python load.py 2000 8
2000 requests in 20.5 s, 98 a second; status {200: 1354, 404: 646}
ana@dev:~/ml$ python latency.py 2000
2000 requests, 0 errors; status {200: 1354, 404: 646}
mean   68.7 ms
p50    81.3 ms
p95   120.3 ms
p99   140.6 ms
max   283.4 ms
```

About a hundred requests a second, no errors, and a third of the answers were refusals: the ids
run to 4,600, and the online store holds 3,372 members fresh enough to serve. **Then the four lines
that matter, and they disagree with each other.** The mean says 68.7 milliseconds. Half the requests
took more than 81.3 (the median, `p50`), one in twenty more than 120.3 (`p95`), one in a hundred
more than 140.6 (`p99`), and the slowest 283.4.

**The mean sits below the median, which a single kind of request would not do.** The log holds two:
refusals, which read one row and stop, and answers, which also run the model. The mean of two
populations describes neither of them, and the next section looks at what does.
