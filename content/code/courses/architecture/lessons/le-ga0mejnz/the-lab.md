---
title: The lab: a service with a fixed capacity
version: 1
---

The lab is a stock service and a client standing in for the checkout. The service has **a fixed
capacity**, which real services also have even when nobody has measured it: four workers, 50
milliseconds each per answer, so 80 answers a second. The client calls it at a steady rate, and its
options switch on each technique the lesson tries. It lives in `~/lab/resilience`:

```sh
mkdir -p ~/lab/resilience && cd ~/lab/resilience
```

`stock.py`, the service:

```schooling-example
{"language": "python", "file": "stock.py", "parts": [{"code": "\"\"\"A stock service with four workers, which can be told to fail or to freeze.\"\"\"\nimport json, random, threading, time\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nworkers = threading.Semaphore(4)\nstate = {\"fail\": 0.0, \"frozen_until\": 0.0}\nstats = {\"answered\": 0, \"late\": 0}\nlock = threading.Lock()\n\n\nclass Handler(BaseHTTPRequestHandler):\n    def reply(self, code, text):\n        body = (text + \"\\n\").encode()\n        self.send_response(code)\n        self.send_header(\"Content-Length\", str(len(body)))\n        self.end_headers()\n        self.wfile.write(body)\n", "note": "A stock service with a fixed capacity: four workers, and every answer takes 50 milliseconds of one worker's time, so it can answer 80 requests a second and no more. Requests beyond that wait for a worker, in arrival order."}, {"code": "    def do_GET(self):\n        if self.path == \"/stats\":\n            with lock:\n                return self.reply(200, json.dumps(stats))\n        with workers:\n            time.sleep(max(0.0, state[\"frozen_until\"] - time.time()) + 0.05)\n        late = time.time() > float(self.headers.get(\"X-Deadline\", \"inf\"))\n        with lock:\n            stats[\"answered\"] += 1\n            stats[\"late\"] += late\n        if random.random() < state[\"fail\"]:\n            return self.reply(503, \"try again\")\n        self.reply(200, \"coffee: 12\")\n", "note": "Each caller sends the moment it will stop waiting, in `X-Deadline`. The service does not use it to decide anything; it only counts the answers that were finished after the caller had already given up, which is work done for nobody."}, {"code": "    def do_POST(self):\n        _, what, value = self.path.split(\"/\")\n        if what == \"fail\":\n            state[\"fail\"] = float(value)\n        elif what == \"freeze\":\n            state[\"frozen_until\"] = time.time() + float(value)\n        self.reply(200, f\"{what} {value}\")\n\n    def log_message(self, *args):\n        pass\n\n\nThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "`POST /fail/0.2` makes one answer in five a `503`. `POST /freeze/3` stops every worker for three seconds, the way a long garbage-collection pause or a database failover would."}]}
```

`client.py`, the checkout's side:

```schooling-example
{"language": "python", "file": "client.py", "parts": [{"code": "\"\"\"Call the stock service at a steady rate, with or without retries, backoff and a breaker.\"\"\"\nimport argparse, json, random, threading, time, urllib.error, urllib.request\nfrom concurrent.futures import ThreadPoolExecutor\n\np = argparse.ArgumentParser()\np.add_argument(\"--rate\", type=int, default=60, help=\"requests a second\")\np.add_argument(\"--seconds\", type=int, default=30)\np.add_argument(\"--timeout\", type=float, default=0.5)\np.add_argument(\"--retries\", type=int, default=0)\np.add_argument(\"--backoff\", choices=[\"none\", \"jitter\"], default=\"none\")\np.add_argument(\"--breaker\", action=\"store_true\")\np.add_argument(\"--freeze-at\", type=int, help=\"second at which to freeze the service for 3 seconds\")\nargs = p.parse_args()\nSTOCK = \"http://stock:8000\"\nstart = time.time()\ncounts = {}  # two-second bucket -> {\"ok\": n, \"failed\": n, \"calls\": n}\nlock = threading.Lock()\n\n\ndef count(what, at=None):\n    bucket = int((at or time.time()) - start) // 2 * 2\n    with lock:\n        counts.setdefault(bucket, {\"ok\": 0, \"failed\": 0, \"calls\": 0})[what] += 1\n\n", "note": "The checkout's side: it asks the stock service at a steady rate and reports, every two seconds, how many requests succeeded, how many failed, and how many calls reached the service in those seconds, retries included. Every option is a flag, so each run in the lesson is one command."}, {"code": "class Breaker:\n    def __init__(self):\n        self.failures, self.open_until, self.probing = 0, 0.0, False\n        self.lock = threading.Lock()\n\n    def allow(self):\n        with self.lock:\n            if self.failures < 5:\n                return True\n            if time.time() < self.open_until or self.probing:\n                return False\n            self.probing = True\n            return True\n\n    def record(self, ok):\n        with self.lock:\n            self.probing = False\n            self.failures = 0 if ok else self.failures + 1\n            if self.failures >= 5:\n                self.open_until = time.time() + 2\n\n\nbreaker = Breaker() if args.breaker else None\n\n\ndef call():\n    if breaker and not breaker.allow():\n        return False\n    count(\"calls\")\n    req = urllib.request.Request(STOCK + \"/stock/coffee\",\n                                 headers={\"X-Deadline\": str(time.time() + args.timeout)})\n    try:\n        with urllib.request.urlopen(req, timeout=args.timeout):\n            ok = True\n    except (urllib.error.URLError, TimeoutError, ConnectionError):\n        ok = False\n    if breaker:\n        breaker.record(ok)\n    return ok\n\n", "note": "The circuit breaker. After five failures in a row it opens, and for the next two seconds every call fails at once without reaching the service. Then it lets one call through, half-open: if that succeeds it closes, and if it fails it opens again."}, {"code": "def request():\n    sent = time.time()\n    for attempt in range(1 + args.retries):\n        if attempt and args.backoff == \"jitter\":\n            time.sleep(random.uniform(0, 0.1 * 2 ** (attempt - 1)))\n        if call():\n            return count(\"ok\", sent)\n    count(\"failed\", sent)\n\n\ndef freeze():\n    time.sleep(args.freeze_at)\n    urllib.request.urlopen(urllib.request.Request(STOCK + \"/freeze/3\", method=\"POST\")).read()\n\n\ndef stats():\n    with urllib.request.urlopen(STOCK + \"/stats\") as r:\n        return json.load(r)\n\n", "note": "One request from the checkout: the first call, and up to `--retries` more if it fails. With `--backoff jitter` it waits before each retry, a random time up to 0.1, 0.2, 0.4 seconds and so on, doubling each time."}, {"code": "def report(before):\n    after = stats()\n    while True:\n        time.sleep(1)\n        now, after = after, stats()\n        if now == after:\n            break\n    print(f\"the stock service answered {after['answered'] - before['answered']} calls, \"\n          f\"{after['late'] - before['late']} of them after the caller had given up\")\n\n\nbefore = stats()\nif args.freeze_at is not None:\n    threading.Thread(target=freeze, daemon=True).start()\nwith ThreadPoolExecutor(max_workers=2000) as pool:\n    for n in range(args.rate * args.seconds):\n        time.sleep(max(0.0, start + n / args.rate - time.time()))\n        pool.submit(request)\nprint(\" second      ok  failed   calls\")\nfor bucket in sorted(counts):\n    c = counts[bucket]\n    print(f\"{bucket:3}-{bucket + 2:<3}  {c['ok']:6}  {c['failed']:6}  {c['calls']:6}\")\nreport(before)", "note": "At the end the client waits until the service has stopped answering calls, because a call the client gave up on is still in the service's queue, and reports what the service did for this run: how many calls it answered, and how many of those after the caller had stopped waiting."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nWORKDIR /app\nCOPY *.py .", "note": "Both programs use only Python's standard library."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  stock:\n    build: .\n    command: python stock.py\n    ports:\n      - \"8001:8000\"\n  client:\n    build: .\n    profiles: [\"tools\"]\n    entrypoint: [\"python\", \"client.py\"]\n    depends_on:\n      - stock", "note": "The stock service, reachable from the machine on port 8001 for `curl`, and the checkout's client, which runs only when asked."}]}
```

Start the service, and keep the command that runs the client in a variable:

```sh
docker compose up -d --build
C="docker compose --progress quiet run --rm client"
```

A healthy run first: 60 requests a second for ten seconds, three quarters of the service's capacity,
with the default half-second timeout and no retries:

```
ana@vm:~/lab/resilience$ $C --seconds 10
 second      ok  failed   calls
  0-2       120       0     120
  2-4       120       0     120
  4-6       120       0     120
  6-8       120       0     120
  8-10      120       0     120
the stock service answered 600 calls, 0 of them after the caller had given up
```

Every request succeeded, each made exactly one call, and the service answered every one of them in time.
That is the baseline for everything that follows.
