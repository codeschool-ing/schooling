---
title: Portable seams, and what portability costs
version: 1
---

The answer to API lock-in is usually put as a choice of service: pick the portable one. **The
better answer is a choice of where the provider is allowed to appear in your code.** A seam is the
line between the part of a program that knows what the shop does and the part that knows where it
runs. Draw it once, keep the provider on one side of it, and moving means rewriting the thin side.

## The shop's quote, three files

The rule the shop cares about is a quote: a list of items in, a total in cents out. It goes in a
file that imports nothing from AWS and nothing about HTTP:

```python
# orders.py
"""The shop's order rules. Nothing here knows where it runs."""

PRICES = {"tee": 7990, "mug": 3490, "cap": 5990}   # cents


def quote(order):
    """Status and body for an order such as {"items": {"tee": 2, "mug": 1}}."""
    items = order.get("items") or {}
    unknown = sorted(set(items) - set(PRICES))
    if unknown:
        return 400, {"error": "unknown item: " + ", ".join(unknown)}
    total = sum(PRICES[name] * count for name, count in items.items())
    return 200, {"items": sum(items.values()), "total_cents": total}
```

Lambda reaches it through a handler. The event is the shape a function URL or an HTTP API sends,
with the request body as a string, and the answer is the shape they expect back:

```python
# lambda_app.py
import json

from orders import quote


def handler(event, context):
    status, body = quote(json.loads(event.get("body") or "{}"))
    return {"statusCode": status,
            "headers": {"content-type": "application/json"},
            "body": json.dumps(body)}
```

A container reaches it through a web server. This one uses only Python's standard library, which
is enough to show the seam; a real service would use a framework, and the seam would be the same:

```python
# server.py
import json
from http.server import BaseHTTPRequestHandler, HTTPServer

from orders import quote


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        size = int(self.headers.get("content-length", 0))
        status, body = quote(json.loads(self.rfile.read(size) or b"{}"))
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


HTTPServer(("127.0.0.1", 8008), Handler).serve_forever()
```

Save the three in one directory, `~/aws/shop`.

## The same rule, run both ways

As a server, started in the background with its log sent to a file, and asked for a quote:

```
ana@laptop:~/aws/shop$ python3 server.py 2> server.log &
ana@laptop:~/aws/shop$ curl -s -XPOST localhost:8008/quote -d '{"items": {"tee": 2, "mug": 1}}'; echo
{"items": 3, "total_cents": 19470}
ana@laptop:~/aws/shop$ curl -s -XPOST localhost:8008/quote -d '{"items": {"hat": 1}}'; echo
{"error": "unknown item: hat"}
ana@laptop:~/aws/shop$ kill %1
```

As a Lambda function, in the AWS base image with the Runtime Interface Emulator that lesson 14
introduced. **This part really runs**: it is the runtime AWS publishes, on your laptop, and the
event is the one a function URL would deliver:

```
ana@laptop:~/aws/shop$ docker run --rm -d --name shop -p 9000:8080 -v "$PWD":/var/task:ro public.ecr.aws/lambda/python:3.12 lambda_app.handler > /dev/null
ana@laptop:~/aws/shop$ curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{"body": "{\"items\": {\"tee\": 2, \"mug\": 1}}"}'; echo
{"statusCode": 200, "headers": {"content-type": "application/json"}, "body": "{\"items\": 3, \"total_cents\": 19470}"}
ana@laptop:~/aws/shop$ curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{"body": "{\"items\": {\"hat\": 1}}"}'; echo
{"statusCode": 400, "headers": {"content-type": "application/json"}, "body": "{\"error\": \"unknown item: hat\"}"}
ana@laptop:~/aws/shop$ docker stop shop
shop
```

The same 19,470 cents, and the same error for an item the shop does not sell, came out of two
runtimes that share nothing but `orders.py`. Neither adapter contains a rule of the shop's.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two dashed boundaries side by side: on the left a Lambda execution environment holding lambda_app.py, which takes an event in and gives a dictionary out; on the right a container on any provider holding server.py, which takes HTTP in and gives HTTP out. Between them, belonging to neither, orders.py with the shop&#x27;s rule. An arrow runs from each adapter to orders.py. Notes below: the seam is two lines in each adapter, the import and the call, and leaving rewrites an adapter, never the rule.\"><defs><marker id=\"l24s-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"300\" height=\"120\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"35\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">a Lambda execution environment</text><rect x=\"400\" y=\"30\" width=\"300\" height=\"120\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"415\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">a container, on any provider</text><rect x=\"45\" y=\"80\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lambda_app.py</text><text x=\"120\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">event in, dict out</text><rect x=\"525\" y=\"80\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">server.py</text><text x=\"600\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">HTTP in, HTTP out</text><rect x=\"285\" y=\"180\" width=\"150\" height=\"55\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"360\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders.py</text><text x=\"360\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the shop's rule</text><path d=\"M120 131 L120 207 L283 207\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l24s-phosphor)\"></path><path d=\"M600 131 L600 207 L437 207\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l24s-phosphor)\"></path><text x=\"360\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">the seam: two lines in each adapter, the import and the call</text><text x=\"360\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">leaving rewrites an adapter, never the rule</text></svg>", "caption": "Two runtimes, one rule. Each adapter knows its runtime and reaches the rule through one import and one call."}
```

## Seams worth having

The same idea applies wherever the provider would otherwise reach into the code:

- **the image** is the seam for compute. An OCI image built from a Dockerfile runs on Fargate, EKS,
  App Runner, a laptop and any other provider's container service; the task definition around it
  is the part that stays behind;
- **open protocols** are the seam for traffic: HTTP in, SQL to the database, and a queue client
  behind an interface of your own rather than SQS calls scattered through the code;
- **a thin adapter round the SDK** is the seam for storage: a `save_report(name, data)` function
  that calls S3 in one place, so the day the reports move, one function changes.

## What portability costs

**A seam is code, and code is paid for.** The adapters above are small because the rule is small;
the price grows with every feature of the platform you decide not to use directly. A team that
wraps Step Functions in its own workflow layer so it could move one day has written a workflow
engine, and will maintain it on every day it does not move.

The opposite mistake is just as real. Refusing every managed service in the name of portability
means running your own queue, your own scheduler and your own database on instances, which costs
more every month than most exits ever would. **Portability is worth paying for where leaving is
likely or expensive, and nowhere else**, and the next section turns that sentence into numbers.
