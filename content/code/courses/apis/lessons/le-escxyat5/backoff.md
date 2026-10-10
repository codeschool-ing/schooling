---
title: A client that behaves
version: 1
---

**A limit only works if clients respond to it, and the response that works is to wait, longer each
time, by an amount that is partly random.** The server can refuse; it cannot make a client stop
asking. A client that answers a `429` by retrying at once gets another `429`, spends the server's
time on refusals, and if there are many such clients they keep each other refused.

Two rules, and each fixes a different failure:

- **Wait as long as the server said.** When the answer carries `Retry-After`, that is the number.
  Waiting less is guaranteed to be refused again; the server knows its own bucket.
- **When the server said nothing, back off exponentially, with jitter.** No answer at all, a
  connection refused, or a `503` with no `Retry-After`: wait up to half a second, then up to one,
  then up to two, doubling up to a ceiling, and pick the actual wait at random between zero and
  that limit. Give up after a few tries.

The doubling is so that a server that is down, or overloaded, gets asked less and less often
instead of at the same steady rate by every client that noticed. The randomness is for the
failure that doubling alone makes worse:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 290\" role=\"img\" aria-label=\"Five clients fail at the same moment and retry after up to 0.5, 1 and 2 seconds. Without jitter all five retry at 0.5, 1.5 and 3.5 seconds, five requests at each instant. With full jitter each wait is a random point below the ceiling, and the retries are spread across the four seconds.\"><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">without jitter</text><rect x=\"146\" y=\"35\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"208.5\" y=\"35\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"333.5\" y=\"35\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"583.5\" y=\"35\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"146\" y=\"50\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"208.5\" y=\"50\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"333.5\" y=\"50\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"583.5\" y=\"50\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"146\" y=\"65\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"208.5\" y=\"65\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"333.5\" y=\"65\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"583.5\" y=\"65\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"146\" y=\"80\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"208.5\" y=\"80\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"333.5\" y=\"80\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"583.5\" y=\"80\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"146\" y=\"95\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"208.5\" y=\"95\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"333.5\" y=\"95\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"583.5\" y=\"95\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">full jitter</text><rect x=\"146\" y=\"155\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"175.7\" y=\"155\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"257.8\" y=\"155\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"424.4\" y=\"155\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"146\" y=\"170\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"154.9\" y=\"170\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"156.3\" y=\"170\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"250.0\" y=\"170\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"146\" y=\"185\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"163.1\" y=\"185\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"264.4\" y=\"185\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"437.1\" y=\"185\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"146\" y=\"200\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"183.6\" y=\"200\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"253.4\" y=\"200\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"418.7\" y=\"200\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"146\" y=\"215\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"155.1\" y=\"215\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"210.1\" y=\"215\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"250.7\" y=\"215\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"212.5\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">5</text><text x=\"337.5\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">5</text><text x=\"587.5\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">5</text><line x1=\"140\" y1=\"245\" x2=\"650\" y2=\"245\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"150\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 s</text><text x=\"275\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1 s</text><text x=\"400\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2 s</text><text x=\"525\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3 s</text><text x=\"650\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4 s</text><rect x=\"150\" y=\"272\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"164\" y=\"277\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the failure</text><rect x=\"260\" y=\"272\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"274\" y=\"277\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a retry</text></svg>", "caption": "Doubling alone moves the spike; jitter spreads it."}
```

Without jitter, clients that failed together retry together, at 0.5 seconds, then 1.5, then 3.5,
and each retry is a spike as tall as the one that caused the failure. Picking each wait at random
between zero and the ceiling, the scheme usually called **full jitter**, spreads those spikes into
a trickle the server can serve.

## polite.py

It asks for `/books` a number of times, one after the other, and follows both rules. Save it as
`~/shelf/polite.py`:

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

`get` turns every outcome into a status and a `Retry-After`, with `None` for a server that did not
answer. `fetch` retries only what is worth retrying: a `429`, a `5xx` or silence. A `404` or a `401`
is returned at once, because sending the same wrong request again cannot make it right. And the
last line of the loop gives up on the whole run, not on one request, when one request has run out
of tries: a server that did not answer five times will not answer the next request either.

Fourteen requests, against a bucket of ten:

```
ana@api:~/shelf$ python3 polite.py demo-bia 14
  0.04s  request 1: 200
  0.04s  request 2: 200
  0.04s  request 3: 200
  0.04s  request 4: 200
  0.05s  request 5: 200
  0.05s  request 6: 200
  0.05s  request 7: 200
  0.05s  request 8: 200
  0.06s  request 9: 200
  0.06s  request 10: 200
         429, Retry-After: 1, waiting 1.07s
  1.13s  request 11: 200
         429, Retry-After: 1, waiting 1.20s
  2.33s  request 12: 200
         429, Retry-After: 1, waiting 1.42s
  3.76s  request 13: 200
         429, Retry-After: 1, waiting 1.31s
  5.07s  request 14: 200
```

Fourteen answers and fourteen `200`s. Ten went at once, out of the bucket; each of the other four
was refused once, waited the second the server asked for plus a fraction, and got through. **Not
one request failed**, and the server spent four refusals on this client where `burst.py`'s fifteen
at once earned five and fixed nothing.

Now with the server stopped, `Ctrl+C` in the second terminal, so nothing answers and nothing says
how long to wait:

```
ana@api:~/shelf$ python3 polite.py demo-bia 3
         no answer, backing off, up to 0.5s, waiting 0.08s
         no answer, backing off, up to 1.0s, waiting 0.75s
         no answer, backing off, up to 2.0s, waiting 1.40s
         no answer, backing off, up to 4.0s, waiting 0.19s
  2.46s  request 1: no answer
giving up after 5 tries
```

The ceiling doubled each time, `0.5s`, `1.0s`, `2.0s`, `4.0s`, while each actual wait was a random point below
it. After five tries it stopped. A client that retried forever, at a fixed rate, would be hitting
the server at full speed the moment it came back up, together with every other client doing the
same.

## Where a client can do better

`polite.py` waits until it is refused. The `RateLimit` header lets a client slow down before that:
with `r=1` left and `t=1` second, it can wait a second before the next request and never see a
`429` at all. That is a refinement a client may make; the draft itself says a client must not treat
`r` as a promise that the next requests will be served. **`Retry-After` and the `429` remain the
signals a client has to honour.**
