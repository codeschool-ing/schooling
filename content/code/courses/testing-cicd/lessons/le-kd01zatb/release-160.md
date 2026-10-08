---
title: Release 1.6.0, and the tools to ship it
version: 1
---

This lesson ships two releases of `shipquote`, and it needs three new tools to ship them with. This
section and the next build all of it, so that every strategy after them has the same releases to
work on. Nothing in them is a strategy yet; they are the material.

**Version 1.6.0 tells the customer how long delivery takes**, in business days, by the state the
CEP is in: the first two digits of a CEP say which. Copy it exactly as it is. A release strategy is
judged by what it does with a release that turns out to be wrong, and section 06 is where this one
is put to that test.

The table and the function that reads it go into the freight module. Save it as
`shipquote/quote.py`:

```python
"""What it costs to send a parcel, in cents."""

# The first digit of a CEP says which region of Brazil it is in.
ZONES = {"0": "SP", "1": "SP", "2": "SE", "3": "SE", "4": "NE",
         "5": "NE", "6": "N", "7": "CO", "8": "S", "9": "S"}
BASE = {"SP": 1290, "SE": 1590, "S": 1890, "CO": 2190, "NE": 2490, "N": 2990}
EXTRA_PER_500G = 450      # every 500 g started after the first
FREE_FROM = 19900         # an order of R$ 199,00 or more ships free

# Business days to deliver, by the first two digits of the CEP: the state.
DAYS = {**{p: 1 for p in range(1, 20)},      # São Paulo
        **{p: 2 for p in range(20, 40)},     # Rio, Espírito Santo, Minas
        **{p: 4 for p in range(40, 57)},     # Bahia to Pernambuco
        **{p: 5 for p in range(58, 66)},     # Paraíba to Maranhão
        **{p: 6 for p in range(66, 70)},     # the North
        **{p: 3 for p in range(70, 80)},     # the Centre-West
        **{p: 2 for p in range(80, 100)}}    # the South


def normalise_cep(cep: str) -> str:
    digits = cep.replace("-", "")
    if len(digits) != 8 or not digits.isdigit():
        raise ValueError(f"not a CEP: {cep!r}")
    return digits


def zone_of(cep: str) -> str:
    return ZONES[normalise_cep(cep)[0]]


def freight(cep: str, weight_g: int, subtotal_cents: int) -> int:
    if weight_g <= 0:
        raise ValueError(f"weight must be positive, got {weight_g}")
    zone = zone_of(cep)
    if subtotal_cents >= FREE_FROM:
        return 0
    extra = (weight_g - 1) // 500
    return BASE[zone] + extra * EXTRA_PER_500G


def delivery_days(cep: str) -> int:
    return DAYS[int(normalise_cep(cep)[:2])]
```

The quote's answer carries the new field, `days`, which is one line in `quote_body`. Save it as
`shipquote/app.py`:

```python
"""The HTTP face of shipquote: /health, /version and /quote."""
import json
import os
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

from . import carrier, money, quote
from .version import VERSION


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.started = time.monotonic()
        url = urlparse(self.path)
        if url.path == "/health":
            return self.reply(200, {"status": "ok"})
        if url.path == "/version":
            env = os.environ.get("SHIPQUOTE_ENV", "dev")
            source = os.environ.get("SHIPQUOTE_CARRIER_URL") or "table"
            return self.reply(200, {"version": VERSION, "env": env,
                                    "carrier": source})
        if url.path != "/quote":
            return self.reply(404, {"error": "not found"})
        args = parse_qs(url.query)
        try:
            cep = args["cep"][0]
            weight_g = int(args["weight"][0])
            subtotal = int(args.get("subtotal", ["0"])[0])
            cents = quote.freight(cep, weight_g, subtotal)
        except KeyError as e:
            return self.reply(400, {"error": f"missing {e.args[0]}"})
        except ValueError as e:
            return self.reply(400, {"error": str(e)})
        carrier_url = os.environ.get("SHIPQUOTE_CARRIER_URL")
        if carrier_url and cents:
            client = carrier.CarrierClient(
                carrier_url, os.environ.get("SHIPQUOTE_CARRIER_TOKEN", ""))
            cents = carrier.price(client, cep, weight_g, subtotal,
                                  log=lambda line: print(line, file=sys.stderr))
        try:
            body = self.quote_body(cep, cents)
        except Exception as e:  # noqa: BLE001 -- answered as a 500 and logged
            print(f"error: {type(e).__name__}: {e}", file=sys.stderr)
            return self.reply(500, {"error": "internal error"})
        self.reply(200, body)

    def quote_body(self, cep, cents):
        return {"cep": cep, "zone": quote.zone_of(cep),
                "cents": cents, "price": money.brl(cents),
                "days": quote.delivery_days(cep)}

    def reply(self, status, body):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, fmt, *args):
        ms = (time.monotonic() - getattr(self, "started", time.monotonic())) * 1000
        print(f"{self.command} {self.path} {args[1]} {ms:.1f}ms v={VERSION}",
              file=sys.stderr)


def main():
    port = int(os.environ.get("SHIPQUOTE_PORT", "8080"))
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print(f"shipquote {VERSION} listening on 127.0.0.1:{port}", file=sys.stderr)
    server.serve_forever()


if __name__ == "__main__":
    main()
```

The tests: four states with their days, and the field in the HTTP answer. Save them as
`tests/test_quote.py`:

```python
import pytest

from shipquote.quote import FREE_FROM, delivery_days, freight, zone_of


def test_a_cep_in_the_city_of_sao_paulo_is_zone_sp():
    assert zone_of("01310-100") == "SP"


@pytest.mark.parametrize("weight_g, cents", [
    (1, 1290),
    (500, 1290),
    (501, 1740),
    (1000, 1740),
    (1001, 2190),
])
def test_every_500_g_started_after_the_first_costs_extra(weight_g, cents):
    assert freight("01310-100", weight_g, 5000) == cents


@pytest.mark.parametrize("subtotal, cents", [
    (FREE_FROM - 1, 1290),
    (FREE_FROM, 0),
    (FREE_FROM + 1, 0),
])
def test_an_order_of_199_reais_or_more_ships_free(subtotal, cents):
    assert freight("01310-100", 300, subtotal) == cents


def test_a_weight_of_zero_is_refused():
    with pytest.raises(ValueError, match="weight must be positive"):
        freight("01310-100", 0, 5000)


def test_a_cep_with_a_letter_in_it_is_refused():
    with pytest.raises(ValueError, match="not a CEP"):
        zone_of("0131O-100")


@pytest.mark.parametrize("cep, days", [
    ("01310-100", 1),
    ("20040-002", 2),
    ("69005-010", 6),
    ("80010-000", 2),
])
def test_delivery_takes_the_days_of_the_state(cep, days):
    assert delivery_days(cep) == days
```

Save them as `tests/test_app.py`:

```python
import pytest

from tests.conftest import get

pytestmark = pytest.mark.functional


def test_health_answers_ok(base_url):
    assert get(base_url + "/health") == (200, {"status": "ok"})


def test_a_quote_comes_back_as_json_with_the_price_formatted(base_url):
    status, body = get(base_url + "/quote?cep=01310-100&weight=1200&subtotal=5000")
    assert status == 200
    assert body == {"cep": "01310-100", "zone": "SP",
                    "cents": 2190, "price": "R$ 21,90", "days": 1}


def test_a_bad_cep_is_a_400_that_says_why(base_url):
    status, body = get(base_url + "/quote?cep=abc&weight=1200")
    assert status == 400
    assert body == {"error": "not a CEP: 'abc'"}


def test_version_says_the_table_is_used_when_no_carrier_is_named(base_url):
    assert get(base_url + "/version")[1]["carrier"] == "table"
```

## The tools

**A router**, which stands in front of two copies of production and sends each request to one of
them by weights read from a file. Section 06 explains it; blue-green and canary both rest on it.
Save it as `ops/router.py`:

```python
"""A small HTTP router for blue-green and canary releases.

ROUTER_CONFIG names a JSON file with the backends and their share of traffic:
  {"backends": {"blue": "http://127.0.0.1:8301", "green": "http://127.0.0.1:8302"},
   "weights": {"blue": 100, "green": 0}}
The file is read on every request, so moving traffic needs no restart. A
request goes to the side its X-Request-Id hashes to, so the same id always
lands on the same side, and the answer says which side in X-Served-By.
"""
import hashlib
import json
import os
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

CONFIG = os.environ["ROUTER_CONFIG"]
PORT = int(os.environ.get("ROUTER_PORT", "8300"))


def choose(request_id, weights):
    bucket = int(hashlib.sha256(request_id.encode()).hexdigest(), 16) % 100
    edge = 0
    for name, weight in weights.items():
        edge += weight
        if bucket < edge:
            return name
    raise LookupError(f"weights add up to {edge}, not 100")


class Route(BaseHTTPRequestHandler):
    def do_GET(self):
        with open(CONFIG) as f:
            routes = json.load(f)
        side = choose(self.headers.get("X-Request-Id", ""), routes["weights"])
        try:
            with urllib.request.urlopen(routes["backends"][side] + self.path,
                                        timeout=5) as resp:
                status, body = resp.status, resp.read()
        except urllib.error.HTTPError as e:
            status, body = e.code, e.read()
        except OSError:
            status, body = 502, b'{"error": "backend unavailable"}'
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("X-Served-By", side)
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        pass


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", PORT), Route).serve_forever()
```

**The customers**, a script that sends a fixed mix of the shop's usual orders, twenty destinations
in turn, and counts the answers and the errors per copy of production. The mix is fixed so that two
runs over the same request numbers send the same requests. Save it as `ops/load.py`:

```python
"""Send quote requests to a URL and count the answers, per backend.

  python3 ops/load.py URL N [FIRST]

Request number i carries X-Request-Id r<i> and the i-th order of a fixed mix
of the shop's usual destinations, so two runs over the same numbers send the
same requests. An error is a 5xx, or no answer at all.
"""
import sys
import time
import urllib.error
import urllib.request
from collections import Counter

ORDERS = [
    ("01310-100", 800), ("04538-133", 1200), ("05402-000", 300),
    ("13015-904", 2500), ("20040-002", 600), ("22041-001", 1500),
    ("30130-010", 900), ("40010-000", 400), ("50030-230", 1100),
    ("57020-050", 700), ("60060-170", 2000), ("64000-020", 500),
    ("66010-000", 1300), ("69005-010", 800), ("70040-010", 600),
    ("74003-010", 1700), ("80010-000", 900), ("88010-001", 1400),
    ("90010-150", 300), ("29010-000", 1000),
]


def main():
    url, n = sys.argv[1], int(sys.argv[2])
    first = int(sys.argv[3]) if len(sys.argv) > 3 else 1
    sent, errors, slowest = Counter(), Counter(), Counter()
    for i in range(first, first + n):
        cep, weight = ORDERS[i % len(ORDERS)]
        req = urllib.request.Request(
            f"{url}/quote?cep={cep}&weight={weight}&subtotal=8990",
            headers={"X-Request-Id": f"r{i}"})
        started = time.monotonic()
        try:
            with urllib.request.urlopen(req, timeout=5) as resp:
                side, status = resp.headers.get("X-Served-By", "direct"), resp.status
        except urllib.error.HTTPError as e:
            side, status = e.headers.get("X-Served-By", "direct"), e.code
        except OSError:
            side, status = "unanswered", 0
        ms = (time.monotonic() - started) * 1000
        sent[side] += 1
        slowest[side] = max(slowest[side], ms)
        if status == 0 or status >= 500:
            errors[side] += 1
    print(f"{'backend':10} {'requests':>8} {'errors':>6} {'rate':>7}")
    for side in sorted(sent):
        rate = 100 * errors[side] / sent[side]
        print(f"{side:10} {sent[side]:8} {errors[side]:6} {rate:6.1f}%")


if __name__ == "__main__":
    main()
```

**A canary that stops itself**, which moves traffic in steps and sends it all back when the new
release's error rate passes a limit. Lesson 11 runs it and reads it line by line; it is part of
this release, so it goes in now. Save it as `ops/canary.py`:

```python
"""Move traffic to a canary in steps, and stop by rule, not by mood.

  python3 ops/canary.py ROUTES_JSON URL

At each step the canary's share of traffic is raised and a batch of requests
is sent. The canary is stopped, and all traffic sent back to the baseline,
as soon as its error rate exceeds the baseline's by more than MAX_GAP points,
once it has answered at least MIN_REQUESTS. Exit 0 means promoted, 1 aborted.
"""
import json
import subprocess
import sys

STEPS = [5, 25, 50, 100]      # the canary's share of traffic, in percent
BATCH = 400                   # requests sent at each step
MIN_REQUESTS = 50             # do not judge a side on fewer answers than this
MAX_GAP = 1.0                 # percentage points of errors above the baseline


def set_weights(path, baseline, canary, share):
    with open(path) as f:
        routes = json.load(f)
    routes["weights"] = {baseline: 100 - share, canary: share}
    with open(path, "w") as f:
        json.dump(routes, f)


def measure(url, first):
    out = subprocess.run([sys.executable, "ops/load.py", url, str(BATCH), str(first)],
                         capture_output=True, text=True, check=True).stdout
    rates = {}
    for line in out.splitlines()[1:]:
        side, sent, errors, _ = line.split()
        rates[side] = (int(sent), int(errors))
    return rates


def main():
    path, url = sys.argv[1], sys.argv[2]
    baseline, canary = "blue", "green"
    first = 1
    for share in STEPS:
        set_weights(path, baseline, canary, share)
        rates = measure(url, first)
        first += BATCH
        sent, errors = rates.get(canary, (0, 0))
        b_sent, b_errors = rates.get(baseline, (0, 0))
        rate = 100 * errors / sent if sent else 0.0
        b_rate = 100 * b_errors / b_sent if b_sent else 0.0
        print(f"canary at {share:3}%: {canary} {errors}/{sent} = {rate:.1f}%, "
              f"{baseline} {b_errors}/{b_sent} = {b_rate:.1f}%")
        if sent >= MIN_REQUESTS and rate - b_rate > MAX_GAP:
            set_weights(path, baseline, canary, 0)
            print(f"abort: {canary} is {rate - b_rate:.1f} points worse than "
                  f"{baseline}; all traffic back to {baseline}")
            return 1
        if sent < MIN_REQUESTS:
            print(f"        {sent} answers is too few to judge; carrying on")
    print(f"promote: {canary} takes all traffic")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

The whole suite should end with `46 passed, 2 skipped`. Then the release is committed and tagged:

```sh
git add shipquote tests ops
git commit -m "Say how many days delivery takes; route and load for releases"
git tag -a v1.6.0 -m "shipquote 1.6.0"
```
