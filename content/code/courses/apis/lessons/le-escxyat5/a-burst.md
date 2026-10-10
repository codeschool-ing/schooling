---
title: x
version: 1
---

```python
# shelf/burst.py
"""Send N requests to limits.py, GAP seconds apart, and print what each one got.

    python3 burst.py KEY PATH N [GAP]
    python3 burst.py --edge KEY PATH N [GAP]    start 1 s before a 10 s window ends
"""
import re
import sys
import time
import urllib.error
import urllib.request

args = sys.argv[1:]
edge = args[0] == "--edge"
if edge:
    args = args[1:]
key, path, n = args[0], args[1], int(args[2])
gap = float(args[3]) if len(args) > 3 else 0

if edge:
    time.sleep((9 - time.time() % 10) % 10)

start = time.time()
for _ in range(n):
    sent = time.time()
    request = urllib.request.Request("http://127.0.0.1:8000" + path, headers={"X-API-Key": key})
    try:
        with urllib.request.urlopen(request) as answer:
            status, headers = answer.status, answer.headers
    except urllib.error.HTTPError as refused:
        status, headers = refused.code, refused.headers
    left = re.findall(r'"(\w+)";r=(\d+)', headers.get("RateLimit", ""))
    line = f"{sent - start:6.2f}s  {status}  " + "  ".join(f"{p} r={r}" for p, r in left)
    if headers.get("Retry-After"):
        line += f"  Retry-After: {headers['Retry-After']}"
    print(line, flush=True)
    time.sleep(max(0, sent + gap - time.time()))
```
