---
title: The lab: a shop with eight threads
version: 1
---

The shop has two pages that matter here: `/stock`, which calls the stock service, and `/catalogue`,
which answers from memory and calls nobody. It serves them from **a pool of eight threads**, which is
small so that the effect is quick to see; a real pool is bigger and fills just the same, only later. It
lives in `~/lab/bulkheads`:

```sh
mkdir -p ~/lab/bulkheads && cd ~/lab/bulkheads
```

`stock.py`:

```schooling-example
{"language": "python", "file": "stock.py", "parts": [{"code": "\"\"\"A stock service whose answers take as long as it is told.\"\"\"\nimport time\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\ndelay = {\"seconds\": 0.02}\n\n\nclass Handler(BaseHTTPRequestHandler):\n    def reply(self, text):\n        body = (text + \"\\n\").encode()\n        self.send_response(200)\n        self.send_header(\"Content-Length\", str(len(body)))\n        self.end_headers()\n        self.wfile.write(body)\n\n    def do_GET(self):\n        time.sleep(delay[\"seconds\"])\n        self.reply(\"coffee: 12\")\n\n    def do_POST(self):\n        delay[\"seconds\"] = float(self.path.split(\"/\")[-1])\n        self.reply(f\"every answer now takes {delay['seconds']} s\")\n\n    def log_message(self, *args):\n        pass\n\n\nThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "The stock service again, reduced to one thing: it answers after a delay that can be changed while it runs. `POST /slow/5` makes every answer take five seconds, the way a service with a database under a long lock might."}]}
```

`shop.py`:

```schooling-example
{"language": "python", "file": "shop.py", "parts": [{"code": "\"\"\"Quitanda's shop: eight threads, a slow dependency, and three ways to protect itself.\"\"\"\nimport os, queue, threading, time, urllib.request\nfrom concurrent.futures import ThreadPoolExecutor\nfrom http.server import BaseHTTPRequestHandler, HTTPServer\n\nBULKHEAD = int(os.environ.get(\"BULKHEAD\", \"0\"))  # threads that may wait on the stock service\nRATE = float(os.environ.get(\"RATE\", \"0\"))        # requests a second allowed per client\nQUEUE = int(os.environ.get(\"QUEUE\", \"0\"))        # orders allowed to wait\n# 0 means no limit, for all three\n\n\nclass PooledServer(HTTPServer):\n    pool = ThreadPoolExecutor(max_workers=8)\n\n    def process_request(self, request, address):\n        self.pool.submit(self.handle_one, request, address)\n\n    def handle_one(self, request, address):\n        try:\n            self.finish_request(request, address)\n        finally:\n            self.shutdown_request(request)\n\n", "note": "The shop, with what every real server has and few people count: **a fixed number of threads**, here eight. A request waits for a free one before anything happens. Three settings, each off by default, are the three protections of this lesson."}, {"code": "stock_slots = threading.BoundedSemaphore(BULKHEAD) if BULKHEAD else None\n", "note": "The bulkhead: a semaphore that lets at most `BULKHEAD` threads wait on the stock service at once. A request that finds it full is refused at once instead of taking a thread too."}, {"code": "buckets = {}  # client -> (tokens, last refill)\nbuckets_lock = threading.Lock()\n\n\ndef allowed(client):\n    if not RATE:\n        return True\n    with buckets_lock:\n        tokens, last = buckets.get(client, (RATE, time.time()))\n        now = time.time()\n        tokens = min(RATE, tokens + (now - last) * RATE)\n        ok = tokens >= 1\n        buckets[client] = (tokens - ok, now)\n        return ok\n\n", "note": "The rate limit: a token bucket per client, named in `X-Client`. Each client's bucket fills at `RATE` tokens a second up to `RATE` tokens, and every request takes one."}, {"code": "orders = queue.Queue(maxsize=QUEUE)\nhandled = {\"count\": 0, \"longest wait\": 0.0}\n\n\ndef work():\n    while True:\n        placed = orders.get()\n        time.sleep(0.1)\n        handled[\"count\"] += 1\n        handled[\"longest wait\"] = max(handled[\"longest wait\"], time.time() - placed)\n\n\nclass Handler(BaseHTTPRequestHandler):\n    def reply(self, code, text, retry_after=None):\n        body = (text + \"\\n\").encode()\n        self.send_response(code)\n        if retry_after:\n            self.send_header(\"Retry-After\", str(retry_after))\n        self.send_header(\"Content-Length\", str(len(body)))\n        self.end_headers()\n        self.wfile.write(body)\n\n    def do_GET(self):\n        if not allowed(self.headers.get(\"X-Client\", \"anonymous\")):\n            return self.reply(429, \"too many requests\", retry_after=1)\n        if self.path == \"/catalogue\":\n            return self.reply(200, \"coffee, tea, rice\")\n        if self.path == \"/orders\":\n            return self.reply(200, f\"handled {handled['count']}, waiting {orders.qsize()}, \"\n                                   f\"longest wait {handled['longest wait']:.1f} s\")\n        if self.path != \"/stock\":\n            return self.reply(404, \"no such page\")\n        if stock_slots and not stock_slots.acquire(blocking=False):\n            return self.reply(503, \"stock: too many waiting already\")\n        try:\n            with urllib.request.urlopen(\"http://stock:8000/\", timeout=10) as r:\n                self.reply(200, r.read().decode().strip())\n        finally:\n            if stock_slots:\n                stock_slots.release()\n\n    def do_POST(self):\n        try:\n            orders.put_nowait(time.time())\n        except queue.Full:\n            return self.reply(503, \"too many orders waiting, try again\", retry_after=2)\n        self.reply(202, \"order accepted\")\n\n    def log_message(self, *args):\n        pass\n\n\nthreading.Thread(target=work, daemon=True).start()\nPooledServer((\"\", 8000), Handler).serve_forever()", "note": "The orders queue, between taking an order and handling it. One worker handles ten orders a second. With `QUEUE` set, the queue holds that many and refuses the rest."}]}
```

`load.py`:

```schooling-example
{"language": "python", "file": "load.py", "parts": [{"code": "\"\"\"Load for the shop: mixed pages, a greedy client, or a burst of orders.\"\"\"\nimport sys, threading, time, urllib.error, urllib.request\nfrom concurrent.futures import ThreadPoolExecutor\n\nSHOP = \"http://shop:8000\"\nresults = {}  # name -> list of (status, milliseconds)\nlock = threading.Lock()\n\n\ndef hit(name, path, client=\"anonymous\", method=\"GET\"):\n    req = urllib.request.Request(SHOP + path, method=method, headers={\"X-Client\": client})\n    start = time.time()\n    try:\n        with urllib.request.urlopen(req, timeout=3) as r:\n            status = r.status\n    except urllib.error.HTTPError as e:\n        status = e.code\n    except (urllib.error.URLError, TimeoutError):\n        status = \"timeout\"\n    with lock:\n        results.setdefault(name, []).append((status, (time.time() - start) * 1000))\n\n\ndef steady(pool, name, path, rate, seconds, client=\"anonymous\"):\n    start = time.time()\n    for n in range(int(rate * seconds)):\n        time.sleep(max(0.0, start + n / rate - time.time()))\n        pool.submit(hit, name, path, client)\n\n", "note": "The load for each experiment, from outside the shop. `mixed` sends 20 requests a second to the stock page and 20 to the catalogue at the same time; `greedy` has one client asking far too often beside one asking normally; `burst` places a number of orders all at once."}, {"code": "def report():\n    for name, rs in sorted(results.items()):\n        ms = sorted(m for _, m in rs)\n        counts = {}\n        for status, _ in rs:\n            counts[status] = counts.get(status, 0) + 1\n        answers = \", \".join(f\"{k}: {v}\" for k, v in sorted(counts.items(), key=str))\n        print(f\"{name:10} {answers:24} median {ms[len(ms) // 2]:5.0f} ms, slowest {ms[-1]:5.0f} ms\")\n\n\nmode = sys.argv[1]\nwith ThreadPoolExecutor(max_workers=500) as pool:\n    if mode == \"mixed\":\n        threads = [threading.Thread(target=steady, args=(pool, n, p, 20, 10))\n                   for n, p in ((\"stock\", \"/stock\"), (\"catalogue\", \"/catalogue\"))]\n        [t.start() for t in threads]\n        [t.join() for t in threads]\n    elif mode == \"greedy\":\n        threads = [threading.Thread(target=steady, args=(pool, c, \"/catalogue\", r, 5, c))\n                   for c, r in ((\"greedy\", 50), (\"ana\", 2))]\n        [t.start() for t in threads]\n        [t.join() for t in threads]\n    elif mode == \"burst\":\n        for _ in range(int(sys.argv[2])):\n            pool.submit(hit, \"orders\", \"/order\", method=\"POST\")\nreport()", "note": "For each kind of request: how many got each answer, and the median and slowest time to get it."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nWORKDIR /app\nCOPY *.py .", "note": "The three programs need only Python's standard library."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  stock:\n    build: .\n    command: python stock.py\n    ports:\n      - \"8001:8000\"\n  shop:\n    build: .\n    command: python shop.py\n    environment:\n      BULKHEAD: ${BULKHEAD:-0}\n      RATE: ${RATE:-0}\n      QUEUE: ${QUEUE:-0}\n    ports:\n      - \"8002:8000\"\n    depends_on:\n      - stock\n  load:\n    build: .\n    profiles: [\"tools\"]\n    entrypoint: [\"python\", \"load.py\"]", "note": "The stock service, the shop with its three settings taken from the shell (all off unless set), and the load, which runs only when asked and leaves the shop as it is, whatever the shell says. Both services are reachable from the machine, on 8001 and 8002, for `curl`."}]}
```

Start the two services, and keep the command for the load in a variable:

```sh
docker compose up -d --build
L="docker compose --progress quiet run --rm load"
```

Ten seconds of 20 stock requests and 20 catalogue requests a second, with everything healthy:

```
ana@vm:~/lab/bulkheads$ $L mixed
catalogue  200: 200                 median     2 ms, slowest    62 ms
stock      200: 200                 median    25 ms, slowest   113 ms
```

Every request got a `200`. The stock page takes a little longer than the catalogue, because it waits
for the stock service's 20 milliseconds; both are far below the load's three-second timeout.
