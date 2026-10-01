---
title: The smallest receiver
version: 1
---

A receiver is a web server with one handler, and Python's standard library has one:

```schooling-example
{
  "language": "python",
  "file": "hook_print.py",
  "parts": [
    {
      "code": "import json\nfrom http.server import BaseHTTPRequestHandler, HTTPServer\n\n\nclass Hook(BaseHTTPRequestHandler):\n    def do_POST(self):\n        body = self.rfile.read(int(self.headers[\"Content-Length\"]))\n        print(\"headers:\", {k: v for k, v in self.headers.items() if k.startswith(\"X-Devapi\")})\n        print(\"body:   \", json.loads(body))",
      "note": "**A webhook receiver is a small web server.** It listens, and each event arrives as an HTTP POST with a JSON body. The standard library is enough."
    },
    {
      "code": "        self.send_response(204)\n        self.end_headers()\n\n    def log_message(self, *args):\n        pass\n\n",
      "note": "**Answer quickly, and answer 2xx.** The sender only needs to know the event arrived; whatever the receiver does with it comes after."
    },
    {
      "code": "HTTPServer((\"192.0.2.10\", 8080), Hook).handle_request()",
      "note": "**One request, then stop**, so the transcript ends; a real receiver runs `serve_forever()`."
    }
  ]
}
```

The router needs to know where to send, so the first step is a subscription, created through the
same API client lesson 2 wrote. The events are the two the router offers, a link going down and
coming up:

```schooling-example
{
  "language": "python",
  "file": "subscribe.py",
  "parts": [
    {
      "code": "import sys\nfrom pathlib import Path\n\nfrom devapi import Device\n"
    },
    {
      "code": "secret = Path(\"~/.hook-secret\").expanduser().read_text().strip()\nedge1 = Device(\"edge1\")\nhook = edge1.request(\"POST\", \"/webhooks\", json={\n    \"url\": \"http://192.0.2.10:8080/hook\",\n    \"events\": [\"interface.down\", \"interface.up\"],\n    \"secret\": secret})\nprint(hook)",
      "note": "**The secret is shared by the two ends and never travels with an event.** The router uses it to sign each delivery; the receiver uses it to check the signature."
    }
  ]
}
```

```
ana@ctl:~$ python subscribe.py
{'id': 'wh-b26d9c7e', 'url': 'http://192.0.2.10:8080/hook', 'events': ['interface.down', 'interface.up']}
```

The router answered with the subscription's id, and **it did not repeat the secret**: a secret
that an API echoes back is one that ends up in logs. Now the receiver runs in one terminal, and in
another a small script takes `edge1`'s `eth2` down through the router's API, the way a change or a
failure would:

```schooling-example
{
  "language": "python",
  "file": "link.py",
  "parts": [
    {
      "code": "import sys\n\nfrom devapi import Device\n"
    },
    {
      "code": "router, interface, state = sys.argv[1:4]\nDevice(router).request(\"PATCH\", f\"/interfaces/{interface}\", json={\"enabled\": state == \"up\"})\nprint(f\"{router} {interface}: {state}\")",
      "note": "**Take a link down or bring it up through the router's API**, the way an operator's change or a failure would. `python link.py edge1 eth2 down`."
    }
  ]
}
```

```
ana@ctl:~$ python link.py edge1 eth2 down
edge1 eth2: down
```

What the receiver printed:

```
ana@ctl:~$ python hook_print.py
headers: {'X-Devapi-Event': 'interface.down', 'X-Devapi-Delivery': 'edge1-1790682864-1', 'X-Devapi-Signature': 'sha256=314b71b4150b6625b24404cfa0b6636478fcdc35db7f1971375f1f582605c750'}
body:    {'id': 'edge1-1790682864-1', 'event': 'interface.down', 'device': 'edge1', 'interface': 'eth2', 'description': 'branch LAN', 'time': '2026-09-29T08:54:45-03:00'}
```

**The event is a small JSON document**: what happened, on which device and interface, the
interface's description, and when. Its `id` is repeated in a header, `X-Devapi-Delivery`, next to
the name of the event and a **signature**. Each of the three headers has a job, and the next three
sections are one each.

The receiver answered `204 No Content` and stopped, because it handles one request and exits; a
real one runs `serve_forever()`. **Answering fast matters more than it looks.** The sender waits for
the answer, and a receiver that does its work before answering, calling a ticketing system that
takes eight seconds, makes the sender think it failed.
