---
title: The lab: Consul, Traefik and three instances
version: 1
---

Three instances of the stock service, **Consul** as the registry, and **Traefik** as the gateway in
front of them. Neither Consul nor Traefik is told about the instances in advance: the instances
register themselves, and the gateway learns about them from the registry. It lives in `~/lab/gateway`:

```sh
mkdir -p ~/lab/gateway && cd ~/lab/gateway
```

`stock.py`, an instance that registers itself:

```schooling-example
{"language": "python", "file": "stock.py", "parts": [{"code": "\"\"\"A stock instance that registers itself with Consul and reports its health.\"\"\"\nimport json, os, signal, socket, sys, time, urllib.error, urllib.request\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nNAME = os.environ[\"NAME\"]\nCONSUL = \"http://consul:8500\"\nADDRESS = socket.gethostbyname(socket.gethostname())\nstate = {\"healthy\": True}\n\n\ndef consul(method, path, body=None):\n    req = urllib.request.Request(CONSUL + path, method=method,\n                                 data=json.dumps(body).encode() if body is not None else None)\n    urllib.request.urlopen(req).read()\n\n", "note": "A stock service instance that registers itself. On start it tells the local Consul agent its name, its address and how to check its health; on a clean stop it deregisters. `POST /sick` makes its health check fail, the way a process that lost its database connection should report itself."}, {"code": "def register(body):\n    while True:\n        try:\n            return consul(\"PUT\", \"/v1/agent/service/register\", body)\n        except urllib.error.URLError:\n            time.sleep(1)\n\n", "note": "Consul may still be starting when the instance does, so registering is retried every second until Consul answers."}, {"code": "register({\n    \"ID\": NAME, \"Name\": \"stock\", \"Address\": ADDRESS, \"Port\": 8000,\n    \"Tags\": [\"traefik.enable=true\",\n             \"traefik.http.routers.stock.rule=PathPrefix(`/stock`)\",\n             \"traefik.http.routers.stock.middlewares=stock-limit\",\n             \"traefik.http.middlewares.stock-limit.ratelimit.average=5\",\n             \"traefik.http.middlewares.stock-limit.ratelimit.burst=5\"],\n    \"Check\": {\"HTTP\": f\"http://{ADDRESS}:8000/health\", \"Interval\": \"2s\",\n              \"DeregisterCriticalServiceAfter\": \"1m\"},\n})\n\n", "note": "The registration. The tags are not for Consul: they are read by the gateway, which routes `/stock` to every passing instance of `stock` and limits each client to five requests a second, with a burst of five."}, {"code": "def stop(*_):\n    consul(\"PUT\", f\"/v1/agent/service/deregister/{NAME}\")\n    sys.exit(0)\n\n\nsignal.signal(signal.SIGTERM, stop)\n\n\nclass Handler(BaseHTTPRequestHandler):\n    def reply(self, code, text):\n        body = (text + \"\\n\").encode()\n        self.send_response(code)\n        self.send_header(\"Content-Length\", str(len(body)))\n        self.end_headers()\n        self.wfile.write(body)\n\n    def do_GET(self):\n        if self.path == \"/health\":\n            return self.reply(200 if state[\"healthy\"] else 503, \"ok\" if state[\"healthy\"] else \"sick\")\n        self.reply(200, f\"{NAME}: coffee 12\")\n\n    def do_POST(self):\n        state[\"healthy\"] = self.path != \"/sick\"\n        self.reply(200, f\"{NAME}: {'healthy' if state['healthy'] else 'sick'}\")\n\n    def log_message(self, *args):\n        pass\n\n\nThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "A clean stop takes the instance out of the registry at once, instead of leaving the gateway to find out from a failed health check."}]}
```

`where.py`, a client asking the registry:

```schooling-example
{"language": "python", "file": "where.py", "parts": [{"code": "\"\"\"List the healthy instances of a service, from Consul.\"\"\"\nimport json, sys, urllib.request\n\nwith urllib.request.urlopen(f\"http://consul:8500/v1/health/service/{sys.argv[1]}?passing\") as r:\n    entries = json.load(r)\nprint(f\"{len(entries)} healthy instance(s) of {sys.argv[1]}\")\nfor e in sorted(entries, key=lambda e: e[\"Service\"][\"ID\"]):\n    print(f\"  {e['Service']['ID']} at {e['Service']['Address']}:{e['Service']['Port']}\")", "note": "Discovery, the way a client library does it: ask the registry for the instances of a service that are passing their health checks, and print where they are."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nWORKDIR /app\nCOPY *.py .", "note": "Both programs use only Python's standard library."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  consul:\n    image: hashicorp/consul:1.20.2\n    command: agent -dev -client 0.0.0.0 -log-level warn", "note": "Consul, as one server in development mode, which keeps everything in memory. A real cluster runs three or five servers, for lesson 10's reasons."}, {"code": "  gateway:\n    image: traefik:v3.3.4\n    command:\n      - --entrypoints.web.address=:80\n      - --providers.consulcatalog=true\n      - --providers.consulcatalog.endpoint.address=consul:8500\n      - --providers.consulcatalog.exposedbydefault=false\n      - --providers.consulcatalog.refreshinterval=2s\n    ports:\n      - \"8080:80\"\n    depends_on:\n      - consul", "note": "The gateway: Traefik, reading its routes from Consul's catalogue, so that it learns about every instance from the registry and routes only to the healthy ones. It is the shop's only door, on the machine's port 8080."}, {"code": "  stock-1:\n    build: .\n    command: python stock.py\n    environment: {NAME: stock-1}\n    ports: [\"8001:8000\"]\n    depends_on: [consul]\n  stock-2:\n    build: .\n    command: python stock.py\n    environment: {NAME: stock-2}\n    ports: [\"8002:8000\"]\n    depends_on: [consul]\n  stock-3:\n    build: .\n    command: python stock.py\n    environment: {NAME: stock-3}\n    ports: [\"8003:8000\"]\n    depends_on: [consul]\n  tools:\n    build: .\n    profiles: [\"tools\"]\n    entrypoint: [\"python\", \"where.py\"]", "note": "Three instances of the stock service, which know nothing about each other or about the gateway; each one only tells Consul it exists. Ports 8001 to 8003 let `curl` reach each one directly."}]}
```

Start everything, give it fifteen seconds, and keep the command for `where.py` in a variable:

```sh
docker compose up -d --build
D="docker compose --progress quiet run --rm tools"
```

The gateway answers on port 8080 and applies a rate limit, so the lesson's loops pause between requests
to stay under it; the limit gets a section of its own.
