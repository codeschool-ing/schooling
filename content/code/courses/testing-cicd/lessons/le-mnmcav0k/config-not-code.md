---
title: Configuration lives outside the code
version: 2
---

If the artifact is the same in every environment, the differences have to come from somewhere else,
and the usual answer is the one popularised by *The Twelve-Factor App*: **the program reads its
configuration from the environment it runs in**, as environment variables, and the code contains no
environment's settings. `shipquote` reads four:

| variable | what it decides | if absent |
|---|---|---|
| `SHIPQUOTE_PORT` | the port it listens on | 8080 |
| `SHIPQUOTE_ENV` | the name it reports on `/version` | `dev` |
| `SHIPQUOTE_CARRIER_URL` | the carrier it asks for prices | none: the shop's own table |
| `SHIPQUOTE_CARRIER_TOKEN` | the key it presents to the carrier | empty |

The two carrier variables are this lesson's change to the code. When `SHIPQUOTE_CARRIER_URL` names
a carrier, a quote asks it, through lesson 2's `carrier.price`, and `/version` says where prices
come from. Save it as `shipquote/app.py`:

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
                "cents": cents, "price": money.brl(cents)}

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

One test is added, for the answer when no carrier is named. Save them as `tests/test_app.py`:

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
                    "cents": 2190, "price": "R$ 21,90"}


def test_a_bad_cep_is_a_400_that_says_why(base_url):
    status, body = get(base_url + "/quote?cep=abc&weight=1200")
    assert status == 400
    assert body == {"error": "not a CEP: 'abc'"}


def test_version_says_the_table_is_used_when_no_carrier_is_named(base_url):
    assert get(base_url + "/version")[1]["carrier"] == "table"
```

Commit it, tag the commit as release 1.5.0 and build its artifact:

```sh
git commit -am "Ask the carrier when the environment names one"
git tag -a v1.5.0 -m "shipquote 1.5.0"
ops/build.sh
```

Then the three configurations. Development has a port and nothing else; staging and production
each name a carrier and carry its token:

```sh
mkdir -p ~/envs/dev ~/envs/staging ~/envs/production
echo SHIPQUOTE_PORT=8100 > ~/envs/dev/config.env
printf 'SHIPQUOTE_PORT=8200\nSHIPQUOTE_CARRIER_URL=http://127.0.0.1:9091\nSHIPQUOTE_CARRIER_TOKEN=lab-sandbox-token\n' > ~/envs/staging/config.env
printf 'SHIPQUOTE_PORT=8300\nSHIPQUOTE_CARRIER_URL=http://127.0.0.1:9092\nSHIPQUOTE_CARRIER_TOKEN=lab-live-token\n' > ~/envs/production/config.env
```

Here they are, with the token lines filtered out from now on, since lesson 9 is about them:

```
ana@laptop:~/shipquote$ grep -v TOKEN ~/envs/*/config.env
/home/ana/envs/dev/config.env:SHIPQUOTE_PORT=8100
/home/ana/envs/production/config.env:SHIPQUOTE_PORT=8300
/home/ana/envs/production/config.env:SHIPQUOTE_CARRIER_URL=http://127.0.0.1:9092
/home/ana/envs/staging/config.env:SHIPQUOTE_PORT=8200
/home/ana/envs/staging/config.env:SHIPQUOTE_CARRIER_URL=http://127.0.0.1:9091
```

Development has only a port, so it prices from the table. Staging and production each name a
carrier. The **same artifact** goes to all three, and each answers with its own identity:

```
ana@laptop:~/shipquote$ for env in dev staging production; do ops/deploy.sh $env dist/shipquote-1.5.0.tar.gz; done
smoke: http://127.0.0.1:8100 is up and running 1.5.0
smoke: http://127.0.0.1:8200 is up and running 1.5.0
smoke: http://127.0.0.1:8300 is up and running 1.5.0
ana@laptop:~/shipquote$ for port in 8100 8200 8300; do curl -s http://127.0.0.1:$port/version; echo; done
{"version": "1.5.0", "env": "dev", "carrier": "table"}
{"version": "1.5.0", "env": "staging", "carrier": "http://127.0.0.1:9091"}
{"version": "1.5.0", "env": "production", "carrier": "http://127.0.0.1:9092"}
```

Three smoke tests passed, one per environment, and the three `/version` answers say the same
version, three environment names and three different sources of prices.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"One artifact, shipquote-1.5.0.tar.gz, at the top, with lines to three environments. dev on port 8100 prices from the table and quotes R$ 21,90. staging on port 8200 asks the carrier on 9091 and quotes R$ 18,60. production on port 8300 asks the carrier on 9092 and quotes R$ 18,60.\"><rect x=\"250\" y=\"16\" width=\"220\" height=\"40\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">shipquote-1.5.0.tar.gz</text><path d=\"M360 56 L125 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><rect x=\"30\" y=\"96\" width=\"190\" height=\"96\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"125\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" fill=\"var(--paper)\">dev</text><text x=\"44\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SHIPQUOTE_PORT=8100</text><text x=\"44\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">prices from: the table</text><text x=\"44\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">R$ 21,90</text><path d=\"M360 56 L355 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><rect x=\"260\" y=\"96\" width=\"190\" height=\"96\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" fill=\"var(--paper)\">staging</text><text x=\"274\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SHIPQUOTE_PORT=8200</text><text x=\"274\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">prices from: carrier :9091</text><text x=\"274\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">R$ 18,60</text><path d=\"M360 56 L585 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><rect x=\"490\" y=\"96\" width=\"190\" height=\"96\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"585\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" fill=\"var(--paper)\">production</text><text x=\"504\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SHIPQUOTE_PORT=8300</text><text x=\"504\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">prices from: carrier :9092</text><text x=\"504\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">R$ 18,60</text><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the same bytes in every box; only the configuration differs</text><text x=\"360\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the quote is for 1.2 kg to São Paulo with a R$ 50,00 basket</text></svg>", "caption": "Section 03's three deploys and section 04's three answers in one drawing. The difference between R$ 21,90 and R$ 18,60 is configuration, not code."}
```

## Where the values come from at run time

`restart.sh` reads `config.env` into the environment of the process it starts, so the values live
in the running process and nowhere in the release. On Linux that is visible from outside:

```
ana@laptop:~/shipquote$ tr '\0' '\n' < /proc/$(cat ~/envs/production/pid)/environ | grep ^SHIPQUOTE_ | grep -v TOKEN
SHIPQUOTE_CARRIER_URL=http://127.0.0.1:9092
SHIPQUOTE_ENV=production
SHIPQUOTE_PORT=8300
```

`/proc/<pid>/environ` holds the environment a process was started with. The production process sees
its port, its carrier and its name, which `restart.sh` sets from the directory. That file is
readable by the process's owner and by root, which matters for the tokens that were filtered out
above, and lesson 9 starts from it.

## What does not belong in configuration

Configuration is for **what differs between environments**. A business rule such as the
free-shipping threshold is the same everywhere and belongs in the code, behind tests, as it is in
`quote.py`. Making it a variable "for flexibility" would turn a tested rule into an untested value
that one environment can set differently from another, and section 07 shows what a difference like
that looks like when nobody can see it.
