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

```
ana@dev:~/obs$ export OPENAI_BASE_URL=http://127.0.0.1:11435/v1
ana@dev:~/obs$ curl -s -X POST 127.0.0.1:11435/flaky -d '{"fail_rate": 0.3}'; echo
{"fail_rate": 0.3, "fail": 0, "status": 503, "cut_after": null, "seed": 7}
ana@dev:~/obs$ rm -f spans.jsonl; python ten.py
4b9557ba  ok      You have 30 days from the date of delivery to return a print
81c6bd42  ok      According to source [1], express delivery costs R$ 29.90.
a13fa2e0  ok      According to [1], we refund within three working days of the
e5f2bca5  ok      According to [1], standard delivery is free on orders over R
42a9eacc  ok      You can read your e-books on up to six devices at the same t
b60268f5  ok      According to [1], a gift card is valid for two years from th
6219b0fe  ok      I could not find that in our documents.
1f352d57  ok      I could not find that in our documents.
d6617692  ok      According to [1], a standard parcel is considered lost when 
11aa7cdf  ok      According to [1], the customer pays for the return postage.
```

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
ana@dev:~/obs$ python errors.py
attempts 17, failed 8
requests by attempts needed: {1: 3, 2: 4, 3: 2}
requests 10, failed 0
```

**Eight of the seventeen attempts failed, and none of the ten requests did.** Three requests needed
one attempt, four needed two, two needed three, and one was refused by the search before any model
call. One of the retried traces:

```
ana@dev:~/obs$ python tree.py 81c6bd42
trace 81c6bd425c703c9d91087c4a37d4f72e   start(ms) took(ms)
      0   3,807 ms  ask
      0     175 ms    embed
    175       0 ms    search
    175   3,631 ms    generate
    175       9 ms      chat llama3.2:3b  ERROR InternalServerError: Error code: 503 - {'error': {'message': 'flaky.py refused this request on purpose', 'type': 'overloaded_error'}}
    685   3,121 ms      chat llama3.2:3b
  3,807       0 ms    check_citations
ana@dev:~/obs$ python tree.py --attrs 81c6bd42 | grep -E "ERROR|attempts"
                       app.attempts = 2
    175       9 ms      chat llama3.2:3b  ERROR InternalServerError: Error code: 503 - {'error': {'message': 'flaky.py refused this request on purpose', 'type': 'overloaded_error'}}
```

The first attempt was refused with a 503 in 9 ms. The assistant waited half a second, its first
backoff, and asked again; the second attempt answered. The request took 3,807 ms, half a second of
it spent waiting to retry, and the customer saw only a slower answer.

## Two error rates

The week needs both, and they mean different things:

- **The attempt error rate**, failed model calls over all model calls: 8 in 17 here, more than the
three in ten flaky.py was asked for, as a small sample drawn at random often is. It is the
provider's health. When it rises, the provider is having a bad day, and the retries are absorbing
it.

An alert on the second alone fires only when it is already too late. An alert on the first alone
fires on every provider hiccup that the retries absorbed and nobody noticed. **A rising attempt
error rate with a flat request error rate is a warning; both rising is an incident.** Lesson 16
builds rules of this kind for refusals, and the same shape fits here.

## A retry the trace cannot see

The assistant retries in its own code so that each attempt is a span. Most code leaves it to the
SDK, whose default is two retries. `sdk_retry.py` makes one call that way, with a span around it,
while flaky.py refuses the next two requests:

```python
"""sdk_retry.py: the SDK retrying inside one span, where the trace cannot see it."""
from openai import OpenAI

import telemetry

telemetry.setup()
client = OpenAI(max_retries=2)
with telemetry.span("chat llama3.2:3b", **{"gen_ai.request.model": "llama3.2:3b"}):
    client.chat.completions.create(model="llama3.2:3b", temperature=0, max_tokens=60,
                                   messages=[{"role": "user", "content": "How long is a gift card valid?"}])
```

```
ana@dev:~/obs$ rm -f spans.jsonl; python sdk_retry.py; python tree.py
trace d0a37dc5e36ef0ffd41382477b17df5a   start(ms) took(ms)
      0   8,096 ms  chat llama3.2:3b
ana@dev:~/obs$ tail -3 flaky.log
{"n": 28, "path": "/v1/chat/completions", "status": 503}
{"n": 29, "path": "/v1/chat/completions", "status": 503}
{"n": 30, "path": "/v1/chat/completions", "status": 200}
```

The trace shows **one span of 8,096 ms, and no error**. flaky.py's log shows what happened: requests
28 and 29 were refused with 503, and 30 answered. The SDK waited, retried twice, and returned
success, and from inside the application none of that is visible. The span is not wrong, the call
did succeed, but a week of these would show a provider getting slower when it was in fact failing a
third of the time.

Two ways out. Retry in your own code, as `assistant.py` does, with `max_retries=0` on the client. Or
keep the SDK's retries and instrument underneath them: an HTTP-level instrumentation sees each request
the SDK sends, retries included, as a span of its own. Either way, **the provider's failures have to be
counted somewhere, or the first sign of them will be a customer**.
