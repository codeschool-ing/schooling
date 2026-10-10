---
title: Testing the matrix
version: 1
---

**Authorisation is a table, every caller against every operation, and in each cell the answer that
should come back.** So its test is a table too: send every request as every caller, compare each
status with the one expected, and fail on any difference, in either direction.

The other direction is the reason to write it. A test of the feature checks that Ana can read her
order. A test of the authorisation also checks that Ana cannot read Bruno's. Nobody writes that check by
hand, because nothing looks broken when it fails: the order appears, the page is fine, and only
Bruno would mind.

`matrix.py` is that test for `orders.py`. It makes its requests with `urllib`, from Python's standard
library. Save it in `~/shelf`:

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
    print(f"{token or '(no token)':14}{cells}".rstrip())
print()
for line in wrong:
    print(line)
checks = len(EXPECTED) * len(ENDPOINTS)
print(f"{checks} checks, {len(wrong)} wrong")
sys.exit(1 if wrong else 0)
```

`EXPECTED` is the specification, written by a person, one row per token. **It is the part to read
in a review**: somebody who knows what the shop intends can check each cell without reading a line
of `orders.py`. With `orders.py` running in the second terminal:

```
ana@api:~/shelf$ python3 matrix.py; echo "exit $?"
1  GET /orders
2  GET /orders/1
3  GET /orders/3
4  GET /orders/99
5  POST /orders
6  GET /admin/people

token              1     2     3     4     5     6
(no token)      401   401   401   401   401   401
demo-ana        200   200   404   404   201   403
demo-ana-app    200   200   404   404   403   403
demo-bruno      200   404   200   404   201   403
demo-carla      200   200   200   404   403   403
demo-dora       200   200   200   404   403   200
demo-eva        403   403   403   403   403   403

42 checks, 0 wrong
exit 0
```

Forty-two checks, none wrong, and an exit status of 0, so a script or a CI job can run it and stop
on a failure. Each run places two more orders, Ana's and Bruno's, which changes no cell.

## Breaking it on purpose

A test you have only ever seen pass has not shown you it can fail. Make a copy of `orders.py`
without the two lines of the ownership check, and look at what went:

```
ana@api:~/shelf$ sed '/!= me and/,+1d' orders.py > broken.py
ana@api:~/shelf$ diff orders.py broken.py
80,81d79
<     if order["customer"] != me and "orders:read_all" not in perms:
<         return None
```

Stop `orders.py` in the second terminal and start the copy there with `python3 broken.py`. Then run
the matrix again:

```
ana@api:~/shelf$ python3 matrix.py; echo "exit $?"
1  GET /orders
2  GET /orders/1
3  GET /orders/3
4  GET /orders/99
5  POST /orders
6  GET /admin/people

token              1     2     3     4     5     6
(no token)      401   401   401   401   401   401
demo-ana        200   200   200!  404   201   403
demo-ana-app    200   200   200!  404   403   403
demo-bruno      200   200!  200   404   201   403
demo-carla      200   200   200   404   403   403
demo-dora       200   200   200   404   403   200
demo-eva        403   403   403   403   403   403

demo-ana: GET /orders/3 answered 200, expected 404
demo-ana-app: GET /orders/3 answered 200, expected 404
demo-bruno: GET /orders/1 answered 200, expected 404
42 checks, 3 wrong
exit 1
```

Three cells changed, each marked with `!`, and the lines under the table say who saw what they
should not have: Ana and her app read Bruno's order 3, and Bruno read Ana's order 1. The exit status
is 1. **Every one of those requests answered 200 with a well-formed order**, which is why no test of
the feature would have noticed.

Stop `broken.py` and start `orders.py` again before you go on; `broken.py` can be deleted.
