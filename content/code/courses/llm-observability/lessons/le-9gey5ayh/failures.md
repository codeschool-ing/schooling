---
title: Failures, and the retries that hide them
version: 2
---

A provider refuses requests. It is overloaded (503, or Anthropic's 529), it is rate limiting this key
(429), or something on its side broke (500). Most of these clear up in a second, which is why every SDK
retries them, and why a failure to the provider is usually not a failure to the customer. The
question for monitoring is whether anybody can still see it.

Ollama on your own computer does none of that unless something is badly wrong, and a lesson cannot
wait for a provider's bad afternoon. So `flaky.py` stands between the assistant and Ollama and fails
on purpose, when told to. It is a small proxy, written with nothing but Python's standard library:
every request it receives it forwards to Ollama and hands back the answer, unless it has been told to
refuse it or to cut its stream short. Save it in `~/obs`:

```python
"""flaky.py: a proxy in front of Ollama that fails on purpose, for lesson 4.

    python flaky.py                      # listens on 127.0.0.1:11435, forwards to 127.0.0.1:11434
    curl -s -X POST 127.0.0.1:11435/flaky -d '{"fail_rate": 0.3}'

A real provider refuses requests and drops streams on days nobody chooses.
This one does it when told to, so the assistant's retries can be watched.
Only requests for a chat completion are touched; embeddings go straight through.
POST /flaky sets any of: fail_rate (share of chat requests refused at random),
fail (refuse the next N), status (what a refusal answers, 503 by default),
cut_after (end the next stream after N pieces, without a finish), seed.
Every request it forwards or refuses is one line in flaky.log.
"""
import json
import random
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

UPSTREAM = "http://127.0.0.1:11434"
config = {"fail_rate": 0.0, "fail": 0, "status": 503, "cut_after": None, "seed": 7}
rng = random.Random(config["seed"])
count = 0


class Proxy(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def log(self, status):
        with open("flaky.log", "a") as f:
            f.write(json.dumps({"n": count, "path": self.path, "status": status}) + "\n")

    def answer(self, status, body):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_POST(self):
        global count, rng
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        if self.path == "/flaky":
            config.update(json.loads(body or b"{}"))
            rng = random.Random(config["seed"])
            return self.answer(200, config)
        count += 1
        chat = self.path.endswith("/chat/completions")
        if chat and (config["fail"] > 0 or rng.random() < config["fail_rate"]):
            config["fail"] = max(0, config["fail"] - 1)
            self.log(config["status"])
            return self.answer(config["status"], {"error": {
                "message": "flaky.py refused this request on purpose", "type": "overloaded_error"}})
        request = urllib.request.Request(UPSTREAM + self.path, body, {"Content-Type": "application/json"})
        try:
            upstream = urllib.request.urlopen(request)
        except urllib.error.HTTPError as e:
            self.log(e.code)
            return self.answer(e.code, json.loads(e.read() or b"{}"))
        self.log(upstream.status)
        self.send_response(upstream.status)
        self.send_header("Content-Type", upstream.headers["Content-Type"])
        self.send_header("Connection", "close")
        self.end_headers()
        cut, pieces = config["cut_after"], 0
        for line in upstream:
            if cut is not None and line.startswith(b"data: {"):
                pieces += 1
                if pieces > cut:
                    config["cut_after"] = None
                    break
            self.wfile.write(line)
            self.wfile.flush()
        self.close_connection = True


ThreadingHTTPServer(("127.0.0.1", 11435), Proxy).serve_forever()
```

Start it in a second terminal, with the environment active, and leave it running:

```sh
python flaky.py
```

Back in the first terminal, point the SDK at it rather than at Ollama, and tell it to refuse three
chat requests in ten, at random. `ten.py` then asks ten of the week's questions, one line each:

```python
"""ten.py: ten questions through the assistant, one line each."""
import json

import assistant
import telemetry

telemetry.setup()
for q in [x["phrasings"][0] for x in json.load(open("data/topics.json"))[:10]]:
    try:
        reply, _, trace = assistant.ask(q)
        print(f"{trace[:8]}  ok      {reply[:60]}")
    except Exception as e:
        print(f"{'':8}  FAILED  {type(e).__name__}: {e}")
```

CAPTURE:failures[0:15]

Ten questions, ten answers. Nothing the customer saw failed. `errors.py` reads the spans:

```python
"""errors.py: the model attempts in spans.jsonl, and what became of the requests that made them."""
import json
from collections import Counter

spans = [json.loads(line) for line in open("spans.jsonl")]
chats = [s for s in spans if s["name"].startswith("chat ")]
asks = [s for s in spans if s["name"] == "ask"]
gens = [s for s in spans if s["name"] == "generate"]
print(f"attempts {len(chats)}, failed {sum(s['status'] == 'ERROR' for s in chats)}")
print("requests by attempts needed:", dict(sorted(Counter(s["attributes"]["app.attempts"] for s in gens).items())))
print(f"requests {len(asks)}, failed {sum(s['status'] == 'ERROR' for s in asks)}")
```

```
ana@lab:~/obs$ python errors.py
attempts 10, failed 2
requests by attempts needed: {1: 6, 2: 2}
requests 10, failed 0
```

**Two of the ten attempts failed, and none of the ten requests did.** Six requests needed one attempt,
two needed two, and two refused before any model call. One of the retried traces:

```
ana@lab:~/obs$ python tree.py 6baa11fa
trace 6baa11fae7dec0ff4b543047a8106bf2   start(ms) took(ms)
      0   1,185 ms  ask
      0      47 ms    embed
     48       3 ms    search
     51   1,134 ms    generate
     51      48 ms      chat extract-1  ERROR InternalServerError: Error code: 503 - {'error': {'message': 'The server is overloaded', 'type': 'overloaded_error', 'code': None}}
    599     585 ms      chat extract-1
  1,185       0 ms    check_citations
ana@lab:~/obs$ python tree.py --attrs 6baa11fa | grep -E "ERROR|attempts"
                       app.attempts = 2
     51      48 ms      chat extract-1  ERROR InternalServerError: Error code: 503 - {'error': {'message': 'The server is overloaded', 'type': 'overloaded_error', 'code': None}}
```

The first attempt was refused with a 503 in 48 ms. The assistant waited half a second, its first
backoff, and asked again; the second attempt answered. The request took 1,185 ms, half a second of it
spent waiting to retry, and the customer saw only a slower answer.

## Two error rates

The week needs both, and they mean different things:

- **The attempt error rate**, failed model calls over all model calls: 2 in 10 here. It is the
  provider's health. When it rises, the provider is having a bad day, and the retries are absorbing it.
- **The request error rate**, requests that reached the customer as an error: 0 in 10. It is the
  customer's experience. When it rises, the retries have run out.

An alert on the second alone fires only when it is already too late. An alert on the first alone
fires on every provider hiccup that the retries absorbed and nobody noticed. **A rising attempt
error rate with a flat request error rate is a warning; both rising is an incident.** Lesson 16 turns
that into rules.

## A retry the trace cannot see

The assistant retries in its own code so that each attempt is a span. Most code leaves it to the SDK,
whose default is two retries. `sdk_retry.py` makes one call that way, with a span around it, while
labobs refuses the next two requests:

```python
"""sdk_retry.py: the SDK retrying inside one span, where the trace cannot see it."""
from openai import OpenAI

import telemetry

telemetry.setup()
client = OpenAI(max_retries=2)
with telemetry.span("chat llama3.2:3b", **{"gen_ai.request.model": "llama3.2:3b"}):
    client.chat.completions.create(model="llama3.2:3b", messages=[{"role": "user", "content": "How long is a gift card valid?"}])
```

```
ana@lab:~/obs$ rm -f spans.jsonl; python sdk_retry.py; python tree.py
trace d1ed988996915d550df75b7bf41c8866   start(ms) took(ms)
      0   1,835 ms  chat extract-1
ana@lab:~/obs$ tail -3 /var/log/labgen/requests.jsonl | python -c "import json, sys; [print(json.loads(l)[\"n\"], json.loads(l)[\"status\"]) for l in sys.stdin]"
2362 503
2363 503
2364 200
```

The trace shows **one span of 1,835 ms, and no error**. labobs' log shows what happened: requests
2362 and 2363 were refused with 503, and 2364 answered. The SDK waited, retried twice, and returned
success, and from inside the application none of that is visible. The span is not wrong, the call did
succeed, but a week of these would show a provider getting slower when it was in fact failing a third
of the time.

Two ways out. Retry in your own code, as `assistant.py` does, with `max_retries=0` on the client. Or
keep the SDK's retries and instrument underneath them: an HTTP-level instrumentation sees each request
the SDK sends, retries included, as a span of its own. Either way, **the provider's failures have to be
counted somewhere, or the first sign of them will be a customer**.
