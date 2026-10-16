---
title: The lab: a monolith behind an edge
version: 1
---

The lab is Quitanda's monolith with the stock module already copied out into a service of its own, and
an **nginx** in front of both as the facade. Two more small programs stand beside them and are the
subject of the second half of the lesson. It lives in `~/lab/strangler`:

```sh
mkdir -p ~/lab/strangler && cd ~/lab/strangler
```

`monolith.py`:

```schooling-example
{"language": "python", "file": "monolith.py", "parts": [{"code": "\"\"\"Quitanda's monolith: catalogue, stock and checkout in one process.\"\"\"\nimport urllib.error, urllib.request\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nSTOCK = {\"coffee\": 12, \"tea\": 30}\n\n\nclass Handler(BaseHTTPRequestHandler):\n    def reply(self, code, text):\n        body = (text + \"\\n\").encode()\n        self.send_response(code)\n        self.send_header(\"Content-Length\", str(len(body)))\n        self.end_headers()\n        self.wfile.write(body)\n\n    def do_GET(self):\n        if self.path == \"/catalogue\":\n            return self.reply(200, \"monolith: coffee, tea\")\n        if self.path.startswith(\"/stock/\"):\n            sku = self.path.split(\"/\")[2]\n            return self.reply(200, f\"monolith: {sku} {STOCK[sku]}\")\n        self.reply(404, \"monolith: no such page\")\n\n    def do_POST(self):\n        try:\n            with urllib.request.urlopen(urllib.request.Request(\"http://localhost:9000/charge\", method=\"POST\"),\n                                        timeout=5) as r:\n                self.reply(200, f\"monolith: checkout done, gateway said {r.read().decode().strip()}\")\n        except urllib.error.HTTPError as e:\n            self.reply(502, f\"monolith: checkout failed, gateway said {e.code}\")\n\n    def log_message(self, *args):\n        pass\n\n\nThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "The monolith, as lesson 1 left it, reduced to three routes: the catalogue, the stock of a product, and a checkout that charges a card. The checkout calls the payment gateway at `localhost:9000`, which is the ambassador's address, not the gateway's: a later section explains."}]}
```

`stock.py`, the stock module as a service:

```schooling-example
{"language": "python", "file": "stock.py", "parts": [{"code": "\"\"\"The stock service, taken out of the monolith.\"\"\"\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nSTOCK = {\"coffee\": 12, \"tea\": 30}\n\n\nclass Handler(BaseHTTPRequestHandler):\n    def do_GET(self):\n        sku = self.path.split(\"/\")[2]\n        body = f\"stock service: {sku} {STOCK[sku]}\\n\".encode()\n        self.send_response(200)\n        self.send_header(\"Content-Length\", str(len(body)))\n        self.end_headers()\n        self.wfile.write(body)\n\n    def log_message(self, *args):\n        pass\n\n\nThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "The stock module, moved out into a service of its own. It answers the same URL as the monolith did, with the same numbers, so that nothing calling it has to change; only the name in its answer is different, which is how the lesson can see which one answered."}]}
```

`proxy.py`, which runs twice, as the sidecar and as the ambassador:

```schooling-example
{"language": "python", "file": "proxy.py", "parts": [{"code": "\"\"\"Forward requests to one upstream, logging each, with optional retries and an API key.\"\"\"\nimport os, time, urllib.error, urllib.request\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nLISTEN = int(os.environ[\"LISTEN\"])\nUPSTREAM = os.environ[\"UPSTREAM\"]\nRETRIES = int(os.environ.get(\"RETRIES\", \"0\"))\nAPI_KEY = os.environ.get(\"API_KEY\")\nNAME = os.environ[\"NAME\"]\n\n\nclass Handler(BaseHTTPRequestHandler):\n    def forward(self):\n        start = time.time()\n        headers = {\"X-Api-Key\": API_KEY} if API_KEY else {}\n        for attempt in range(1 + RETRIES):\n            req = urllib.request.Request(UPSTREAM + self.path, method=self.command, headers=headers)\n            try:\n                with urllib.request.urlopen(req, timeout=5) as r:\n                    status, body = r.status, r.read()\n            except urllib.error.HTTPError as e:\n                status, body = e.code, e.read()\n            if status != 503:\n                break\n        ms = (time.time() - start) * 1000\n        print(f\"{NAME}: {self.command} {self.path} -> {status} in {ms:.0f} ms, {attempt + 1} attempt(s)\",\n              flush=True)\n        self.send_response(status)\n        self.send_header(\"Content-Length\", str(len(body)))\n        self.end_headers()\n        self.wfile.write(body)\n\n    do_GET = do_POST = forward\n\n    def log_message(self, *args):\n        pass\n\n\nThreadingHTTPServer((\"\", LISTEN), Handler).serve_forever()", "note": "One small proxy, used twice in the lab. It listens on `LISTEN`, forwards every request to `UPSTREAM`, and prints a line for each: method, path, status and time taken. With `RETRIES` set it tries again on a `503`, and with `API_KEY` set it adds the key to the request. What makes it a sidecar or an ambassador is not its code but whom it is put beside."}]}
```

`gateway.py`, standing in for an external payment gateway:

```schooling-example
{"language": "python", "file": "gateway.py", "parts": [{"code": "\"\"\"A payment gateway that wants an API key and is busy half the time.\"\"\"\nimport itertools\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\ncalls = itertools.count(1)\n\n\nclass Handler(BaseHTTPRequestHandler):\n    def do_POST(self):\n        if self.headers.get(\"X-Api-Key\") != \"sk_test_quitanda\":\n            code, text = 401, \"no valid API key\"\n        elif next(calls) % 2 == 0:\n            code, text = 503, \"busy, try again\"\n        else:\n            code, text = 200, \"charged\"\n        body = (text + \"\\n\").encode()\n        self.send_response(code)\n        self.send_header(\"Content-Length\", str(len(body)))\n        self.end_headers()\n        self.wfile.write(body)\n\n    def log_message(self, *args):\n        pass\n\n\nThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "A stand-in for an external payment gateway: it refuses a request without the right API key, and answers every second request with `503`, the way a busy third party does."}]}
```

`nginx.conf`, the edge:

```schooling-example
{"language": "conf", "file": "nginx.conf", "parts": [{"code": "events {}\nhttp {\n    upstream monolith { server monolith:8000; }\n    upstream stock    { server stock:8080; }\n", "note": "The edge, the strangler's facade: every request to the shop comes in here, on port 8080 of the machine. `/stock/` goes to whichever backend `stock-split.conf` picks for the request; everything else goes to the monolith."}, {"code": "    include /etc/nginx/stock-split.conf;\n\n    server {\n        listen 80;\n        location /stock/ { proxy_pass http://$stock_backend; }\n        location /       { proxy_pass http://monolith; }\n    }\n}", "note": "Which backend serves `/stock/` is decided in a file of its own, so that moving traffic is editing that file and reloading."}]}
```

`stock-split.conf`, the one setting the migration moves:

```schooling-example
{"language": "conf", "file": "stock-split.conf", "parts": [{"code": "split_clients \"${request_id}\" $stock_backend {\n    * monolith;\n}", "note": "Where `/stock/` goes. `split_clients` turns each request's id into a percentage and picks a backend by it; at the start, all of it goes to the monolith."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nWORKDIR /app\nCOPY *.py .", "note": "Every program in the lab uses only Python's standard library."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  edge:\n    image: nginx:1.27-alpine\n    volumes:\n      - ./nginx.conf:/etc/nginx/nginx.conf:ro\n      - ./stock-split.conf:/etc/nginx/stock-split.conf:ro\n    ports:\n      - \"8080:80\"\n    depends_on:\n      - monolith\n      - stock", "note": "The edge, published on the machine's port 8080, with its two configuration files mounted from the lab directory."}, {"code": "  monolith:\n    build: .\n    command: python monolith.py\n  ambassador:\n    build: .\n    command: python proxy.py\n    network_mode: service:monolith\n    environment:\n      NAME: ambassador\n      LISTEN: \"9000\"\n      UPSTREAM: http://gateway:8000\n      RETRIES: \"2\"\n      API_KEY: sk_test_quitanda\n  gateway:\n    build: .\n    command: python gateway.py", "note": "The monolith, and its **ambassador**: a proxy in the monolith's own network namespace (`network_mode: service:monolith`), so that for the monolith it is `localhost:9000`. It adds the API key and retries the gateway's `503`s."}, {"code": "  stock:\n    build: .\n    command: python stock.py\n  sidecar:\n    build: .\n    command: python proxy.py\n    network_mode: service:stock\n    environment:\n      NAME: sidecar\n      LISTEN: \"8080\"\n      UPSTREAM: http://localhost:8000", "note": "The new stock service, and its **sidecar**: a proxy in the stock service's namespace, listening on 8080 and forwarding to the service on `localhost:8000`, logging every request on its way in. The edge talks to the sidecar, never to the service directly."}]}
```

Start everything, and ask the edge for a page and for the stock of coffee:

```
ana@vm:~/lab/strangler$ curl -s localhost:8080/catalogue; curl -s localhost:8080/stock/coffee
monolith: coffee, tea
monolith: coffee 12
```

Both answers came from the monolith, through the edge. That is step 1 of the migration, and it already
matters: from now on no client talks to the monolith directly, so where a request goes can be changed
in one place without anybody else knowing.
