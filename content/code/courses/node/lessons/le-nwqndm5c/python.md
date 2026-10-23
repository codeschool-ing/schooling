---
title: Python
version: 1
---

**Python is the language most people meet first, and on servers it is where data, scripting and
machine learning meet the web.** Ubuntu ships it, because parts of the system are written in it:

```sh
python3 --version                 # Ubuntu and WSL: already there
brew install python               # a Mac, with Homebrew (not run for this course)
```

```
ana@dev:~/server/other/python$ python3 --version
Python 3.12.3
```

The server, with nothing but the standard library:

```schooling-example
{"language": "python", "file": "hello.py", "parts": [
 {"code": "# hello.py: the same server in Python, with nothing but the standard library.\nimport json\nimport os\nimport time\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\nfrom urllib.parse import parse_qs, urlparse", "note": "**Imports name what they take**, like `import { … } from` in a module. `http.server` is Python's equivalent of `node:http`."},
 {"code": "class Handler(BaseHTTPRequestHandler):\n    def send(self, status, body):\n        data = json.dumps(body).encode()\n        self.send_response(status)\n        self.send_header(\"content-type\", \"application/json\")\n        self.send_header(\"content-length\", str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)", "note": "**A class with a method per HTTP verb.** The server calls `do_GET` for each GET, on an object made for that request. Indentation is the syntax: there are no braces, and a block is whatever is indented under its line."},
 {"code": "    def do_GET(self):\n        url = urlparse(self.path)\n        if url.path == \"/hello\":\n            name = parse_qs(url.query).get(\"name\", [\"world\"])[0]\n            return self.send(200, {\"hello\": name})\n        if url.path == \"/slow\":\n            time.sleep(1)\n            return self.send(200, {\"slept\": 1000})\n        self.send(404, {\"error\": f\"nothing at {url.path}\"})", "note": "**`time.sleep(1)` blocks**, which in Node would stop every request. Here it stops only this one, because each request has a thread of its own: `ThreadingHTTPServer`, below."},
 {"code": "port = int(os.environ.get(\"PORT\", \"3000\"))\nprint(f\"python on :{port}\", flush=True)\nThreadingHTTPServer((\"127.0.0.1\", port), Handler).serve_forever()", "note": "`os.environ` is `process.env`, and an `f\"…\"` string is a template literal."}
]}
```

```
ana@dev:~/server/other/python$ python3 hello.py
python on :3000
127.0.0.1 - - [22/Oct/2026 20:11:16] "GET /hello?name=ana HTTP/1.1" 200 -
127.0.0.1 - - [22/Oct/2026 20:11:16] "GET /nope HTTP/1.1" 404 -
127.0.0.1 - - [22/Oct/2026 20:11:17] "GET /slow HTTP/1.1" 200 -
127.0.0.1 - - [22/Oct/2026 20:11:17] "GET /slow HTTP/1.1" 200 -
127.0.0.1 - - [22/Oct/2026 20:11:17] "GET /slow HTTP/1.1" 200 -
127.0.0.1 - - [22/Oct/2026 20:11:17] "GET /slow HTTP/1.1" 200 -
127.0.0.1 - - [22/Oct/2026 20:11:17] "GET /slow HTTP/1.1" 200 -
127.0.0.1 - - [22/Oct/2026 20:11:17] "GET /slow HTTP/1.1" 200 -
127.0.0.1 - - [22/Oct/2026 20:11:17] "GET /slow HTTP/1.1" 200 -
127.0.0.1 - - [22/Oct/2026 20:11:17] "GET /slow HTTP/1.1" 200 -
127.0.0.1 - - [22/Oct/2026 20:11:17] "GET /slow HTTP/1.1" 200 -
127.0.0.1 - - [22/Oct/2026 20:11:17] "GET /slow HTTP/1.1" 200 -
^C
```

```
ana@dev:~/server/other/python$ curl -s 'http://127.0.0.1:3000/hello?name=ana'
{"hello": "ana"}
ana@dev:~/server/other/python$ curl -s -w ' %{http_code}\n' http://127.0.0.1:3000/nope
{"error": "nothing at /nope"} 404
ana@dev:~/server/other/python$ time (for i in $(seq 10); do curl -s -o /dev/null -w '%{http_code} ' http://127.0.0.1:3000/slow & done; wait)
200 200 200 200 200 200 200 200 200 200 
real	0m1.015s
user	0m0.030s
sys	0m0.020s
```

**The same answers, one difference in the bytes**: Python's `json.dumps` puts a space after each colon,
which a JSON reader ignores and a test comparing strings would not. And the server writes a log line
per request on its own, in the first terminal.

**Ten slow requests took one second** because each one got its own thread, which is the opposite way
round from Node: Python blocks and runs many threads, Node does not block and runs one. The section on
concurrency models measures what that costs when the work is computation instead of waiting.

## What a real Python service uses

Python's own documentation says `http.server` is not for production, and nobody uses it there. The
usual choices:

| what | in Node terms |
|---|---|
| **FastAPI**, or **Flask**, for an API | Express |
| **Django**, a framework with a database layer, an admin and templates included | no single equivalent |
| `uvicorn` or `gunicorn`, the server that runs the application | `node server.js` |
| `pip`, and a **virtual environment** (`python3 -m venv .venv`) per project | `npm`, and `node_modules/` |
| `requirements.txt` or `pyproject.toml` | `package.json` |

A virtual environment is the part Node does not need. `npm` installs into the project by default, and
`pip` installs into the whole system unless a `venv` is active, which is why Ubuntu now refuses a
plain `pip install` outside one.
