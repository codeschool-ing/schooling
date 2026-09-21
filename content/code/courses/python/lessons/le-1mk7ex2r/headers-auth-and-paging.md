---
title: A token, a rate limit, and the loop that follows `next`
version: 1
---

```python
import os, requests

s = requests.Session()
s.headers.update({
    "Authorization": f"Bearer {os.environ['API_TOKEN']}",
    "User-Agent": "rates/0.1 (ops@example.tld)",
})
r = s.get(url, timeout=10)
```

**A `Session` sends those headers on every request through it**, so the token is written once.
It also reuses the TCP connection, which is worth having over a few hundred calls.

## The token goes in a header

Not in the query string. A URL is logged by every proxy, every server and your own terminal
history, and a token in one is a token in all of them.

```python
os.environ["API_TOKEN"]       # from the environment
```

Not in the file either. That is lesson 18's `.env` and lesson 17's `.gitignore`, and the failure
mode is a repository somebody makes public two years later.

## The rate limit is a header

```sh
>>> {k: v for k, v in r.headers.items() if k.lower().startswith("x-rate")}
{'X-RateLimit-Limit': '60', 'X-RateLimit-Remaining': '59'}
```

Most APIs tell you where you stand on every response — usually `X-RateLimit-Remaining` and a
`X-RateLimit-Reset` timestamp. **Reading it is how you find out before you are cut off.**

```python
if int(r.headers.get("X-RateLimit-Remaining", 1)) < 5:
    time.sleep(...)
```

When you do get cut off it is a **429**, often with a `Retry-After` header saying how long. That
header is an instruction, and ignoring it is how a temporary block becomes a permanent one.

## Paging

```json
{"results": [ … ten rows … ], "next": "https://api.example.tld/orders?page=2"}
```

```python
url, rows = "https://api.example.tld/orders", []
while url:
    r = s.get(url, timeout=10)
    r.raise_for_status()
    page = r.json()
    rows += page["results"]
    url = page["next"]
```

```sh
followed next: 3 pages, 25 rows
```

**Six lines, and the same six lines every time.** The loop does not need to know how many pages
there are; it stops when `next` is null.

The other convention is a page number you increment until you get an empty list, and the third is
a `Link` header with `rel="next"` in it — `r.links.get("next", {}).get("url")` reads that one.

## Retrying

```python
from requests.adapters import HTTPAdapter
from urllib3.util import Retry

s.mount("https://", HTTPAdapter(max_retries=Retry(
    total=3, backoff_factor=1,
    status_forcelist=[429, 500, 502, 503, 504],
)))
```

Retry the statuses that are worth retrying, with a gap that grows. Do **not** retry a 400 or a
404 — those will say the same thing next time — and do not retry a POST that is not idempotent,
or you will create two of something.

## And be a good guest

A `User-Agent` naming your program and a way to contact you. When your script starts doing
something unhelpful, that line is the difference between somebody emailing you and somebody
blocking your address range.
