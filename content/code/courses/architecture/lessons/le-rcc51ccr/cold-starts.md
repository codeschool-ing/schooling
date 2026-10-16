---
title: Cold starts, measured
version: 1
---

A **cold start** is the time a platform spends getting your code ready before it can run it: finding
a machine, starting an isolated environment, starting the language runtime, and loading your code
and its libraries. A **warm** call lands on a copy that is already running and pays for the handler
alone.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two timelines for one event. The cold path has four segments: the platform finds a machine, starts a container, starts the runtime and loads the code, and only then runs the handler for a few milliseconds. The warm path has only the handler segment, because an instance is already running.\"><defs><marker id=\"l3-cold-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">cold</text><rect x=\"90\" y=\"50\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"155.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">find a machine</text><rect x=\"220\" y=\"50\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">start container</text><rect x=\"360\" y=\"50\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"440.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">start runtime, load code</text><rect x=\"520\" y=\"50\" width=\"70\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">handler</text><text x=\"26\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">warm</text><rect x=\"520\" y=\"114\" width=\"70\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"555\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">handler</text><path d=\"M90 186 L680 186\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3-cold-ah-wire)\"></path><text x=\"385\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">time, from the event's arrival</text></svg>", "caption": "A cold start pays for everything before the handler; a warm instance pays only for the handler. The first caller after an idle period waits for all of it."}
```

Your lab is not a function platform, but it does the same two things a platform does, and they can
be timed. `runner.py` wraps the handler from the previous section in the two ways a platform runs it:

```schooling-example
{"language": "python", "file": "runner.py", "parts": [{"code": "import json, sys\nfrom http.server import BaseHTTPRequestHandler, HTTPServer\nfrom handler import handle\n\nif sys.argv[1] == \"once\":\n    print(json.dumps(handle(json.loads(sys.argv[2]))))\nelse:\n    class Warm(BaseHTTPRequestHandler):\n        def do_POST(self):\n            event = json.loads(self.rfile.read(int(self.headers[\"Content-Length\"])))\n            body = (json.dumps(handle(event)) + \"\\n\").encode()\n            self.send_response(200)\n            self.send_header(\"Content-Length\", str(len(body)))\n            self.end_headers()\n            self.wfile.write(body)\n\n        def log_message(self, *args):\n            pass\n\n    HTTPServer((\"\", 8080), Warm).serve_forever()", "note": "What a platform does around the handler, in miniature. `once` is a cold start: a fresh process loads the handler, answers one event and exits. `serve` is a warm instance: the process stays up and answers event after event over HTTP."}]}
```

## Cold: a new container for one event

`docker run --rm` creates a container from `python:3.12-slim`, mounts the current directory at
`/fn` with `-v ./:/fn`, starts the interpreter, loads `runner.py` and `handler.py` from there,
answers one event and removes the container.
`time` measures all of it:

```
ana@vm:~/lab/faas$ time docker run --rm -v ./:/fn -w /fn python:3.12-slim python runner.py once '{"weight_g": 7400}'
{"weight_g": 7400, "fee_cents": 1240}

real	0m0.741s
user	0m0.030s
sys	0m0.020s
```

## Warm: one container, many events

`docker run -d` starts the same container and leaves it running, listening on port 8080. Each event
is then an HTTP request to a process that is already up, and `curl` reports how long each took:

```
ana@vm:~/lab/faas$ docker run -d --name warm -v ./:/fn -w /fn -p 127.0.0.1:8080:8080 python:3.12-slim python runner.py serve
85bafaa4db3d20e78241ea5dbb65f1a9c3bed2ae3dea12c8167ed6ce58e1ab0d
ana@vm:~/lab/faas$ curl -s -w '%{time_total}s\n' -d '{"weight_g": 7400}' localhost:8080
{"weight_g": 7400, "fee_cents": 1240}
0.002559s
ana@vm:~/lab/faas$ curl -s -w '%{time_total}s\n' -d '{"weight_g": 7400}' localhost:8080
{"weight_g": 7400, "fee_cents": 1240}
0.004560s
ana@vm:~/lab/faas$ curl -s -w '%{time_total}s\n' -d '{"weight_g": 7400}' localhost:8080
{"weight_g": 7400, "fee_cents": 1240}
0.003327s
```

The cold call took 0.741 seconds on this machine; each warm call took between two and five
milliseconds.
**The handler is the same few lines in both cases**, and nearly all of the cold call is everything
before it. On a real platform the numbers differ, and the providers work hard to make them small, but
the shape does not: the first caller after an idle period pays for the environment, and the ones
after it do not.

Stop the warm instance:

```
ana@vm:~/lab/faas$ docker rm -f warm
warm
```

## What makes a cold start longer

| factor | why |
| --- | --- |
| the runtime | an interpreter such as Python or Node starts faster than a JVM, which loads and compiles classes first |
| the size of the code and its libraries | everything imported at start-up is read from disk and initialised before the first event |
| work done at import time | opening database connections or reading configuration at the top of the file runs on every cold start |
| memory requested | on several platforms the CPU share grows with the memory, so a small function starts on a small slice |

## What people do about it

**Keep the start-up small**: fewer libraries, nothing slow at import time. **Keep copies warm**: most
platforms sell a minimum number of instances that never stop, AWS calls it provisioned concurrency,
and that is paying for an always-on server again, in smaller pieces. **Accept it** where nobody is
waiting, which is most of the glue in the table of triggers: an e-mail sent a second later than it
could have been costs nobody anything.

Leave `~/lab/faas` as it is; nothing in it is running now.
