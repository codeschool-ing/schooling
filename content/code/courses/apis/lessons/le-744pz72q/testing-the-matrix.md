---
title: x
version: 1
---

```python
# shelf/matrix.py
"""Every token against every endpoint of orders.py, compared with what should happen.

Run it while orders.py is running: python3 matrix.py
"""
import json
import sys
import urllib.error
import urllib.request

ENDPOINTS = [
    ("GET", "/orders"),
    ("GET", "/orders/1"),
    ("GET", "/orders/3"),
    ("GET", "/orders/99"),
    ("POST", "/orders"),
    ("GET", "/admin/people"),
]

# One row per token, one status per endpoint, in the order above.
EXPECTED = {
    None: [401, 401, 401, 401, 401, 401],
    "demo-ana": [200, 200, 404, 404, 201, 403],
    "demo-ana-app": [200, 200, 404, 404, 403, 403],
    "demo-bruno": [200, 404, 200, 404, 201, 403],
    "demo-carla": [200, 200, 200, 404, 403, 403],
    "demo-dora": [200, 200, 200, 404, 403, 200],
    "demo-eva": [403, 403, 403, 403, 403, 403],
}


def status(method, path, token):
    req = urllib.request.Request("http://127.0.0.1:8000" + path, method=method)
    if token:
        req.add_header("Authorization", "Bearer " + token)
    if method == "POST":
        req.add_header("Content-Type", "application/json")
        req.data = json.dumps({"book_id": 1, "quantity": 1}).encode()
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status
    except urllib.error.HTTPError as e:
        return e.code


for n, (method, path) in enumerate(ENDPOINTS, 1):
    print(f"{n}  {method} {path}")
print()
print(f"{'token':14}" + "".join(f"{n:>6}" for n in range(1, len(ENDPOINTS) + 1)))
wrong = []
for token, expected in EXPECTED.items():
    cells = ""
    for (method, path), want in zip(ENDPOINTS, expected):
        got = status(method, path, token)
        cells += f"{got:>5}" + (" " if got == want else "!")
        if got != want:
            wrong.append(f"{token}: {method} {path} answered {got}, expected {want}")
    print(f"{token or '(no token)':14}{cells}")
print()
for line in wrong:
    print(line)
checks = len(EXPECTED) * len(ENDPOINTS)
print(f"{checks} checks, {len(wrong)} wrong")
sys.exit(1 if wrong else 0)
```
