"""labembed: an embedding provider on 127.0.0.1:8500, for lessons 7 to 10.

No embedding API was reachable from the machine this course was recorded on,
and an API key is a bill a course cannot hand out. So the providers' own
Python SDKs (openai, google-genai, cohere) are pointed at this server instead,
unmodified, through the base URL each of them accepts.

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

Every request is one JSON line in $LABEMBED_LOG/requests.jsonl.
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
LOGDIR = os.environ.get("LABEMBED_LOG", "/var/log/labembed")
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
        os.makedirs(LOGDIR, exist_ok=True)
        with _lock, open(os.path.join(LOGDIR, "requests.jsonl"), "a") as f:
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
