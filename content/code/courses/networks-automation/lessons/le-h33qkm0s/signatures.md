---
title: Checking who sent it
version: 1
---

The receiver listens on a port anyone on the network can reach, and anyone can POST JSON to it.
**Without a check, a forged "link down" opens a ticket, and a forged "link up" closes one.** The
subscription's secret is what stops that: the router computes an HMAC of the exact bytes of the
body with the secret, and sends it in `X-Devapi-Signature`. Nobody without the secret can compute
it, and any change to the body changes it.

The receiver the rest of the lesson uses checks it first, before reading anything in the body:

```schooling-example
{
  "language": "python",
  "file": "receiver.py",
  "parts": [
    {
      "code": "import hashlib\nimport hmac\nimport json\nimport sys\nfrom http.server import BaseHTTPRequestHandler, HTTPServer\nfrom pathlib import Path\n\nimport desk\n\nSECRET = Path(\"~/.hook-secret\").expanduser().read_text().strip().encode()\nSEEN = set()\nFAIL_ONCE = \"--fail-once\" in sys.argv\n\n",
      "note": "**The receiver the rest of the lesson builds on.** It checks every delivery's signature, ignores a delivery it has already handled, and turns events into tickets."
    },
    {
      "code": "def signed(body, header):\n    want = \"sha256=\" + hmac.new(SECRET, body, hashlib.sha256).hexdigest()\n    return hmac.compare_digest(want, header or \"\")\n\n\nclass Hook(BaseHTTPRequestHandler):\n    def do_POST(self):\n        body = self.rfile.read(int(self.headers[\"Content-Length\"]))\n        delivery = self.headers.get(\"X-Devapi-Delivery\")\n        if not signed(body, self.headers.get(\"X-Devapi-Signature\")):\n            print(f\"{delivery}: bad signature, refused\")\n            return self.answer(401)",
      "note": "**The signature is an HMAC of the exact bytes received**, computed with the shared secret. `compare_digest` compares in constant time, so the time it takes says nothing about how much of a forged signature was right."
    },
    {
      "code": "        if delivery in SEEN:\n            print(f\"{delivery}: already handled, ignored\")\n            return self.answer(204)\n        event = json.loads(body)\n        print(f\"{delivery}: {event['event']} {event['device']} {event['interface']}\")\n        print(\"  \", desk.handle(event))\n        SEEN.add(delivery)\n        if FAIL_ONCE and len(SEEN) == 1:\n            print(f\"{delivery}: answering 500 on purpose\")\n            return self.answer(500)\n        self.answer(204)\n\n    def answer(self, status):\n        self.send_response(status)\n        self.end_headers()\n\n    def log_message(self, *args):\n        pass\n\n\nserver = HTTPServer((\"192.0.2.10\", 8080), Hook)\nfor _ in range(int(sys.argv[1])):\n    server.handle_request()",
      "note": "**The delivery id makes a retry harmless.** A sender that did not hear back sends the same event again, with the same id, and the receiver has already acted on it."
    }
  ]
}
```

A forged request, with a made-up signature:

```
ana@ctl:~$ curl -s -o /dev/null -w "%{http_code}\n" -H "Content-Type: application/json" -H "X-Devapi-Delivery: forged-1" -H "X-Devapi-Signature: sha256=0000" -d '{"event": "interface.up", "device": "edge1", "interface": "eth1"}' http://192.0.2.10:8080/hook
401
```

```
ana@ctl:~$ python receiver.py 1
forged-1: bad signature, refused
```

`401`, and nothing else happened. Three details in `signed` are what make it a real check:

- **It signs the raw bytes**, as received, not the JSON after parsing. Parsing and re-serialising
  can change spacing or key order, and then a genuine signature would stop matching.
- **It uses `hmac.compare_digest`**, not `==`. An ordinary comparison stops at the first differing
  character, so its timing leaks how many characters of a guess were right.
- **The secret lives in a file only `ana` can read**, `~/.hook-secret`, and never in the code.

Many senders also put a timestamp in what they sign, so an old delivery captured on the wire cannot
be replayed tomorrow. The lab's router does not; the delivery id, in the next section, limits the
damage a replay can do.
