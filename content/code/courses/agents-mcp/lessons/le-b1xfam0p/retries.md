---
title: When the provider fails
version: 2
---

Model APIs fail in ordinary ways: a rate limit (HTTP 429), an internal error (500), a server too busy to answer (Anthropic's 529, *overloaded*). Most of these pass in a second or two, and the right response is to wait and try again. **The question for an agent is who does the retrying**, because there are three candidates: the SDK, the adapter and the loop.

To watch who retries, put something in front of Ollama that fails on purpose. `flaky.py` answers the first N requests the way Anthropic's API answers when it is overloaded, with a 529 and the same error body, and passes every later request on to Ollama. It prints each status it sends. Save it as `~/agents/flaky.py`:

```python
"""flaky.py N: answer the first N requests on port 11437 with 529 Overloaded, then pass the rest on to Ollama."""
import http.client
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

left = int(sys.argv[1])


class Flaky(BaseHTTPRequestHandler):
    def do_POST(self):
        global left
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        if left > 0:
            left -= 1
            status = 529
            data = json.dumps({"type": "error", "error": {"type": "overloaded_error", "message": "Overloaded"}}).encode()
        else:
            upstream = http.client.HTTPConnection("127.0.0.1", 11434, timeout=900)
            upstream.request("POST", self.path, body, {"Content-Type": "application/json"})
            reply = upstream.getresponse()
            status, data = reply.status, reply.read()
        print(status, flush=True)
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *args):
        pass


ThreadingHTTPServer(("127.0.0.1", 11437), Flaky).serve_forever()
```

Run it once letting two requests fail, and once letting three:

```
ana@lab:~/agents$ python flaky.py 2 > flaky.log &
ana@lab:~/agents$ ANTHROPIC_BASE_URL=http://127.0.0.1:11437 python run.py "Can I return the copy of Dracula I bought in September? My order is M1047." | head -n 1
answered after 2 steps, 726 tokens
ana@lab:~/agents$ cat flaky.log
529
529
200
200
ana@lab:~/agents$ pkill -f "^python flaky.py"
ana@lab:~/agents$ python flaky.py 3 > flaky.log &
ana@lab:~/agents$ ANTHROPIC_BASE_URL=http://127.0.0.1:11437 python run.py "Can I return the copy of Dracula I bought in September? My order is M1047." 2>&1 | tail -n 1
anthropic.OverloadedError: Error code: 529 - {'type': 'error', 'error': {'type': 'overloaded_error', 'message': 'Overloaded'}}
ana@lab:~/agents$ cat flaky.log
529
529
529
```

With two failures, the run answered as if nothing had happened: `answered after 2 steps, 726 tokens`. `flaky.py`'s log shows what happened underneath: `529 529 200 200`, two refusals and then the run's two real requests. **The anthropic SDK retried twice, by itself, and told nobody.** Its default is `max_retries=2`, with an exponential backoff starting at half a second, and it retries 408, 409, 429 and every 5xx status. With three failures the retries ran out after three attempts, and the run ended with `anthropic.OverloadedError`, a 529.

## Decide which layer retries

**The SDK's retries are usually the right first layer**: they handle a short outage on one request, honour `retry-after` headers, and keep the loop simple. Know that they are there, and know their limits. Two retries with backoff cover a second or two of trouble, not a minute.

**The loop should not retry a request blindly on top of the SDK.** Two layers of three attempts each are nine requests, and an outage long enough to exhaust the SDK's retries is long enough that a customer is better served by a stopped outcome than by a run that hangs. `minagent` passes `max_retries` to the SDK and leaves the exception to propagate, which is lesson 4's rule: an outage is not something the model can fix, so it is not a tool result.

**Where a retry at the run level makes sense, it should be idempotent.** Retrying a whole run after a crash replays every tool call, which is harmless for reads and dangerous for writes, and is exactly what lesson 4's idempotency keys exist for.

**Rate limits deserve their own handling.** A 429 says you are sending too fast, and retrying faster makes it worse. In a system running many agents, the fix is a limit on concurrent runs or requests per minute, enforced before the request is sent, rather than a retry after it fails.
