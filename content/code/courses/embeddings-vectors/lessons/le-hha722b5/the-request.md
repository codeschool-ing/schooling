---
title: The request
version: 1
---

Every vector so far came from a model running on Ana's laptop. Many teams do not run their own: they
send text to a provider over HTTP, get vectors back, and pay per token. This lesson calls OpenAI's
embeddings endpoint, whose format other providers copy, with OpenAI's own Python library, `openai`.

## What answers on this machine

**The server in this lesson is not OpenAI.** An API key is a bill, and a lesson that needed one
could only be finished by somebody willing to pay it. So this course comes with **labembed**, a
small server written for it, which runs on your own computer at `127.0.0.1:8500`. It answers
OpenAI's `/v1/embeddings` request in OpenAI's format closely enough that the real SDK accepts its
answers unmodified. The vectors are real: they come from all-MiniLM-L6-v2 and WordLlama, the two
models the earlier lessons ran, served under the course's own names `lab-minilm` and
`lab-wordllama`. Lessons 8 and 10 point two more SDKs at it.

Save it as `~/emb/labembed.py`, beside `minilm.py`, which it imports:

```python
"""labembed: an embedding provider on 127.0.0.1:8500, for lessons 7 to 10.

An API key is a bill a course cannot hand out. So the providers' own Python
SDKs (openai, google-genai, cohere) are pointed at this server instead,
unmodified, through the base URL each of them accepts. Start it from ~/emb,
beside minilm.py, and leave it running:  python labembed.py

WHAT IS REAL. The vectors. They come from the two models the rest of the
course runs, and they are computed for every request:

  lab-minilm      all-MiniLM-L6-v2 through minilm.py: 384 numbers,
                  a transformer, the dimension is fixed
  lab-wordllama   WordLlama l2_supercat: 256 numbers, trained so that the
                  first 64 or 128 of them still work on their own, which is
                  what a `dimensions` parameter relies on

WHAT IS THE LAB'S. The wire formats are copied from the providers'
documentation closely enough that the SDKs accept the answers, and the
refusals mimic theirs. The model NAMES are not the providers' models, and a
request for text-embedding-3-small or gemini-embedding-001 is refused with a
404 rather than answered by something else wearing its name. `task_type`,
`input_type` and `task` are checked and recorded, and change nothing: both
lab models are symmetric, so a query and a document are embedded the same way.
Cohere's int8 and binary encodings are this lab's own arithmetic, said below.

    POST /v1/embeddings                          OpenAI, and Jina's copy of it
    POST /v1beta/models/{m}:embedContent         Gemini, one text
    POST /v1beta/models/{m}:batchEmbedContents   Gemini, several
    POST /v2/embed                               Cohere
    POST /lab/config  {"fail": N, "status": 429} the next N requests fail

Every request is one JSON line in labembed.jsonl, in the directory it runs in.
"""
import base64
import datetime
import json
import os
import re
import sys
import threading
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import numpy as np

import minilm
from wordllama import WordLlama

PORT = int(os.environ.get("LABEMBED_PORT", "8500"))
LOG = os.environ.get("LABEMBED_LOG", "labembed.jsonl")
KEYS = {"openai": "lab-openai-key-0001", "google": "lab-google-key-0001",
        "cohere": "lab-cohere-key-0001", "jina": "lab-jina-key-0001"}

_wl = WordLlama.load(dim=256)
_wl_tok = _wl.tokenizer
_lock = threading.Lock()
_fail = {"left": 0, "status": 429}

GEMINI_TASKS = {"RETRIEVAL_QUERY", "RETRIEVAL_DOCUMENT", "SEMANTIC_SIMILARITY",
                "CLASSIFICATION", "CLUSTERING", "QUESTION_ANSWERING",
                "FACT_VERIFICATION", "CODE_RETRIEVAL_QUERY"}
COHERE_INPUTS = {"search_document", "search_query", "classification", "clustering"}
COHERE_TYPES = {"float", "int8", "uint8", "binary", "ubinary"}
JINA_TASKS = {"retrieval.query", "retrieval.passage", "text-matching",
              "classification", "separation"}
MAX_INPUTS = 2048


class Refusal(Exception):
    def __init__(self, status, message, code=None):
        super().__init__(message)
        self.status, self.message, self.code = status, message, code


def tokens(model, text):
    """What a bill counts: the model's own tokens, without its markers."""
    if model == "lab-minilm":
        return len(minilm.pieces(text)) - 2
    return len(_wl_tok.encode(text, add_special_tokens=False).ids)


def vectors(model, texts, dims=None):
    if model == "lab-minilm":
        if dims is not None and dims != minilm.DIM:
            raise Refusal(400, "This model does not support specifying dimensions.",
                          "invalid_value")
        return minilm.embed(texts)
    if model == "lab-wordllama":
        v = _wl.embed(texts, norm=False).astype(np.float32)
        if dims is not None:
            if not 1 <= dims <= 256:
                raise Refusal(400, f"dimensions must be between 1 and 256, got {dims}.",
                              "invalid_value")
            v = v[:, :dims]
        return v / np.linalg.norm(v, axis=1, keepdims=True)
    raise Refusal(404, f"The model `{model}` does not exist or you do not have access to it. "
                  "This lab serves lab-minilm and lab-wordllama.", "model_not_found")


def int8(v):
    """The lab's int8: each vector scaled so its largest magnitude is 127."""
    s = 127.0 / np.abs(v).max(axis=1, keepdims=True)
    return np.round(v * s).astype(np.int8)


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *a):
        pass

    def send_json(self, status, obj, headers=None):
        data = json.dumps(obj).encode()
        self.send_response(status)
        self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(data)))
        for k, v in (headers or {}).items():
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(data)

    def body(self):
        n = int(self.headers.get("content-length") or 0)
        raw = self.rfile.read(n) if n else b""
        try:
            return json.loads(raw or b"{}")
        except ValueError:
            raise Refusal(400, "We could not parse the JSON body of your request.")

    def key(self, provider):
        if provider == "google":
            got = self.headers.get("x-goog-api-key") or ""
        else:
            auth = self.headers.get("authorization") or ""
            got = auth[7:] if auth.lower().startswith("bearer ") else ""
        if not got:
            raise Refusal(401, "You didn't provide an API key.", "missing_api_key")
        if got != KEYS[provider]:
            raise Refusal(401, "Incorrect API key provided.", "invalid_api_key")

    def gate(self):
        with _lock:
            if _fail["left"] > 0:
                _fail["left"] -= 1
                raise Refusal(_fail["status"], "Rate limit reached for requests. "
                              "Please try again in 1s.", "rate_limit_exceeded")

    def do_GET(self):
        self.send_json(200, {"labembed": "ok", "models": ["lab-minilm", "lab-wordllama"]})

    def do_POST(self):
        path = self.path.split("?")[0]
        provider = ("google" if path.startswith("/v1beta/") else
                    "cohere" if path == "/v2/embed" else
                    "jina" if self.headers.get("authorization", "").endswith(KEYS["jina"]) else
                    "openai")
        record = {"at": datetime.datetime.now().astimezone().isoformat(timespec="seconds"),
                  "path": path, "provider": provider}
        try:
            req = self.body()
            if path == "/lab/config":
                with _lock:
                    _fail["left"] = int(req.get("fail", 0))
                    _fail["status"] = int(req.get("status", 429))
                return self.send_json(200, {"fail": _fail["left"], "status": _fail["status"]})
            self.key(provider)
            self.gate()
            if path == "/v1/embeddings":
                status, out = self.openai(req, record, provider)
            elif path == "/v2/embed":
                status, out = self.cohere(req, record)
            else:
                m = re.fullmatch(r"/v1beta/models/([^:]+):(embedContent|batchEmbedContents)", path)
                if not m:
                    raise Refusal(404, f"No route for {path}.")
                status, out = self.gemini(m.group(1), m.group(2), req, record)
            record["status"] = status
            self.write_log(record)
            self.send_json(status, out)
        except Refusal as e:
            record["status"] = e.status
            record["error"] = e.message
            self.write_log(record)
            headers = {"retry-after": "1"} if e.status == 429 else None
            if provider == "google":
                body = {"error": {"code": e.status, "message": e.message,
                                  "status": "INVALID_ARGUMENT" if e.status == 400 else
                                  "NOT_FOUND" if e.status == 404 else
                                  "RESOURCE_EXHAUSTED" if e.status == 429 else "UNAUTHENTICATED"}}
            elif provider == "cohere":
                body = {"message": e.message}
            else:
                body = {"error": {"message": e.message, "type": "invalid_request_error",
                                  "param": None, "code": e.code}}
            self.send_json(e.status, body, headers)

    def write_log(self, record):
        with _lock, open(LOG, "a") as f:
            f.write(json.dumps(record) + "\n")

    def openai(self, req, record, provider):
        model = req.get("model")
        inputs = req.get("input")
        if not model:
            raise Refusal(400, "you must provide a model parameter")
        if isinstance(inputs, str):
            inputs = [inputs]
        if not isinstance(inputs, list) or not inputs or not all(isinstance(t, str) for t in inputs):
            raise Refusal(400, "'input' must be a string or a non-empty array of strings.",
                          "invalid_value")
        if len(inputs) > MAX_INPUTS:
            raise Refusal(400, f"'input' must have at most {MAX_INPUTS} items, got {len(inputs)}.",
                          "invalid_value")
        if any(t == "" for t in inputs):
            raise Refusal(400, "'input' cannot contain an empty string.", "invalid_value")
        fmt = req.get("encoding_format", "float")
        if provider == "jina":
            task = req.get("task")
            if task is not None and task not in JINA_TASKS:
                raise Refusal(422, f"task must be one of {sorted(JINA_TASKS)}")
            record["task"] = task
        v = vectors(model, inputs, req.get("dimensions"))
        n = sum(tokens(model, t) for t in inputs)
        record.update(model=model, inputs=len(inputs), tokens=n, dims=int(v.shape[1]),
                      encoding_format=fmt)
        data = []
        for i, row in enumerate(v):
            emb = (base64.b64encode(row.astype("<f4").tobytes()).decode() if fmt == "base64"
                   else [float(x) for x in row])
            data.append({"object": "embedding", "index": i, "embedding": emb})
        return 200, {"object": "list", "data": data, "model": model,
                     "usage": {"prompt_tokens": n, "total_tokens": n}}

    def gemini(self, model, method, req, record):
        reqs = req.get("requests") if method == "batchEmbedContents" else [dict(req, model="models/" + model)]
        if not reqs:
            raise Refusal(400, "* BatchEmbedContentsRequest.requests: must not be empty")
        texts, task, dims = [], None, None
        for r in reqs:
            parts = (r.get("content") or {}).get("parts") or []
            texts.append("".join(p.get("text", "") for p in parts))
            task = r.get("taskType") or r.get("task_type") or task
            dims = r.get("outputDimensionality") or r.get("output_dimensionality") or dims
        if task is not None and task not in GEMINI_TASKS:
            raise Refusal(400, f"Invalid value at 'requests[0].task_type' ({task})")
        v = vectors(model, texts, dims)
        record.update(model=model, inputs=len(texts), tokens=sum(tokens(model, t) for t in texts),
                      dims=int(v.shape[1]), task_type=task)
        if method == "embedContent":
            return 200, {"embedding": {"values": [float(x) for x in v[0]]}}
        return 200, {"embeddings": [{"values": [float(x) for x in row]} for row in v]}

    def cohere(self, req, record):
        model = req.get("model")
        texts = req.get("texts")
        itype = req.get("input_type")
        kinds = req.get("embedding_types") or ["float"]
        if not model:
            raise Refusal(400, "model is required")
        if not texts:
            raise Refusal(400, "texts is required")
        if itype is None:
            raise Refusal(400, "input_type is required for embed models v3 and higher")
        if itype not in COHERE_INPUTS:
            raise Refusal(400, f"invalid input_type: {itype}")
        bad = [k for k in kinds if k not in COHERE_TYPES]
        if bad:
            raise Refusal(400, f"invalid embedding type: {bad[0]}")
        if len(texts) > 96:
            raise Refusal(400, f"too many texts: {len(texts)} (the limit is 96)")
        v = vectors(model, texts, req.get("output_dimension"))
        n = sum(tokens(model, t) for t in texts)
        record.update(model=model, inputs=len(texts), tokens=n, dims=int(v.shape[1]),
                      input_type=itype, embedding_types=kinds)
        out = {}
        for k in kinds:
            if k == "float":
                out[k] = [[float(x) for x in row] for row in v]
            elif k == "int8":
                out[k] = int8(v).tolist()
            elif k == "uint8":
                out[k] = (int8(v).astype(np.int16) + 128).tolist()
            elif k == "ubinary":
                out[k] = np.packbits(v > 0, axis=1).tolist()
            elif k == "binary":
                out[k] = (np.packbits(v > 0, axis=1).astype(np.int16) - 128).tolist()
        return 200, {"id": str(uuid.UUID(int=len(texts) + n)), "embeddings": out, "texts": texts,
                     "meta": {"api_version": {"version": "2"},
                              "billed_units": {"input_tokens": n}},
                     "response_type": "embeddings_by_type"}


def main():
    srv = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    print(f"labembed on 127.0.0.1:{PORT}", file=sys.stderr, flush=True)
    srv.serve_forever()


if __name__ == "__main__":
    main()
```

You do not need to read it now. Each section of lessons 7, 8 and 10 says which part of it answered,
and why the answer looks as it does. Start it in a second terminal, in `~/emb`, and leave that
terminal open for as long as you work on these lessons:

```bash
cd ~/emb
python labembed.py
```

It prints the address it listens on and then waits. Every request it answers becomes one JSON line
in `~/emb/labembed.jsonl`.

The SDKs find it through environment variables, the ones each of them reads on its own. Add them
to `~/.bashrc`, in the first terminal:

```bash
cat >> ~/.bashrc <<'END'
# embeddings course, lessons 7 to 10: the SDKs talk to labembed
export OPENAI_BASE_URL=http://127.0.0.1:8500/v1
export OPENAI_API_KEY=lab-openai-key-0001
export GEMINI_BASE_URL=http://127.0.0.1:8500
export GEMINI_API_KEY=lab-google-key-0001
export CO_API_URL=http://127.0.0.1:8500
export CO_API_KEY=lab-cohere-key-0001
export JINA_BASE_URL=http://127.0.0.1:8500/v1
export JINA_API_KEY=lab-jina-key-0001
END
source ~/.bashrc
```

The keys are labembed's and open nothing anywhere else. For OpenAI, two of them matter:

```
ana@lab:~/emb$ env | grep ^OPENAI
OPENAI_API_KEY=lab-openai-key-0001
OPENAI_BASE_URL=http://127.0.0.1:8500/v1
```

Against the real service you would delete `OPENAI_BASE_URL`, set your own key, and write
`text-embedding-3-small` where this lesson writes `lab-minilm`. Nothing else in the code changes.
What does change is everything labembed cannot imitate: OpenAI's prices, its rate limits, its
latency and the model's own vectors. Where this lesson says something about those, it quotes
OpenAI's documentation or the price sheet and says so.

## One call

```schooling-example
{
  "language": "python",
  "file": "first.py",
  "parts": [
    {
      "code": "from openai import OpenAI\n\nclient = OpenAI()",
      "note": "`OpenAI()` reads `OPENAI_API_KEY` and `OPENAI_BASE_URL` from the environment. On this machine the base URL points at labembed; without it, the SDK talks to `https://api.openai.com/v1`."
    },
    {
      "code": "response = client.embeddings.create(\n    model=\"lab-minilm\",\n    input=\"When your refund arrives\",\n)",
      "note": "One call, two arguments: which model, and the text. `input` takes a string or a list of strings."
    },
    {
      "code": "vector = response.data[0].embedding\nprint(type(vector).__name__, len(vector), [round(x, 4) for x in vector[:4]])\nprint(response.usage)",
      "note": "The vector is in `data[0].embedding`, a plain Python list of floats. `usage` says how many tokens the request was billed for."
    }
  ]
}
```

```
ana@lab:~/emb$ python first.py
list 384 [-0.0865, -0.0142, -0.0045, 0.0386]
Usage(prompt_tokens=5, total_tokens=5)
ana@lab:~/emb$ tail -n 1 labembed.jsonl
{"at": "2026-10-05T14:19:26-03:00", "path": "/v1/embeddings", "provider": "openai", "model": "lab-minilm", "inputs": 1, "tokens": 5, "dims": 384, "encoding_format": "base64", "status": 200}
```

The first four numbers are the ones lesson 1 printed for the same title from the same model,
rounded the same way. A vector from an API is the same object as a vector from a local model:
384 floats, length 1, comparable with other vectors from that model and no other.

The last line of the transcript is labembed's own log of the request, one JSON line per call. It
records what the SDK sent, and one field in it, `encoding_format`, is a detail the next section
comes back to.

## The same request without the SDK

The SDK is a convenience over one HTTP request, and it helps to see that request bare. It is a
`POST` with the key in an `Authorization: Bearer` header and a JSON body:

```json
{"model": "lab-minilm", "input": "When your refund arrives"}
```

```
ana@lab:~/emb$ curl -s $OPENAI_BASE_URL/embeddings -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" -d @request.json | cut -c 1-150
{"object": "list", "data": [{"object": "embedding", "index": 0, "embedding": [-0.08653447031974792, -0.014246996492147446, -0.004477363079786301, 0.03
```

That is the whole protocol: a model name, an input, and a list of numbers back. Any language with
an HTTP client can call it, which is why so many other providers copy its shape; lesson 10 meets
one that does.

## When the request is refused

Two refusals come up on the first day: a wrong key, and a model name the server does not know.

```python
import openai
from openai import OpenAI

attempts = [
    (OpenAI(api_key="sk-not-the-lab-key"), "lab-minilm"),
    (OpenAI(), "text-embedding-3-small"),
]
for client, model in attempts:
    try:
        client.embeddings.create(model=model, input="When your refund arrives")
    except openai.APIStatusError as e:
        print(type(e).__name__, e.status_code, e.code)
        print("   ", e.body["message"])
```

```
ana@lab:~/emb$ python refused.py
AuthenticationError 401 invalid_api_key
    Incorrect API key provided.
NotFoundError 404 model_not_found
    The model `text-embedding-3-small` does not exist or you do not have access to it. This lab serves lab-minilm and lab-wordllama.
```

The SDK turns each HTTP status into its own exception class, `AuthenticationError` for 401 and
`NotFoundError` for 404, and keeps the server's JSON in `e.body`. Note the second one: labembed
refuses `text-embedding-3-small` **on purpose**, so that nothing in this course can pass a lab
model off as OpenAI's. Against the real service that name is the one to use, and labembed's names
mean nothing there.
