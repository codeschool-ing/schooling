---
title: Reranking, the thing Cohere is known for
version: 1
---

A **reranker** is a model with one job: given a question and a list of documents, put the documents
in order of how well they answer it. It writes nothing. It is the second stage of retrieval, the
fix lesson 1 section 11 named for missing facts: a fast search finds fifty passages that might be
relevant, and a reranker picks the five worth putting in the prompt. `embeddings-vectors` and `rag`,
the two courses after this one, build that pipeline; this section is about what the model is and
how it is sold.

The sheet prices Cohere's reranker in a different unit from every chat model so far:

```
ana@desk:~/desk$ python sheet.py show rerank-v4.0-pro | grep -E "^(input_cost_per_query|max_input|mode|source)"
input_cost_per_query                       0.0025
max_input_tokens                           32768
mode                                       rerank
source                                     https://cohere.com/pricing
```

**$0.0025 per query**, not per token: a search is billed as one unit, whatever the number of
documents. Its window, 32,768 tokens, bounds how much text one query can rank.

## What a rerank request looks like

Cohere's own SDK, `cohere`, is the client, and it brings a problem with it. It pins an older version
of a library that lesson 19 needs, and installing it in the desk's environment replaces that library
without asking:

```
ana@desk:~/desk$ pip install -q cohere==7.2.0; pip list | grep -iE "^(cohere|huggingface)"
cohere                             7.2.0
huggingface_hub                    1.33.0
```

`huggingface_hub` was 2.1.1 when lesson 1 installed it and is 1.33.0 now, and nothing said so. **A
library that pins another can downgrade it silently**, and the program that breaks is a different
one, weeks later. The fix is an environment of its own for the library that pins, and the desk's
own one put back:

```
ana@desk:~/desk$ python3 -m venv .venv-cohere && .venv-cohere/bin/pip install -q cohere==7.2.0
ana@desk:~/desk$ rm -rf .venv && python3 -m venv .venv && .venv/bin/pip install -q openai==3.24.0 anthropic==1.11.0 ollama==0.6.3 google-genai==2.28.0 mistralai==3.0.0 huggingface_hub==2.1.1 && .venv/bin/pip list | grep -iE "^(cohere|huggingface)"
huggingface_hub                    2.1.1
```

Nothing on this computer is a reranker: Ollama has no rerank endpoint, and without a Cohere key
there is nobody to ask. What can be seen is the request, and for that this course has a small
program that lessons 14 to 21 use again. `relay.py` sits between a program and Ollama, passes every
request on, and writes each one down in `wire.jsonl`. Two switches make it misbehave on purpose,
for the lessons about errors and limits:

```python
"""relay.py: a door in front of Ollama that writes down every request.

    python relay.py                 listen on 127.0.0.1:8500 and pass every request on to Ollama
    python relay.py --fail 529:2    answer the next two requests with 529 instead (lesson 17)
    python relay.py --rpm 3         allow three requests a minute, and 429 the rest (lesson 21)
    python relay.py show [--headers H,H] [--body] [--count N]
                                    print the last request, or a line for each of the last N

Each request is one line of wire.jsonl: the method, the path, the headers (keys
cut short), the body and the status it got. Standard library only.
"""
import argparse
import http.client
import http.server
import json
import time

LOG = "wire.jsonl"
OLLAMA = ("127.0.0.1", 11434)
SECRET = {"authorization", "x-api-key", "x-goog-api-key"}
SKIP = {"host", "content-length", "connection", "accept-encoding"}
DROP = {"transfer-encoding", "connection", "content-length", "date", "server"}  # set again below


class Relay(http.server.BaseHTTPRequestHandler):
    fail, fail_left, rpm, seen = 0, 0, 0, []

    def handle_one(self):
        body = self.rfile.read(int(self.headers.get("content-length") or 0))
        now, cls = time.time(), type(self)
        cls.seen = [t for t in cls.seen if now - t < 60]
        if cls.fail_left:
            cls.fail_left -= 1
            status, data, headers = cls.fail, b'{"type": "error", "error": {"type": "overloaded_error"}}', []
        elif cls.rpm and len(cls.seen) >= cls.rpm:
            wait = int(60 - (now - cls.seen[0])) + 1
            status, data, headers = 429, b'{"error": "rate limited"}', [("retry-after", str(wait))]
        else:
            cls.seen.append(now)
            up = http.client.HTTPConnection(*OLLAMA, timeout=600)
            sent = {k: v for k, v in self.headers.items() if k.lower() != "host"}
            up.request(self.command, self.path, body, sent)
            r = up.getresponse()
            status, data = r.status, r.read()
            headers = [(k, v) for k, v in r.getheaders() if k.lower() not in DROP]
        seen = {k.lower(): (v[:12] + "…" if k.lower() in SECRET else v) for k, v in self.headers.items()}
        with open(LOG, "a") as f:
            f.write(json.dumps({"method": self.command, "path": self.path, "headers": seen,
                                "request": json.loads(body) if body else None, "status": status}) + "\n")
        self.send_response(status)
        for k, v in headers:
            self.send_header(k, v)
        self.send_header("content-length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    do_GET = do_POST = do_DELETE = handle_one

    def log_message(self, *args):
        pass


def show(a):
    rows = [json.loads(line) for line in open(LOG)]
    if a.count:
        for r in rows[-a.count:]:
            print(f"{r['method']} {r['path']} -> {r['status']} {(r['request'] or {}).get('model', '')}")
        return
    r = rows[-1]
    if not a.body:
        print(f"{r['method']} {r['path']}")
        wanted = [h.strip().lower() for h in a.headers.split(",") if h.strip()]
        for k, v in r["headers"].items():
            if (k in wanted) if wanted else (k not in SKIP):
                print(f"{k}: {v}")
        print()
    print(json.dumps(r["request"], indent=2, ensure_ascii=False))


p = argparse.ArgumentParser(prog="relay.py")
p.add_argument("cmd", nargs="?", choices=["show"])
p.add_argument("--fail", default="")
p.add_argument("--rpm", type=int, default=0)
p.add_argument("--headers", default="")
p.add_argument("--body", action="store_true")
p.add_argument("--count", type=int, default=0)
a = p.parse_args()
if a.cmd == "show":
    show(a)
else:
    if a.fail:
        Relay.fail, Relay.fail_left = (int(x) for x in a.fail.split(":"))
    Relay.rpm = a.rpm
    print(f"relay on 127.0.0.1:8500, to Ollama on {OLLAMA[1]}, writing {LOG}", flush=True)
    http.server.ThreadingHTTPServer(("127.0.0.1", 8500), Relay).serve_forever()
```

Start it in a second terminal, in `~/desk`, and leave it running:

```
ana@desk:~/desk$ python relay.py
relay on 127.0.0.1:8500, to Ollama on 11434, writing wire.jsonl
```

`rerank.py` asks the question a customer's e-mail raises against four lines of the shop's policy,
sending it to the relay:

```python
import cohere

# no Cohere key, so the relay is the address: it writes the request down and passes it to Ollama
co = cohere.ClientV2(api_key="ollama", base_url="http://127.0.0.1:8500")
policies = [
    "Orders ship from our warehouse within two working days of payment.",
    "Refunds for damaged or misprinted books are paid to the original card within ten days.",
    "Gift vouchers are sent by e-mail on the date the buyer chooses.",
    "An address can be changed until the order leaves the warehouse.",
]
r = co.rerank(model="rerank-v4.0-pro", query="my book arrived damaged, I want my money back",
              documents=policies, top_n=2)
for hit in r.results:
    print(f"{hit.relevance_score:.4f}  {policies[hit.index]}")
```

```
ana@desk:~/desk$ .venv-cohere/bin/python rerank.py 2>&1 | tail -1
cohere.core.api_error.ApiError: headers: {'server': 'BaseHTTP/0.6 Python/3.13.16', 'date': 'Wed, 07 Oct 2026 17:00:51 GMT', 'content-type': 'text/plain', 'content-length': '18'}, status_code: 404, body: 404 page not found
```

The **404** is Ollama saying it has no such path; with a Cohere key and Cohere's address, the same
program prints two scored policies. The request is what the SDK sent, whoever answers it:

```
ana@desk:~/desk$ python relay.py show --headers user-agent,authorization
POST /v2/rerank
user-agent: cohere/7.2.0
authorization: Bearer ollam…

{
  "model": "rerank-v4.0-pro",
  "query": "my book arrived damaged, I want my money back",
  "documents": [
    "Orders ship from our warehouse within two working days of payment.",
    "Refunds for damaged or misprinted books are paid to the original card within ten days.",
    "Gift vouchers are sent by e-mail on the date the buyer chooses.",
    "An address can be changed until the order leaves the warehouse."
  ],
  "top_n": 2
}
```

The request is the whole interface: a model, a query, the documents as plain strings, and how many
to return. The reply, as the SDK's own types describe it, gives each hit two fields:

```
ana@desk:~/desk$ .venv-cohere/bin/python -c "import cohere; print(list(cohere.V2RerankResponseResultsItem.model_fields))"
['index', 'relevance_score']
```

**An index into the list you sent, and a relevance score**, not the text, so the program maps back
to its own documents, as `rerank.py` does with `policies[hit.index]`.
