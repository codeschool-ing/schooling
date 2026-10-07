---
title: Two productions and a switch
version: 1
---

**Blue-green** keeps two complete copies of production. One, call it blue, serves every customer.
The new release is deployed to the other, green, while nobody is using it, and checked there.
Then the router in front of both is told to send traffic to green instead. The old copy stays
running, untouched, and that is the point of the strategy.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two drawings of the router on port 8300 in front of blue, running 1.5.0, and green, running 1.6.0. On the left, blue-green after the switch: green receives 100 percent of the traffic and blue none, though it keeps running. On the right, a canary at 10 percent: blue receives 90 percent and green 10.\"><text x=\"175\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">blue-green, after the switch</text><rect x=\"105\" y=\"36\" width=\"140\" height=\"40\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"175.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">router :8300</text><path d=\"M175 76 L90 160\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\" fill=\"none\"></path><text x=\"98.5\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">0%</text><rect x=\"20\" y=\"160\" width=\"140\" height=\"58\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">blue</text><text x=\"90.0\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">1.5.0</text><path d=\"M175 76 L260 160\" stroke=\"var(--amber)\" stroke-width=\"8.0\" fill=\"none\"></path><text x=\"251.5\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">100%</text><rect x=\"190\" y=\"160\" width=\"140\" height=\"58\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"260.0\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">green</text><text x=\"260.0\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">1.6.0</text><text x=\"545\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">canary, at 10%</text><rect x=\"475\" y=\"36\" width=\"140\" height=\"40\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"545.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">router :8300</text><path d=\"M545 76 L460 160\" stroke=\"var(--phosphor)\" stroke-width=\"7.3\" fill=\"none\"></path><text x=\"468.5\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">90%</text><rect x=\"390\" y=\"160\" width=\"140\" height=\"58\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"460.0\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">blue</text><text x=\"460.0\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">1.5.0</text><path d=\"M545 76 L630 160\" stroke=\"var(--amber)\" stroke-width=\"1.7\" fill=\"none\"></path><text x=\"621.5\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">10%</text><rect x=\"560\" y=\"160\" width=\"140\" height=\"58\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">green</text><text x=\"630.0\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">1.6.0</text><path d=\"M360 30 L360 230\" stroke=\"var(--wire)\" stroke-width=\"1\"></path></svg>", "caption": "The same two sides behind the same router. Blue-green moves everybody at once; a canary moves a share and watches it."}
```

The lab's version is `ops/router.py`, listening on port 8300 in front of two environments,
`production-blue` on 8301 and `production-green` on 8302. It reads its weights from a file on every
request, so moving traffic needs no restart.

```python
def choose(request_id, weights):
    bucket = int(hashlib.sha256(request_id.encode()).hexdigest(), 16) % 100
    edge = 0
    for name, weight in weights.items():
        edge += weight
        if bucket < edge:
            return name
    raise LookupError(f"weights add up to {edge}, not 100")
```

Each request goes to a side by a hash of its `X-Request-Id`, so the same id always lands on the same
side. Blue runs 1.5.0 and has every customer:

```
ana@laptop:~/shipquote$ ls dist/*.tar.gz
dist/shipquote-1.5.0.tar.gz
dist/shipquote-1.6.0.tar.gz
dist/shipquote-1.6.1.tar.gz
ana@laptop:~/shipquote$ git log --oneline v1.5.0..v1.6.1
20bd4df Give Alagoas its delivery days, and put the estimate behind a flag
f2e1ad1 Say how many days delivery takes; route and load for releases
```

```
ana@laptop:~/shipquote$ cat ~/envs/production-blue/config.env ~/envs/production-green/config.env
SHIPQUOTE_PORT=8301
SHIPQUOTE_FLAGS=/home/ana/envs/flags.json
SHIPQUOTE_PORT=8302
SHIPQUOTE_FLAGS=/home/ana/envs/flags.json
```

## The switch

Ana deploys 1.6.0 to green. Customers still meet blue, because the weights have not moved:

```
ana@laptop:~/shipquote$ cat ~/envs/routes.json
{"backends": {"blue": "http://127.0.0.1:8301", "green": "http://127.0.0.1:8302"}, "weights": {"blue": 100, "green": 0}}
ana@laptop:~/shipquote$ curl -s http://127.0.0.1:8300/version; echo
{"version": "1.5.0", "env": "production-blue", "carrier": "table"}
ana@laptop:~/shipquote$ ops/deploy.sh production-green dist/shipquote-1.6.0.tar.gz
smoke: http://127.0.0.1:8302 is up and running 1.6.0
ana@laptop:~/shipquote$ curl -s http://127.0.0.1:8300/version; echo
{"version": "1.5.0", "env": "production-blue", "carrier": "table"}
ana@laptop:~/shipquote$ python3 ops/load.py http://127.0.0.1:8300 2000 & sleep 1; sed -i 's/"blue": 100, "green": 0/"blue": 0, "green": 100/' ~/envs/routes.json; wait
backend    requests errors    rate
blue            449      0    0.0%
green          1551     77    5.0%
ana@laptop:~/shipquote$ curl -s http://127.0.0.1:8300/version; echo
{"version": "1.6.0", "env": "production-green", "carrier": "table"}
```

The smoke test passed on green before a single customer reached it. Then `ops/load.py` started
sending the shop's usual mix of orders, and one second in, a `sed` changed the weights to send
everything to green. Not one request went unanswered during the switch: 449 were served by blue
before it, 1551 by green after it.

But **77 of green's answers were errors**, one in twenty. That is the order in the mix that
goes to CEP 57020-050, in Alagoas. The smoke test only asked whether 1.6.0 was running, and it was.
Every customer had been moved to a release that could not answer one of the shop's destinations.
