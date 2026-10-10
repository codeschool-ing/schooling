---
title: x
version: 1
---

```python
# shelf/polite.py
"""Ask limits.py for the list of books N times, waiting instead of failing when told to.

    python3 polite.py KEY N
"""
import random
import sys
import time
import urllib.error
import urllib.request

BASE, CAP, TRIES = 0.5, 8, 5


def get(url, key):
    """The status and Retry-After of one GET; the status is None when nothing answered."""
    request = urllib.request.Request(url, headers={"X-API-Key": key})
    try:
        with urllib.request.urlopen(request) as answer:
            return answer.status, None
    except urllib.error.HTTPError as refused:
        return refused.code, refused.headers.get("Retry-After")
    except OSError:
        return None, None


def fetch(url, key):
    """GET url, retrying a 429, a 5xx or silence up to TRIES times; the last status."""
    for attempt in range(TRIES):
        status, after = get(url, key)
        if status is not None and status != 429 and status < 500:
            return status
        if attempt == TRIES - 1:
            break
        if after is not None:
            pause = int(after) + random.uniform(0, 0.5)
            why = f"Retry-After: {after}"
        else:
            ceiling = min(CAP, BASE * 2 ** attempt)
            pause = random.uniform(0, ceiling)
            why = f"backing off, up to {ceiling}s"
        print(f"         {status or 'no answer'}, {why}, waiting {pause:.2f}s", flush=True)
        time.sleep(pause)
    return status


start = time.time()
key, n = sys.argv[1], int(sys.argv[2])
for i in range(1, n + 1):
    status = fetch("http://127.0.0.1:8000/books", key)
    print(f"{time.time() - start:6.2f}s  request {i}: {status or 'no answer'}", flush=True)
    if status is None or status == 429 or status >= 500:
        print(f"giving up after {TRIES} tries", flush=True)
        break
```
