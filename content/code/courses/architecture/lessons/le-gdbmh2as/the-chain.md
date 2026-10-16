---
title: A chain of three
version: 1
---

To see what synchronous calls do to each other, the lab builds a chain: Quitanda's checkout asks
pricing for the basket's total, and pricing asks stock whether the items are there. The three links
are the same small program with different settings. The lesson works in `~/lab/chain`:

```sh
mkdir -p ~/lab/chain && cd ~/lab/chain
```

`hop.py`, one link of the chain:

```schooling-example
{"language": "python", "file": "hop.py", "parts": [{"code": "\"\"\"A service that does some work and then asks the next one.\"\"\"\nimport json, os, time, urllib.error, urllib.request\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nNAME = os.environ[\"NAME\"]\nNEXT = os.environ.get(\"NEXT\")\nDELAY = int(os.environ.get(\"DELAY_MS\", \"0\")) / 1000\nTIMEOUT = float(os.environ[\"TIMEOUT_S\"]) if os.environ.get(\"TIMEOUT_S\") else None\n\n", "note": "One link of a chain of services. Each copy does DELAY_MS of work, then, if NEXT is set, calls the next link and waits for its answer, for at most TIMEOUT_S seconds when that is set and for as long as it takes when it is not."}, {"code": "class Handler(BaseHTTPRequestHandler):\n    def do_GET(self):\n        start = time.monotonic()\n        time.sleep(DELAY)\n        status, body = 200, {\"name\": NAME}\n        if NEXT:\n            try:\n                with urllib.request.urlopen(NEXT, timeout=TIMEOUT) as r:\n                    body[\"next\"] = json.loads(r.read())\n            except urllib.error.HTTPError as e:\n                status, body[\"error\"] = 502, f\"{NEXT} answered {e.code}\"\n                body[\"next\"] = json.loads(e.read())\n            except TimeoutError:\n                status, body[\"error\"] = 504, f\"{NEXT} did not answer within {TIMEOUT} s\"\n            except OSError as e:\n                status, body[\"error\"] = 502, f\"{NEXT} unreachable: {e}\"\n        body[\"took_ms\"] = round((time.monotonic() - start) * 1000)\n        data = (json.dumps(body) + \"\\n\").encode()\n        self.send_response(status)\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)\n\n    def log_message(self, fmt, *args):\n        print(f\"{NAME} {fmt % args}\", flush=True)\n\n\nThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "The answer carries this link's name, how long the whole call took from here, and the answer of the next link inside it, so one response shows the whole chain."}]}
```

`report.py` belongs to a later section of this lesson; save it now so that it is in the image:

```schooling-example
{"language": "python", "file": "report.py", "parts": [{"code": "\"\"\"Quitanda's monthly sales report, built in the background.\"\"\"\nimport json, threading, time\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\njobs = {}\n\n\ndef build(job_id):\n    time.sleep(3)  # stands in for three seconds of queries\n    jobs[job_id] = {\"status\": \"done\", \"orders\": 412, \"revenue_cents\": 1893450}\n\n\nclass Handler(BaseHTTPRequestHandler):\n    def reply(self, status, body, location=None):\n        data = (json.dumps(body) + \"\\n\").encode()\n        self.send_response(status)\n        if location:\n            self.send_header(\"Location\", location)\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)\n", "note": "Asynchronous request-reply over plain HTTP. A request to build the monthly report is accepted at once with `202 Accepted` and the address where its result will be; the work runs in the background, and the client asks that address until the report is done."}, {"code": "    def do_POST(self):\n        job_id = str(len(jobs) + 1)\n        jobs[job_id] = {\"status\": \"running\"}\n        threading.Thread(target=build, args=(job_id,)).start()\n        self.reply(202, {\"job\": job_id}, location=f\"/reports/{job_id}\")\n", "note": "POST starts a job and returns before it has done any of it."}, {"code": "    def do_GET(self):\n        job = jobs.get(self.path.rsplit(\"/\", 1)[-1])\n        self.reply(200, job) if job else self.reply(404, {\"error\": \"no such job\"})\n\n    def log_message(self, *args):\n        pass\n\n\nThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "GET on the job's address says how far it has got. A real service would keep the jobs in a database, not in memory, as lesson 4 explained."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nWORKDIR /app\nCOPY *.py .\nCMD [\"python\", \"hop.py\"]", "note": "One image for every link; what makes each link different is its environment."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  checkout:\n    build: .\n    environment: {NAME: checkout, NEXT: \"http://pricing:8000/\", DELAY_MS: \"100\"}\n    ports: [\"127.0.0.1:8000:8000\"]\n  pricing:\n    build: .\n    environment: {NAME: pricing, NEXT: \"http://stock:8000/\", DELAY_MS: \"100\", TIMEOUT_S: \"${PRICING_TIMEOUT_S:-}\"}\n  stock:\n    build: .\n    environment: {NAME: stock, DELAY_MS: \"${STOCK_DELAY_MS:-100}\"}", "note": "Quitanda's checkout as a chain: the checkout asks pricing, pricing asks stock. Each link does 100 ms of work of its own, and two settings can be changed from the shell: how slow stock is, and how long pricing waits for it."}, {"code": "  reports:\n    build: .\n    command: [\"python\", \"report.py\"]\n    ports: [\"127.0.0.1:8001:8000\"]", "note": "The sales report runs as a service of its own, on port 8001, and answers in the asynchronous style of the last section."}]}
```

## One request through the chain

```
ana@vm:~/lab/chain$ docker compose ps --format "{{.Service}} {{.Status}} {{.Ports}}"
checkout Up 2 seconds 127.0.0.1:8000->8000/tcp
pricing Up 2 seconds 
reports Up 2 seconds 127.0.0.1:8001->8000/tcp
stock Up 2 seconds 
ana@vm:~/lab/chain$ curl -s localhost:8000/
{"name": "checkout", "next": {"name": "pricing", "next": {"name": "stock", "took_ms": 100}, "took_ms": 242}, "took_ms": 373}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A sequence diagram with four lifelines: the client, checkout, pricing and stock. The client&#x27;s request goes to checkout, which calls pricing, which calls stock. Each caller is drawn with a waiting bar that lasts until the answer from below returns, so the client waits for the whole stack of work.\"><defs><marker id=\"l5-wait-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"280\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"24\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">client</text><rect x=\"210\" y=\"24\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">checkout</text><rect x=\"390\" y=\"24\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pricing</text><rect x=\"570\" y=\"24\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">stock</text><path d=\"M90 56 L90 68\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M90 268 L90 280\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M270 56 L270 80\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M270 256 L270 280\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M450 56 L450 92\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M450 244 L450 280\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M630 56 L630 104\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M630 232 L630 280\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"84\" y=\"70\" width=\"12\" height=\"196\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"264\" y=\"82\" width=\"12\" height=\"172\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"444\" y=\"94\" width=\"12\" height=\"148\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"624\" y=\"106\" width=\"12\" height=\"124\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M98 80 L262 80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-wait-ah-phosphor)\"></path><path d=\"M262 262 L98 262\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l5-wait-ah-phosphor)\"></path><path d=\"M278 92 L442 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-wait-ah-phosphor)\"></path><path d=\"M442 250 L278 250\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l5-wait-ah-phosphor)\"></path><path d=\"M458 104 L622 104\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-wait-ah-phosphor)\"></path><path d=\"M622 238 L458 238\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l5-wait-ah-phosphor)\"></path><text x=\"180\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">waiting</text><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">waiting</text><text x=\"540\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">waiting</text><text x=\"680\" y=\"168\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">work</text></svg>", "caption": "In a synchronous chain every caller waits for everything below it. The client's wait is the sum of all the work, plus every hop."}
```

Read the answer from the inside out. Stock did its 100 ms of work and answered in 100. Pricing did
its own 100 ms, waited for stock, and answered after 242. Checkout did the same on top and answered
after 373. **Each link's time includes everything below it**: the client waited for all three
services' work plus every network hop between them, and each hop also paid for opening a new
connection, since `urllib` opens one per request.

That sum is the first cost of a chain. A checkout that calls five services one after another, each
taking 50 ms, cannot answer in less than 250 ms however fast the checkout itself is. Where the calls
do not depend on each other, making them **in parallel** turns the sum into the slowest of them, which
is one of the few optimisations that changes a chain's arithmetic rather than its constants.
