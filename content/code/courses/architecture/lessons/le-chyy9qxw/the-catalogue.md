---
title: A catalogue written to the factors
version: 1
---

The lesson's program is Quitanda's catalogue again, this time against PostgreSQL rather than an
SQLite file, because a real database server is the backing service most of the factors are about.
It lives in `~/lab/twelve`:

```sh
mkdir -p ~/lab/twelve && cd ~/lab/twelve
```

`catalogue.py`:

```schooling-example
{"language": "python", "file": "catalogue.py", "parts": [{"code": "\"\"\"Quitanda's catalogue, written to the twelve factors.\"\"\"\nimport json, os, signal, socket, sys, threading\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nimport psycopg\n\nDATABASE_URL = os.environ.get(\"DATABASE_URL\")\nif not DATABASE_URL:\n    sys.exit(\"DATABASE_URL is not set: give the catalogue the address of its database\")\nPORT = int(os.environ.get(\"PORT\", \"8000\"))\nHOST = socket.gethostname()\nhits = 0\n", "note": "Quitanda's catalogue as a twelve-factor app. Every setting comes from the environment (III), and the one without which nothing works, the database's address, stops the program at once with a sentence saying what is missing."}, {"code": "PRODUCTS = [(\"tomato\", \"Tomatoes, 1 kg\", 899), (\"banana\", \"Bananas, 1 kg\", 649),\n            (\"coffee\", \"Coffee beans, 500 g\", 3290), (\"cheese\", \"Minas cheese, 500 g\", 2450),\n            (\"bread\", \"Bread rolls, 6\", 990)]\n\n\ndef migrate():\n    with psycopg.connect(DATABASE_URL) as con:\n        con.execute(\"CREATE TABLE IF NOT EXISTS products (sku text PRIMARY KEY, name text, price_cents int)\")\n        for p in PRODUCTS:\n            con.execute(\"INSERT INTO products VALUES (%s, %s, %s) ON CONFLICT DO NOTHING\", p)\n    print(f\"migrated: {len(PRODUCTS)} products\", flush=True)\n\n", "note": "The admin task (XII) is part of the same program: `python catalogue.py migrate` creates the table and the products, then exits. It runs with the same code and the same configuration as the service."}, {"code": "class Handler(BaseHTTPRequestHandler):\n    def reply(self, status, body):\n        data = (json.dumps(body) + \"\\n\").encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)\n\n    def do_GET(self):\n        global hits\n        hits += 1\n        if self.path == \"/products\":\n            with psycopg.connect(DATABASE_URL) as con:\n                rows = con.execute(\"SELECT sku, price_cents FROM products ORDER BY sku\").fetchall()\n            self.reply(200, {\"served_by\": HOST, \"products\": dict(rows)})\n        elif self.path == \"/hits\":\n            self.reply(200, {\"served_by\": HOST, \"hits\": hits})\n        else:\n            self.reply(404, {\"error\": \"not found\"})\n", "note": "The service. `/products` reads the backing database (IV). `/hits` counts requests in this process's memory, which is exactly what factor VI says not to do; it is there to be watched failing."}, {"code": "    def log_message(self, fmt, *args):\n        print(f\"{HOST} {fmt % args}\", flush=True)\n\n", "note": "Logs go to standard output, one line per request, and nowhere else (XI). Collecting and keeping them is the platform's job."}, {"code": "def serve():\n    server = ThreadingHTTPServer((\"\", PORT), Handler)\n    server.daemon_threads = False\n\n    def stop(signum, frame):\n        print(f\"{HOST} SIGTERM: finishing requests in progress, then exiting\", flush=True)\n        threading.Thread(target=server.shutdown).start()\n\n    signal.signal(signal.SIGTERM, stop)\n    print(f\"{HOST} catalogue listening on :{PORT}\", flush=True)\n    server.serve_forever()\n    server.server_close()\n    print(f\"{HOST} stopped\", flush=True)\n\n\nif __name__ == \"__main__\":\n    migrate() if sys.argv[1:] == [\"migrate\"] else serve()", "note": "Disposability (IX): on SIGTERM the server stops taking new requests, lets the ones in progress finish, and the process exits. Without the handler, Python running as the container's first process would ignore SIGTERM, and Docker would wait ten seconds and kill it."}]}
```

`requirements.txt`:

```schooling-example
{"language": "sh", "file": "requirements.txt", "parts": [{"code": "psycopg[binary]==3.3.6", "note": "Dependencies declared, with exact versions (II). The image installs this list and nothing else, so two builds a month apart get the same library."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nWORKDIR /app\nCOPY requirements.txt .\nRUN pip install --no-cache-dir -r requirements.txt\nCOPY catalogue.py .\nCMD [\"python\", \"catalogue.py\"]", "note": "Build (V): the dependencies first, so that a change to the code reuses the layer with them, then the code. The image that comes out is the same in every environment."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  catalogue:\n    build: .\n    image: quitanda/catalogue:${TAG:-dev}\n    environment:\n      DATABASE_URL: ${DATABASE_URL:-postgresql://quitanda:quitanda@db:5432/quitanda}\n      PORT: \"8000\"\n    ports:\n      - \"127.0.0.1:8000-8002:8000\"\n    depends_on:\n      db:\n        condition: service_healthy", "note": "The release (V) is this image plus this configuration. The database is a backing service (IV), named only by a URL; `${DATABASE_URL:-…}` takes the URL from the shell's environment when one is set there, and the image's tag comes from TAG the same way."}, {"code": "  db:\n    image: postgres:17\n    environment:\n      POSTGRES_USER: quitanda\n      POSTGRES_PASSWORD: quitanda\n    healthcheck:\n      test: [\"CMD\", \"pg_isready\", \"-U\", \"quitanda\"]\n      interval: 2s\n      retries: 15", "note": "The same Postgres major version as production (X), with a health check, so that the catalogue starts only when the database accepts connections."}]}
```

## I, codebase: one directory, many deploys

Everything above is one codebase. In a real project it is one repository, and **the same commit is
deployed everywhere**: on your laptop, in staging, in production. Two programs sharing one repository
is a monorepo, which is fine; one program whose production copy lives in a different repository from
its development copy is not, because the two drift apart and nobody can say which one is running.

## II, dependencies: declared and isolated

`catalogue.py` imports `psycopg`, and `requirements.txt` says exactly which version. The image installs
that list and nothing else, so the program never relies on something that happens to be on a machine.
Build it, run the admin task that creates the table, and start the service:

```
ana@vm:~/lab/twelve$ docker compose build --quiet
 Image quitanda/catalogue:dev Building 
 Image quitanda/catalogue:dev Built 
ana@vm:~/lab/twelve$ docker compose run --rm catalogue python catalogue.py migrate
 Network twelve_default Creating 
 Network twelve_default Creating 
 Network twelve_default Created 
 Network twelve_default Created 
 Container twelve-db-1 Creating 
 Container twelve-db-1 Created 
 Container twelve-db-1 Starting 
 Container twelve-db-1 Started 
 Container twelve-db-1 Waiting 
 Container twelve-db-1 Healthy 
 Container twelve-catalogue-run-d2ea61a78579 Creating 
 Container twelve-catalogue-run-d2ea61a78579 Created 
migrated: 5 products
ana@vm:~/lab/twelve$ docker compose up -d
 Container twelve-db-1 Running 
 Container twelve-catalogue-1 Creating 
 Container twelve-catalogue-1 Created 
 Container twelve-db-1 Waiting 
 Container twelve-db-1 Healthy 
 Container twelve-catalogue-1 Starting 
 Container twelve-catalogue-1 Started 
```

Inside the container, the installed packages are the declared one and what it depends on:

```
ana@vm:~/lab/twelve$ docker compose exec catalogue pip freeze
psycopg==3.3.6
psycopg-binary==3.3.6
typing_extensions==4.16.0
```

**`psycopg-binary` and `typing_extensions` were never written down by you**; `psycopg[binary]` pulled
them in. Pinning only the top level leaves those free to change between two builds. Tools such as
`pip-compile`, Poetry's lock file, `package-lock.json` in Node or `go.sum` in Go write down the whole
tree, and a build from the lock file gets the same versions every time.

And the service answers, from its database:

```
ana@vm:~/lab/twelve$ curl -s localhost:8000/products
{"served_by": "144d3a898221", "products": {"banana": 649, "bread": 990, "cheese": 2450, "coffee": 3290, "tomato": 899}}
```

`served_by` is the container's hostname, which Docker sets to the start of its id. It matters in the
section on processes, where there are three of them.
