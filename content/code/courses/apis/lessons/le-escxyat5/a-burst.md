---
title: A burst against it
version: 1
---

**A limiter is only believed once it has refused something, so this section sends more than the
limit and reads every answer.** A shell loop of curl would do, but its timing is whatever the shell
manages, and here the timing is what is being measured. This small client sends a number of requests a fixed
gap apart and prints, for each, when it was sent, the status, what the `RateLimit` header said was
left, and `Retry-After` when there was one. Save it as `~/shelf/burst.py`:

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

`--edge` is for the fixed window. It waits until one second before the next multiple of ten
seconds on the clock, which is where `limits.py window` starts a new window.

## Fifteen at once

`limits.py` running in the second terminal, the free key, fifteen requests with no gap:

```
ana@api:~/shelf$ python3 burst.py demo-bia /books 15
  0.00s  200  burst r=9  daily r=4999
  0.05s  200  burst r=8  daily r=4998
  0.05s  200  burst r=7  daily r=4997
  0.06s  200  burst r=6  daily r=4996
  0.06s  200  burst r=5  daily r=4995
  0.06s  200  burst r=4  daily r=4994
  0.06s  200  burst r=3  daily r=4993
  0.07s  200  burst r=2  daily r=4992
  0.07s  200  burst r=1  daily r=4991
  0.07s  200  burst r=0  daily r=4990
  0.07s  429  burst r=0  daily r=4990  Retry-After: 1
  0.08s  429  burst r=0  daily r=4990  Retry-After: 1
  0.08s  429  burst r=0  daily r=4990  Retry-After: 1
  0.08s  429  burst r=0  daily r=4990  Retry-After: 1
  0.08s  429  burst r=0  daily r=4990  Retry-After: 1
```

Ten accepted, the bucket's capacity, and the rest refused, each with `Retry-After: 1`. The
`daily` count went down only for the requests that were served: a refusal costs the client
nothing from its quota. The refusal in full:

```
ana@api:~/shelf$ curl -si -H 'X-API-Key: demo-bia' localhost:8000/books/1
HTTP/1.1 429 Too Many Requests
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:48:44 GMT
Content-Type: application/json
Content-Length: 45
RateLimit-Policy: "burst";q=10;w=10, "daily";q=5000;w=86400
RateLimit: "burst";r=0;t=1, "daily";r=4990;t=69076
Retry-After: 1

{"error": "too many requests: retry in 1 s"}
```

`r=0` and `t=1` in `RateLimit` agree with `Retry-After: 1`: nothing left now, and a token back
within a second. The body says the same thing in words for a person reading a log. **Every
refusal says when to come back**, which is what separates a limit from an outage.

The limit is per key. The pro key, asked in the same second, is not touched by anything the free
key did:

```
ana@api:~/shelf$ curl -s -o /dev/null -w '%{http_code}\n' -H 'X-API-Key: demo-caio' localhost:8000/books
200
```

And after three seconds of quiet, the free key has three tokens again, and the fourth request
of the next burst is refused:

```
ana@api:~/shelf$ sleep 3; python3 burst.py demo-bia /books 5
  0.00s  200  burst r=2  daily r=4989
  0.03s  200  burst r=1  daily r=4988
  0.03s  200  burst r=0  daily r=4987
  0.04s  429  burst r=0  daily r=4987  Retry-After: 1
  0.04s  429  burst r=0  daily r=4987  Retry-After: 1
```

The second terminal printed one line per request, and the refusals are in it as `429`s:

```
127.0.0.1 - - [10/Oct/2026 01:48:44] "GET /books HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:48:44] "GET /books HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:48:44] "GET /books HTTP/1.1" 429 -
127.0.0.1 - - [10/Oct/2026 01:48:44] "GET /books HTTP/1.1" 429 -
127.0.0.1 - - [10/Oct/2026 01:48:44] "GET /books HTTP/1.1" 429 -
```

**The `429`s in that log are data.** A key refused all day long needs a conversation or a bigger
tier, and a sudden rise in refusals across every key is often the first sign of a client release
with a retry bug in it.

## A steady pace

Four requests a second, against a bucket that refills one a second. These are the numbers drawn
in the section on the token bucket:

```
ana@api:~/shelf$ python3 burst.py demo-bia /books 24 0.25
  0.00s  200  burst r=9  daily r=4999
  0.25s  200  burst r=8  daily r=4998
  0.50s  200  burst r=7  daily r=4997
  0.75s  200  burst r=6  daily r=4996
  1.00s  200  burst r=5  daily r=4995
  1.25s  200  burst r=5  daily r=4994
  1.50s  200  burst r=4  daily r=4993
  1.75s  200  burst r=3  daily r=4992
  2.00s  200  burst r=2  daily r=4991
  2.25s  200  burst r=2  daily r=4990
  2.50s  200  burst r=1  daily r=4989
  2.75s  200  burst r=0  daily r=4988
  3.00s  429  burst r=0  daily r=4988  Retry-After: 1
  3.25s  200  burst r=0  daily r=4987
  3.50s  429  burst r=0  daily r=4987  Retry-After: 1
  3.75s  429  burst r=0  daily r=4987  Retry-After: 1
  4.00s  429  burst r=0  daily r=4987  Retry-After: 1
  4.25s  200  burst r=0  daily r=4986
  4.50s  429  burst r=0  daily r=4986  Retry-After: 1
  4.75s  429  burst r=0  daily r=4986  Retry-After: 1
  5.00s  429  burst r=0  daily r=4986  Retry-After: 1
  5.26s  200  burst r=0  daily r=4985
  5.51s  429  burst r=0  daily r=4985  Retry-After: 1
  5.76s  429  burst r=0  daily r=4985  Retry-After: 1
```

## The edge, measured

The run behind the figure in the section on the fixed window. First with `limits.py window`
running, then, after `Ctrl+C`, with plain `limits.py`. Thirty requests a tenth of a second apart,
starting one second before a window ends:

```
ana@api:~/shelf$ python3 burst.py --edge demo-bia /books 30 0.1
  0.00s  200  burst r=9  daily r=4999
  0.10s  200  burst r=8  daily r=4998
  0.20s  200  burst r=7  daily r=4997
  0.30s  200  burst r=6  daily r=4996
  0.40s  200  burst r=5  daily r=4995
  0.50s  200  burst r=4  daily r=4994
  0.60s  200  burst r=3  daily r=4993
  0.70s  200  burst r=2  daily r=4992
  0.80s  200  burst r=1  daily r=4991
  0.90s  200  burst r=0  daily r=4990
  1.00s  200  burst r=9  daily r=4989
  1.10s  200  burst r=8  daily r=4988
  1.20s  200  burst r=7  daily r=4987
  1.30s  200  burst r=6  daily r=4986
  1.40s  200  burst r=5  daily r=4985
  1.50s  200  burst r=4  daily r=4984
  1.61s  200  burst r=3  daily r=4983
  1.71s  200  burst r=2  daily r=4982
  1.81s  200  burst r=1  daily r=4981
  1.91s  200  burst r=0  daily r=4980
  2.01s  429  burst r=0  daily r=4980  Retry-After: 9
  2.11s  429  burst r=0  daily r=4980  Retry-After: 9
  2.21s  429  burst r=0  daily r=4980  Retry-After: 9
  2.31s  429  burst r=0  daily r=4980  Retry-After: 9
  2.41s  429  burst r=0  daily r=4980  Retry-After: 9
  2.51s  429  burst r=0  daily r=4980  Retry-After: 9
  2.61s  429  burst r=0  daily r=4980  Retry-After: 9
  2.71s  429  burst r=0  daily r=4980  Retry-After: 9
  2.81s  429  burst r=0  daily r=4980  Retry-After: 9
  2.91s  429  burst r=0  daily r=4980  Retry-After: 9
```

Twenty accepted inside two seconds, with a limit of ten per ten seconds: the first ten in the last
second of one window, the next ten in the first second of the next. Then the counter is full, and
`Retry-After: 9` sends the client to the start of the following window. The same thirty against
the bucket:

```
ana@api:~/shelf$ python3 burst.py --edge demo-bia /books 30 0.1
  0.00s  200  burst r=9  daily r=4999
  0.10s  200  burst r=8  daily r=4998
  0.20s  200  burst r=7  daily r=4997
  0.30s  200  burst r=6  daily r=4996
  0.40s  200  burst r=5  daily r=4995
  0.50s  200  burst r=4  daily r=4994
  0.60s  200  burst r=3  daily r=4993
  0.70s  200  burst r=2  daily r=4992
  0.80s  200  burst r=1  daily r=4991
  0.90s  200  burst r=0  daily r=4990
  1.00s  429  burst r=0  daily r=4990  Retry-After: 1
  1.11s  200  burst r=0  daily r=4989
  1.21s  429  burst r=0  daily r=4989  Retry-After: 1
  1.31s  429  burst r=0  daily r=4989  Retry-After: 1
  1.41s  429  burst r=0  daily r=4989  Retry-After: 1
  1.51s  429  burst r=0  daily r=4989  Retry-After: 1
  1.61s  429  burst r=0  daily r=4989  Retry-After: 1
  1.71s  429  burst r=0  daily r=4989  Retry-After: 1
  1.81s  429  burst r=0  daily r=4989  Retry-After: 1
  1.91s  429  burst r=0  daily r=4989  Retry-After: 1
  2.01s  429  burst r=0  daily r=4989  Retry-After: 1
  2.11s  200  burst r=0  daily r=4988
  2.21s  429  burst r=0  daily r=4988  Retry-After: 1
  2.31s  429  burst r=0  daily r=4988  Retry-After: 1
  2.41s  429  burst r=0  daily r=4988  Retry-After: 1
  2.51s  429  burst r=0  daily r=4988  Retry-After: 1
  2.61s  429  burst r=0  daily r=4988  Retry-After: 1
  2.71s  429  burst r=0  daily r=4988  Retry-After: 1
  2.81s  429  burst r=0  daily r=4988  Retry-After: 1
  2.91s  429  burst r=0  daily r=4988  Retry-After: 1
```

Twelve accepted: the ten saved up, then one per second. The bucket has no edge because it has no
windows; a token that has been spent is gone until the refill brings it back, whatever the clock
says.
