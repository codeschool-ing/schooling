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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Each response carries its rows and the address of the next page. The loop follows that address until a response comes back with none, and it never has to know how many pages there were.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"20\" y=\"24\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">while url:</text> <rect x=\"20\" y=\"36\" width=\"180\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"110\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/orders</text> <path d=\"M206 55 L244 55\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"250\" y=\"36\" width=\"150\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"325\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10 rows</text> <rect x=\"420\" y=\"36\" width=\"160\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"500\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">?page=2</text> <path d=\"M500 78 L500 84 L110 84 L110 90\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"20\" y=\"88\" width=\"180\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"110\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">?page=2</text> <path d=\"M206 107 L244 107\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"250\" y=\"88\" width=\"150\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"325\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10 rows</text> <rect x=\"420\" y=\"88\" width=\"160\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"500\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">?page=3</text> <path d=\"M500 130 L500 136 L110 136 L110 142\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"20\" y=\"140\" width=\"180\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"110\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">?page=3</text> <path d=\"M206 159 L244 159\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"250\" y=\"140\" width=\"150\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"325\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5 rows</text> <rect x=\"420\" y=\"140\" width=\"160\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"500\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">null</text> <text x=\"500\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">no next, so the loop ends</text> <text x=\"360\" y=\"208\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">3 pages, 25 rows</text> <text x=\"360\" y=\"230\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">A page number you increment until the list comes back empty is the other convention,</text> <text x=\"360\" y=\"247\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">and a Link header with rel=&quot;next&quot; is the third: r.links[&quot;next&quot;][&quot;url&quot;] reads that one.</text> </svg>", "caption": "Six lines, and the same six lines every time. The loop stops when the server says there is no next."}
```

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
