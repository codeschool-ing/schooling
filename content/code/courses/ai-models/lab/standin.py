"""standin: the model providers this course's lab talks to. It is not a model.

No model API is reachable from the machine the course was recorded on, and an
API key is a bill a course cannot hand out. So the providers' own SDKs, at the
versions lab.sh pins, talk to this instead. What it copies is the WIRE: the
paths, the headers it checks, the request and response bodies and the error
shapes of eight APIs, closely enough that each SDK talks to it unmodified.

    port 8500
    POST /v1/messages                           Anthropic Messages
    POST /v1/messages/count_tokens              and its token counter
    GET  /v1/models                             Anthropic or OpenAI, by the key
    POST /v1/chat/completions                   OpenAI Chat Completions, and
                                                Mistral, which has the same shape
    POST /v1/responses   GET /v1/responses/ID   OpenAI Responses
    DELETE /v1/responses/ID
    POST /v1beta/models/M:generateContent       Gemini, and :streamGenerateContent
    POST /v1beta/models/M:countTokens           and :countTokens
    GET  /v1beta/models                         and the list
    POST /v2/chat   /v2/rerank                  Cohere
    POST /hf/v1/chat/completions                Hugging Face's router
    GET  /openrouter/api/v1/models              OpenRouter
    GET  /openrouter/api/v1/key                 and what the key has spent
    POST /openrouter/api/v1/chat/completions
    port 11434
    POST /api/chat  /api/generate  GET /api/tags  POST /api/show  GET /api/ps
    POST /v1/chat/completions                   Ollama, and its OpenAI shape
    port 1234
    GET  /v1/models  POST /v1/chat/completions  LM Studio's OpenAI-compatible server

WHICH PROVIDER A REQUEST IS FOR is decided by its key, the way it is in the
world: /v1/chat/completions is the same path at OpenAI and at Mistral, and only
the key says which account is paying.

WHAT IT ANSWERS IS WRITTEN BY THE COURSE, in two files beside it:

    answers.json  what each stand-in model labels each case in cases.jsonl,
                  and the order number it extracts. A table, not a model.
    replies.json  replies to the few other prompts the lessons send, chosen
                  by the words in the prompt. Anything else gets one sentence
                  saying it was written by the stand-in.

Its own rules, where they are not a provider's, are written here and named in
the lessons: the window and the speed of each model below, a token counted with
o200k_base plus 3 per message, and the rate limit set by /lab/config.

    POST /lab/config   {"rpm": 3, "fail_next": 529, "fail_count": 2,
                        "down": ["standin-east"], "clear": true}   loopback only
"""
import hashlib
import itertools
import json
import os
import random
import re
import sys
import threading
import time
from collections import deque
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import tiktoken

ENC = tiktoken.get_encoding("o200k_base")
SHARE = os.environ.get("STANDIN_SHARE", "/opt/aimodels/share")
LOG = os.environ.get("STANDIN_LOG", "/var/log/standin")

KEYS = {
    "lab-anthropic-key-0001": "anthropic",
    "lab-openai-key-0001": "openai",
    "lab-google-key-0001": "google",
    "lab-mistral-key-0001": "mistral",
    "lab-cohere-key-0001": "cohere",
    "hf_lab_token_0001": "hf",
    "sk-or-lab-key-0001": "openrouter",
}

# The three models, and the numbers that make them differ. They are the
# course's: a window, a ceiling on output, how long before the first token and
# how long each token after it.
MODELS = {
    "standin-large": {"window": 200000, "max_output": 8192, "ttft": 0.60, "per_token": 0.025},
    "standin-small": {"window": 32768, "max_output": 4096, "ttft": 0.15, "per_token": 0.008},
    "standin-local": {"window": 8192, "max_output": 2048, "ttft": 0.90, "per_token": 0.050},
}
# OpenRouter's catalogue: one model offered by two upstream providers, with
# the course's prices per token as strings, the way that API writes them.
ROUTES = {
    "standin/large": {"base": "standin-large", "providers": ["standin-east", "standin-west"],
                      "prompt": "0.000003", "completion": "0.000015"},
    "standin/small": {"base": "standin-small", "providers": ["standin-east"],
                      "prompt": "0.00000025", "completion": "0.00000125"},
}
# Hugging Face's router: the same two models, each provider with a throughput
# (tokens per second) and a price per million output tokens, both the course's.
# ":fastest" (the default) takes the highest throughput, ":cheapest" the lowest
# output price, ":preferred" the account's order, which here is the list's.
HF_ROUTES = {
    "standin/large": {"base": "standin-large",
                      "providers": {"standin-east": (40, 15.0), "standin-west": (80, 18.0)}},
    "standin/small": {"base": "standin-small", "providers": {"standin-east": (120, 1.25)}},
}
# Which upstream providers keep what they are sent, for data_collection: "deny".
# The course's own rule, standing for the Data Policy tag OpenRouter shows.
STORES = {"standin-east": True, "standin-west": False}

CONFIG = {"rpm": 50, "fail_next": None, "fail_count": 0, "down": [], "jitter": 0, "or_key_limit": None}
SPENT = {}       # OpenRouter: dollars each key has spent, for its credit limit
LOCK = threading.Lock()
COUNTER = itertools.count(1)
SEEN = {}        # key -> deque of request times
TURNS = {}       # (model, case) -> how many times it was asked, for the unstable cases
STORED = {}      # response id -> (input items, output text), for previous_response_id
LOADED = {}      # Ollama: model -> when keep_alive lets it go (epoch seconds)
CACHED = {}      # Anthropic prompt caching: hash of a cached prefix -> when it expires
# The shortest prefix each model will cache, in tokens: the course's numbers,
# shaped like the per-model minimums Anthropic documents. Below it, a request
# marked for caching is processed without caching, and nothing says so.
CACHE_MIN = {"standin-large": 1024, "standin-small": 2048}


def load(name):
    with open(os.path.join(SHARE, name)) as f:
        return json.load(f) if name.endswith(".json") else [json.loads(x) for x in f if x.strip()]


def log(record):
    os.makedirs(LOG, exist_ok=True)
    with open(os.path.join(LOG, "requests.jsonl"), "a") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")


def mask(value):
    """A key in the log is cut to what identifies it, never the whole of it."""
    return value[:12] + "…" if value and len(value) > 12 else value


# ---------------------------------------------------------------- counting

def text_of(content):
    if content is None:
        return ""
    if isinstance(content, str):
        return content
    if isinstance(content, dict):
        content = [content]
    out = []
    for b in content:
        if isinstance(b, str):
            out.append(b)
        elif b.get("type") in ("text", "input_text", "output_text") or "text" in b:
            out.append(b.get("text", ""))
        elif b.get("type") == "tool_result":
            out.append(text_of(b.get("content")))
    return "\n".join(out)


def count(system, messages):
    n = len(ENC.encode(text_of(system)))
    for m in messages:
        n += 3 + len(ENC.encode(text_of(m.get("content"))))
    return n


# ---------------------------------------------------------------- the answers

def answer(model, system, messages, temperature):
    """The reply text, and which rule chose it. Every reply is the course's."""
    user = ""
    for m in reversed(messages):
        if m.get("role") == "user":
            user = text_of(m.get("content"))
            break
    whole = text_of(system) + "\n" + user
    for r in load("replies.json"):
        if all(s.lower() in whole.lower() for s in r["when"]):
            return r["reply"], r["id"]
    for case in load("cases.jsonl"):
        if case["text"] in user:
            return case_answer(model, case, whole, temperature)
    return (f"This reply was written by the course's stand-in, not by a model. "
            f"{model} answers every prompt it has no reply for with this sentence."), "none"


def case_answer(model, case, prompt, temperature):
    table = load("answers.json")
    if "json" in prompt.lower():
        wrong = table["extract"].get(model, {})
        order = wrong.get(case["id"], case["order"]) if case["id"] in wrong else case["order"]
        if order == "prose":
            return "Here is the JSON you asked for: " + json.dumps({"order": case["order"]}), "extract:" + case["id"]
        return json.dumps({"order": order}), "extract:" + case["id"]
    unstable = table["unstable"].get(model, {}).get(case["id"])
    if unstable and temperature not in (None, 0, 0.0):
        with LOCK:
            k = TURNS.get((model, case["id"]), 0)
            TURNS[(model, case["id"])] = k + 1
        return unstable[k % len(unstable)], "triage:" + case["id"]
    return table["triage"].get(model, {}).get(case["id"], case["label"]), "triage:" + case["id"]


def pieces(text):
    return [ENC.decode([t]) for t in ENC.encode(text)]


# ---------------------------------------------------------------- the server

class Refusal(Exception):
    def __init__(self, status, kind, message, headers=None, body_metadata=None):
        super().__init__(message)
        self.status, self.kind, self.message, self.headers = status, kind, message, headers or {}
        self.metadata = body_metadata


class Handler(BaseHTTPRequestHandler):
    server_version = "standin/1.0"
    sys_version = ""
    protocol_version = "HTTP/1.1"

    def log_message(self, *a):
        pass

    # -- plumbing
    def body(self):
        n = int(self.headers.get("Content-Length") or 0)
        raw = self.rfile.read(n) if n else b""
        try:
            return json.loads(raw or b"{}")
        except json.JSONDecodeError as e:
            raise Refusal(400, "invalid_request_error", f"the body is not JSON: {e}")

    def send_json(self, status, obj, headers=None):
        data = json.dumps(obj, ensure_ascii=False).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("request-id", "req_lab_%04d" % self.n)
        for k, v in (headers or {}).items():
            self.send_header(k, str(v))
        self.end_headers()
        self.wfile.write(data)

    def start_stream(self, ctype="text/event-stream"):
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Connection", "close")
        self.end_headers()
        self.close_connection = True

    def event(self, name, data):
        line = (f"event: {name}\n" if name else "") + "data: " + json.dumps(data, ensure_ascii=False) + "\n\n"
        self.wfile.write(line.encode())
        self.wfile.flush()

    def key(self):
        for h in ("x-api-key", "x-goog-api-key"):
            if self.headers.get(h):
                return self.headers.get(h)
        auth = self.headers.get("Authorization") or ""
        return auth.removeprefix("Bearer ").strip() or None

    def provider(self, path):
        if self.server.server_port == 11434:
            return "ollama"
        if self.server.server_port == 1234:
            return "lmstudio"
        if path.startswith("/openrouter/"):
            return "openrouter"
        if path.startswith("/hf/"):
            return "hf"
        if path.startswith("/v1beta"):
            return "google"
        if path.startswith("/v2/"):
            return "cohere"
        return KEYS.get(self.key()) or ("anthropic" if self.headers.get("x-api-key") else "openai")

    def gate(self, provider):
        """The key, the injected failures and the rate limit, in that order."""
        if provider in ("ollama", "lmstudio"):
            return {}
        key = self.key()
        if KEYS.get(key) != provider:
            raise Refusal(401, "authentication_error", {
                "anthropic": "invalid x-api-key", "google": "API key not valid. Please pass a valid API key.",
                "cohere": "invalid api token"}.get(provider, "Incorrect API key provided"))
        # the version header belongs to the Messages API; the OpenAI-compatible path does without
        if provider == "anthropic" and not self.headers.get("anthropic-version") \
                and self.path.split("?")[0] != "/v1/chat/completions":
            raise Refusal(400, "invalid_request_error", "anthropic-version: header is required")
        with LOCK:
            if CONFIG["fail_count"]:
                CONFIG["fail_count"] -= 1
                status = CONFIG["fail_next"]
                if not CONFIG["fail_count"]:
                    CONFIG["fail_next"] = None
                raise Refusal(status, "overloaded_error" if status == 529 else "api_error",
                              "Overloaded" if status == 529 else "Internal server error")
            now = time.time()
            q = SEEN.setdefault(key, deque())
            while q and now - q[0] >= 60:
                q.popleft()
            limit = CONFIG["rpm"]
            if len(q) >= limit:
                wait = int(60 - (now - q[0])) + 1
                raise Refusal(429, "rate_limit_error",
                              f"This request would exceed the rate limit of {limit} requests per minute.",
                              dict(self.limit_headers(provider, limit, 0, wait), **{"retry-after": wait}))
            q.append(now)
            reset = int(60 - (now - q[-1])) + 1  # when the newest request leaves the window
            return self.limit_headers(provider, limit, limit - len(q), reset)

    @staticmethod
    def limit_headers(provider, limit, remaining, reset):
        if provider == "anthropic":
            return {"anthropic-ratelimit-requests-limit": limit,
                    "anthropic-ratelimit-requests-remaining": remaining,
                    "anthropic-ratelimit-requests-reset":
                        time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(time.time() + reset))}
        if provider in ("openai", "mistral", "openrouter", "hf"):
            return {"x-ratelimit-limit-requests": limit, "x-ratelimit-remaining-requests": remaining,
                    "x-ratelimit-reset-requests": f"{reset}s"}
        return {}

    def refuse(self, e, provider):
        if provider == "anthropic":
            obj = {"type": "error", "error": {"type": e.kind, "message": e.message},
                   "request_id": "req_lab_%04d" % self.n}
        elif provider == "google":
            obj = {"error": {"code": e.status, "message": e.message, "status": {
                400: "INVALID_ARGUMENT", 401: "UNAUTHENTICATED", 404: "NOT_FOUND",
                429: "RESOURCE_EXHAUSTED"}.get(e.status, "INTERNAL")}}
        elif provider == "cohere":
            obj = {"message": e.message}
        elif provider == "ollama":
            obj = {"error": e.message}
        elif provider == "openrouter" and e.metadata:
            obj = {"error": {"code": e.status, "message": e.message, "metadata": e.metadata}}
        else:
            obj = {"error": {"message": e.message, "type": e.kind, "code": None}}
        self.send_json(e.status, obj, e.headers)

    def handle_any(self, method):
        self.n = next(COUNTER)
        path = self.path.split("?")[0]
        provider = self.provider(path)
        started = time.time()
        record = {"n": self.n, "at": time.strftime("%H:%M:%S"), "port": self.server.server_port,
                  "method": method, "path": path, "provider": provider,
                  "headers": {k.lower(): (mask(v) if k.lower() in ("x-api-key", "authorization", "x-goog-api-key")
                                          else v) for k, v in self.headers.items()}}
        try:
            if path == "/lab/config":
                if self.client_address[0] != "127.0.0.1":
                    raise Refusal(403, "permission_error", "loopback only")
                with LOCK:
                    CONFIG.update(self.body())
                    if CONFIG.get("fail_next") and not CONFIG.get("fail_count"):
                        CONFIG["fail_count"] = 1
                    if CONFIG.pop("clear", None):
                        SEEN.clear(); TURNS.clear(); STORED.clear(); SPENT.clear()
                return self.send_json(200, dict(CONFIG))
            req = self.body() if method == "POST" else {}
            if req:
                record["request"] = req
            headers = self.gate(provider)
            self.route(method, path, provider, req, headers, record)
            record.setdefault("status", 200)
        except Refusal as e:
            record["status"], record["error"] = e.status, e.message
            self.refuse(e, provider)
        except (BrokenPipeError, ConnectionResetError):
            record["status"] = "client went away"
        record["ms"] = int((time.time() - started) * 1000)
        log(record)

    def do_GET(self):
        self.handle_any("GET")

    def do_POST(self):
        self.handle_any("POST")

    def do_DELETE(self):
        self.handle_any("DELETE")

    def route(self, method, path, provider, req, headers, record):
        if provider == "ollama":
            return self.ollama(method, path, req, record)
        if provider == "lmstudio":
            return self.lmstudio(method, path, req, record)
        if method == "GET" and path == "/v1/models":
            return self.list_models(provider, headers)
        if method == "GET" and path == "/v1beta/models":
            return self.send_json(200, {"models": [
                {"name": "models/" + m, "displayName": m, "inputTokenLimit": v["window"],
                 "outputTokenLimit": v["max_output"],
                 "supportedGenerationMethods": ["generateContent", "countTokens"]} for m, v in MODELS.items()]})
        if method == "DELETE" and path.startswith("/v1/responses/"):
            rid = path.rsplit("/", 1)[1]
            if STORED.pop(rid, None) is None:
                raise Refusal(404, "invalid_request_error", f"Response with id '{rid}' not found.")
            return self.send_json(200, {"id": rid, "object": "response", "deleted": True}, headers)
        if method == "GET" and path.startswith("/v1/responses/"):
            rid = path.rsplit("/", 1)[1]
            if rid not in STORED:
                raise Refusal(404, "invalid_request_error", f"Response with id '{rid}' not found.")
            return self.send_json(200, STORED[rid]["response"], headers)
        if method == "GET" and path == "/openrouter/api/v1/key":
            limit, used = CONFIG["or_key_limit"], round(SPENT.get(self.key(), 0.0), 8)
            return self.send_json(200, {"data": {
                "label": "lab key", "limit": limit, "limit_reset": None,
                "limit_remaining": None if limit is None else round(max(limit - used, 0.0), 8),
                "include_byok_in_limit": False, "usage": used, "usage_daily": used, "usage_weekly": used,
                "usage_monthly": used, "is_free_tier": False}})
        if method == "GET" and path == "/openrouter/api/v1/models":
            return self.send_json(200, {"data": [
                {"id": k, "name": k, "context_length": MODELS[v["base"]]["window"],
                 "pricing": {"prompt": v["prompt"], "completion": v["completion"]}} for k, v in ROUTES.items()]})
        if method != "POST":
            raise Refusal(404, "not_found_error", f"Not found: {path}")
        if path == "/v1/messages":
            return self.messages(req, headers, record)
        if path == "/v1/messages/count_tokens":
            n = self.check_anthropic(req, need_max=False)
            record["input_tokens"] = n
            return self.send_json(200, {"input_tokens": n}, headers)
        if path == "/hf/v1/chat/completions":
            return self.hf_router(req, headers, record)
        if path == "/v1/chat/completions":
            return self.chat(req, headers, record)
        if path == "/openrouter/api/v1/chat/completions":
            return self.openrouter(req, headers, record)
        if path == "/v1/responses":
            return self.responses_api(req, headers, record)
        if path.startswith("/v1beta/models/"):
            return self.gemini(path, req, record)
        if path == "/v2/chat":
            return self.cohere_chat(req, record)
        if path == "/v2/rerank":
            return self.cohere_rerank(req, record)
        raise Refusal(404, "not_found_error", f"Not found: {path}")

    def list_models(self, provider, headers):
        if provider == "anthropic":
            data = [{"type": "model", "id": m, "display_name": m.replace("-", " ").title(),
                     "created_at": "2026-09-01T00:00:00Z"} for m in MODELS]
            return self.send_json(200, {"data": data, "has_more": False,
                                        "first_id": data[0]["id"], "last_id": data[-1]["id"]}, headers)
        return self.send_json(200, {"object": "list", "data": [
            {"id": m, "object": "model", "created": 1788220800, "owned_by": "standin"} for m in MODELS]}, headers)

    # -- shared by every API: check the model, produce the reply, wait as long as it would take
    def model_of(self, model):
        if model not in MODELS:
            raise Refusal(404, "not_found_error", f"model: {model}")
        return MODELS[model]

    def produce(self, model, system, messages, limit, temperature, record):
        spec = self.model_of(model)
        n_in = count(system, messages)
        if n_in + limit > spec["window"]:
            raise Refusal(400, "invalid_request_error",
                          f"prompt is too long: {n_in} tokens + {limit} max tokens > {spec['window']} maximum")
        text, rule = answer(model, system, messages, temperature)
        toks = pieces(text)
        reason = "end"
        if len(toks) > limit:
            toks, reason = toks[:limit], "length"
        record.update(model=model, rule=rule)
        return toks, reason, n_in

    def first(self, model):
        """Time to the first token. With "jitter" set, it is stretched by a random factor whose
        tail is long, the way a shared service's is; the draw is seeded by the request number."""
        extra = random.Random(self.n).expovariate(1.0) * CONFIG["jitter"] if CONFIG["jitter"] else 0
        return MODELS[model]["ttft"] * (1 + extra)

    def wait(self, model, n_out):
        time.sleep(self.first(model) + MODELS[model]["per_token"] * n_out)

    # -- Anthropic
    def check_anthropic(self, req, need_max=True):
        self.model_of(req.get("model"))
        if need_max and not isinstance(req.get("max_tokens"), int):
            raise Refusal(400, "invalid_request_error", "max_tokens: Field required")
        msgs = req.get("messages")
        if not isinstance(msgs, list) or not msgs:
            raise Refusal(400, "invalid_request_error", "messages: at least one message is required")
        if msgs[0].get("role") != "user":
            raise Refusal(400, "invalid_request_error", "messages: the first message must use the \"user\" role")
        for a, b in zip(msgs, msgs[1:]):
            if a.get("role") == b.get("role"):
                raise Refusal(400, "invalid_request_error",
                              "messages: roles must alternate between \"user\" and \"assistant\"")
        if need_max and req["max_tokens"] > MODELS[req["model"]]["max_output"]:
            raise Refusal(400, "invalid_request_error",
                          f"max_tokens: {req['max_tokens']} > {MODELS[req['model']]['max_output']}, which is the "
                          f"maximum allowed number of output tokens for {req['model']}")
        return count(req.get("system"), msgs)

    def cache(self, req, n_in):
        """Prompt caching: the prefix up to the last block marked cache_control, if it is long
        enough. Returns (written, read) token counts; input_tokens is what remains after them."""
        system, msgs = req.get("system"), req["messages"]
        marks = []
        if isinstance(system, list) and any(isinstance(b, dict) and b.get("cache_control") for b in system):
            marks.append((system, [], max(i for i, b in enumerate(system) if b.get("cache_control"))))
        for i, m in enumerate(msgs):
            blocks = m.get("content")
            if isinstance(blocks, list) and any(isinstance(b, dict) and b.get("cache_control") for b in blocks):
                marks.append((system, msgs[:i + 1], i))
        if not marks:
            return 0, 0
        sys_part, msg_part, _ = marks[-1]
        prefix = count(sys_part, msg_part)
        if prefix < CACHE_MIN.get(req["model"], 10 ** 9) or prefix > n_in:
            return 0, 0
        ttl = 3600 if '"ttl": "1h"' in json.dumps([sys_part, msg_part]) else 300
        key = hashlib.sha256(json.dumps([req["model"], sys_part, msg_part], sort_keys=True).encode()).hexdigest()
        now = time.time()
        hit = CACHED.get(key, 0) > now
        CACHED[key] = now + ttl  # a hit refreshes the lifetime
        return (0, prefix) if hit else (prefix, 0)

    def messages(self, req, headers, record):
        self.check_anthropic(req)
        toks, reason, n_in = self.produce(req["model"], req.get("system"), req["messages"], req["max_tokens"],
                                          req.get("temperature"), record)
        stop = {"end": "end_turn", "length": "max_tokens"}[reason]
        written, read = self.cache(req, n_in)
        usage = {"input_tokens": n_in - written - read, "output_tokens": len(toks),
                 "cache_creation_input_tokens": written, "cache_read_input_tokens": read}
        record["usage"] = usage
        mid = "msg_lab_%04d" % self.n
        if not req.get("stream"):
            self.wait(req["model"], len(toks))
            return self.send_json(200, {
                "id": mid, "type": "message", "role": "assistant", "model": req["model"],
                "content": [{"type": "text", "text": "".join(toks)}], "stop_reason": stop,
                "stop_sequence": None, "usage": usage}, headers)
        spec = MODELS[req["model"]]
        self.start_stream()
        time.sleep(self.first(req["model"]))
        self.event("message_start", {"type": "message_start", "message": {
            "id": mid, "type": "message", "role": "assistant", "model": req["model"], "content": [],
            "stop_reason": None, "stop_sequence": None, "usage": dict(usage, output_tokens=1)}})
        self.event("content_block_start", {"type": "content_block_start", "index": 0,
                                           "content_block": {"type": "text", "text": ""}})
        for p in toks:
            time.sleep(spec["per_token"])
            self.event("content_block_delta", {"type": "content_block_delta", "index": 0,
                                               "delta": {"type": "text_delta", "text": p}})
        self.event("content_block_stop", {"type": "content_block_stop", "index": 0})
        self.event("message_delta", {"type": "message_delta", "delta": {"stop_reason": stop, "stop_sequence": None},
                                     "usage": {"output_tokens": len(toks)}})
        self.event("message_stop", {"type": "message_stop"})

    # -- OpenAI Chat Completions, and everybody who copied it
    @staticmethod
    def split_chat(msgs):
        system = "\n".join(text_of(m.get("content")) for m in msgs if m.get("role") in ("system", "developer"))
        rest = [m for m in msgs if m.get("role") not in ("system", "developer")]
        return system, rest

    def chat(self, req, headers, record, extra=None):
        msgs = req.get("messages")
        if not isinstance(msgs, list) or not msgs:
            raise Refusal(400, "invalid_request_error", "messages: a non-empty list is required")
        system, rest = self.split_chat(msgs)
        limit = req.get("max_completion_tokens") or req.get("max_tokens") or 1024
        model = (extra or {}).get("model", req.get("model"))
        toks, reason, n_in = self.produce(model, system, rest, limit, req.get("temperature"), record)
        finish = {"end": "stop", "length": "length"}[reason]
        usage = {"prompt_tokens": n_in, "completion_tokens": len(toks), "total_tokens": n_in + len(toks)}
        if extra and "cost" in extra:
            usage["cost"] = extra["cost"](n_in, len(toks))
        record["usage"] = usage
        cid = "chatcmpl-lab%04d" % self.n
        shown = req.get("model") if not extra else extra.get("shown", req.get("model"))
        if not req.get("stream"):
            self.wait(model, len(toks))
            body = {"id": cid, "object": "chat.completion", "created": int(time.time()), "model": shown,
                    "choices": [{"index": 0, "message": {"role": "assistant", "content": "".join(toks)},
                                 "finish_reason": finish}], "usage": usage}
            if extra and "provider" in extra:
                body["provider"] = extra["provider"]
            return self.send_json(200, body, headers)
        spec = MODELS[model]
        self.start_stream()
        time.sleep(self.first(model))
        base = {"id": cid, "object": "chat.completion.chunk", "created": int(time.time()), "model": shown}
        self.event(None, dict(base, choices=[{"index": 0, "delta": {"role": "assistant", "content": ""},
                                              "finish_reason": None}]))
        for p in toks:
            time.sleep(spec["per_token"])
            self.event(None, dict(base, choices=[{"index": 0, "delta": {"content": p}, "finish_reason": None}]))
        last = dict(base, choices=[{"index": 0, "delta": {}, "finish_reason": finish}])
        if (req.get("stream_options") or {}).get("include_usage"):
            self.event(None, last)
            last = dict(base, choices=[], usage=usage)
        self.event(None, last)
        self.wfile.write(b"data: [DONE]\n\n")

    # -- OpenRouter: one model, several upstreams, and a list of models to fall back through
    def openrouter(self, req, headers, record):
        limit = CONFIG["or_key_limit"]
        if limit is not None and SPENT.get(self.key(), 0.0) >= limit:
            raise Refusal(402, "payment_required",
                          "This API key has reached its credit limit.",
                          body_metadata={"limit_source": "openrouter_key_limit",
                                         "remedy_hint": "Raise the key's credit limit or wait for it to reset."})
        wanted = req.get("models") or [req.get("model")]
        prefs = req.get("provider") or {}
        tried = []
        for name in wanted:
            route = ROUTES.get(name)
            if not route:
                tried.append(f"{name}: no such model")
                continue
            ups = list(route["providers"])
            if prefs.get("order"):
                ups = [p for p in prefs["order"] if p in ups] + [p for p in ups if p not in prefs["order"]]
            if prefs.get("data_collection") == "deny":
                kept = [p for p in ups if not STORES.get(p, True)]
                tried += [f"{name} at {p}: stores data" for p in ups if p not in kept]
                ups = kept
            if prefs.get("allow_fallbacks") is False:
                ups = ups[:1]
            for up in ups:
                if up in CONFIG["down"]:
                    tried.append(f"{name} at {up}: 503")
                    continue
                record["routed"] = {"model": name, "provider": up, "tried": tried}
                price = (float(route["prompt"]), float(route["completion"]))
                key = self.key()

                def cost(i, o):
                    c = round(i * price[0] + o * price[1], 8)
                    SPENT[key] = SPENT.get(key, 0.0) + c
                    return c
                return self.chat(req, headers, record, extra={
                    "model": route["base"], "shown": name, "provider": up, "cost": cost})
        record["routed"] = {"tried": tried}
        raise Refusal(503, "provider_unavailable", "No allowed providers are available for the selected model. "
                      + "; ".join(tried))

    def hf_router(self, req, headers, record):
        name, _, suffix = (req.get("model") or "").partition(":")
        route = HF_ROUTES.get(name)
        if not route:
            raise Refusal(400, "model_not_supported", f"The requested model '{name}' is not supported by any provider you have enabled.")
        ups = route["providers"]
        policy = suffix or "fastest"
        if policy == "fastest":
            up = max(ups, key=lambda p: ups[p][0])
        elif policy == "cheapest":
            up = min(ups, key=lambda p: ups[p][1])
        elif policy == "preferred":
            up = next(iter(ups))
        elif policy in ups:
            up = policy
        else:
            raise Refusal(400, "model_not_supported",
                          f"The requested model '{name}' is not supported by provider '{policy}'.")
        record["routed"] = {"model": name, "provider": up, "policy": policy}
        return self.chat(req, headers, record, extra={"model": route["base"], "shown": name})

    # -- OpenAI Responses
    def responses_api(self, req, headers, record):
        model = req.get("model")
        items = req.get("input")
        if isinstance(items, str):
            items = [{"role": "user", "content": items}]
        if not items:
            raise Refusal(400, "invalid_request_error", "Missing required parameter: 'input'.")
        history = []
        prev = req.get("previous_response_id")
        if prev:
            if prev not in STORED:
                raise Refusal(400, "invalid_request_error", f"Previous response with id '{prev}' not found.")
            history = STORED[prev]["conversation"]
        conversation = history + [{"role": i.get("role", "user"), "content": text_of(i.get("content"))}
                                  for i in items if i.get("role") in (None, "user", "assistant")]
        system = req.get("instructions")
        limit = req.get("max_output_tokens") or 1024
        if req.get("truncation") == "auto":
            # drop items from the beginning of the conversation until it fits
            while len(conversation) > 1 and count(system, conversation) + limit > self.model_of(model)["window"]:
                conversation = conversation[1:]
        toks, reason, n_in = self.produce(model, system, conversation, limit, req.get("temperature"), record)
        text = "".join(toks)
        usage = {"input_tokens": n_in, "input_tokens_details": {"cached_tokens": 0},
                 "output_tokens": len(toks), "output_tokens_details": {"reasoning_tokens": 0},
                 "total_tokens": n_in + len(toks)}
        record["usage"] = usage
        rid = "resp_lab_%04d" % self.n
        msg = {"type": "message", "id": "msg_lab_%04d" % self.n, "status": "completed", "role": "assistant",
               "content": [{"type": "output_text", "text": text, "annotations": []}]}
        response = {"id": rid, "object": "response", "created_at": int(time.time()), "model": model,
                    "status": "completed" if reason == "end" else "incomplete",
                    "incomplete_details": None if reason == "end" else {"reason": "max_output_tokens"},
                    "instructions": system, "previous_response_id": prev, "output": [msg],
                    "parallel_tool_calls": True, "tool_choice": "auto", "tools": [], "store": req.get("store", True),
                    "usage": usage}
        if req.get("store", True):
            STORED[rid] = {"response": response,
                           "conversation": conversation + [{"role": "assistant", "content": text}]}
        if not req.get("stream"):
            self.wait(model, len(toks))
            return self.send_json(200, response, headers)
        spec = MODELS[model]
        self.start_stream()
        time.sleep(self.first(model))
        seq = itertools.count(0)
        self.event("response.created", {"type": "response.created", "sequence_number": next(seq),
                                         "response": dict(response, status="in_progress", output=[], usage=None)})
        for p in toks:
            time.sleep(spec["per_token"])
            self.event("response.output_text.delta", {"type": "response.output_text.delta",
                                                      "sequence_number": next(seq), "item_id": msg["id"],
                                                      "output_index": 0, "content_index": 0, "delta": p,
                                                      "logprobs": []})
        self.event("response.completed", {"type": "response.completed", "sequence_number": next(seq),
                                           "response": response})

    # -- Google
    def gemini(self, path, req, record):
        m = re.match(r"/v1beta/models/([^:]+):(generateContent|streamGenerateContent|countTokens)$", path)
        if not m:
            raise Refusal(404, "not_found_error", f"Not found: {path}")
        model, verb = m.groups()
        conv = [{"role": "assistant" if c.get("role") == "model" else "user",
                 "content": "".join(p.get("text", "") for p in c.get("parts", []))}
                for c in req.get("contents") or []]
        si = req.get("systemInstruction") or {}
        system = "".join(p.get("text", "") for p in si.get("parts", [])) or None
        if verb == "countTokens":
            self.model_of(model)
            return self.send_json(200, {"totalTokens": count(system, conv)})
        cfg = req.get("generationConfig") or {}
        toks, reason, n_in = self.produce(model, system, conv, cfg.get("maxOutputTokens", 1024),
                                          cfg.get("temperature"), record)
        finish = {"end": "STOP", "length": "MAX_TOKENS"}[reason]
        usage = {"promptTokenCount": n_in, "candidatesTokenCount": len(toks), "totalTokenCount": n_in + len(toks)}
        record["usage"] = usage

        def resp(t, fin):
            c = {"content": {"role": "model", "parts": [{"text": t}]}, "index": 0}
            if fin:
                c["finishReason"] = fin
            return {"candidates": [c], "usageMetadata": usage, "modelVersion": model,
                    "responseId": "lab%04d" % self.n}
        if verb == "generateContent":
            self.wait(model, len(toks))
            return self.send_json(200, resp("".join(toks), finish))
        spec = MODELS[model]
        self.start_stream()
        time.sleep(self.first(model))
        for k, p in enumerate(toks):
            time.sleep(spec["per_token"])
            self.event(None, resp(p, finish if k == len(toks) - 1 else None))

    # -- Cohere
    def cohere_chat(self, req, record):
        system, rest = self.split_chat(req.get("messages") or [])
        if not rest:
            raise Refusal(400, "invalid_request_error", "messages: at least one user message is required")
        toks, reason, n_in = self.produce(req.get("model"), system, rest, req.get("max_tokens") or 1024,
                                          req.get("temperature"), record)
        self.wait(req["model"], len(toks))
        usage = {"billed_units": {"input_tokens": n_in, "output_tokens": len(toks)},
                 "tokens": {"input_tokens": n_in, "output_tokens": len(toks)}}
        record["usage"] = usage
        self.send_json(200, {"id": "lab-%04d" % self.n,
                             "finish_reason": {"end": "COMPLETE", "length": "MAX_TOKENS"}[reason],
                             "message": {"role": "assistant", "content": [{"type": "text", "text": "".join(toks)}]},
                             "usage": usage})

    def cohere_rerank(self, req, record):
        """Ranks by shared words. Cohere's reranker is a model; this is arithmetic, and says so."""
        def words(s):
            return set(re.findall(r"[a-z0-9]+", s.lower()))
        q = words(req.get("query", ""))
        docs = [d if isinstance(d, str) else d.get("text", "") for d in req.get("documents") or []]
        scored = [(len(q & words(d)) / (len(q) or 1), i) for i, d in enumerate(docs)]
        scored.sort(key=lambda x: (-x[0], x[1]))
        top = scored[:req.get("top_n") or len(scored)]
        record.update(model=req.get("model"), rule="word-overlap")
        self.send_json(200, {"id": "lab-%04d" % self.n,
                             "results": [{"index": i, "relevance_score": round(s, 4)} for s, i in top],
                             "meta": {"billed_units": {"search_units": 1}}})

    # -- Ollama, on its own port
    def ollama(self, method, path, req, record):
        local = {m: v for m, v in MODELS.items() if m == "standin-local"}
        if method == "GET" and path == "/api/tags":
            return self.send_json(200, {"models": [
                {"name": m + ":latest", "model": m + ":latest", "modified_at": "2026-09-14T10:02:11-03:00",
                 "size": 0, "digest": hashlib.sha256(m.encode()).hexdigest(),
                 "details": {"format": "standin", "family": "standin", "parameter_size": "none",
                             "quantization_level": "none"}} for m in local]})
        if method == "GET" and path == "/api/ps":
            now = time.time()
            return self.send_json(200, {"models": [
                {"name": m + ":latest", "model": m + ":latest", "size": 0,
                 "digest": hashlib.sha256(m.encode()).hexdigest(),
                 "details": {"format": "standin", "family": "standin"},
                 "expires_at": time.strftime("%Y-%m-%dT%H:%M:%S-03:00", time.localtime(t)), "size_vram": 0}
                for m, t in sorted(LOADED.items()) if t > now]})
        if method == "GET" and path == "/v1/models":
            # created is when the model was last modified, the same instant /api/tags gives
            return self.send_json(200, {"object": "list", "data": [
                {"id": m + ":latest", "object": "model", "created": 1789390931, "owned_by": "library"}
                for m in local]})
        if method == "GET" and path in ("/", "/api/version"):
            return self.send_json(200, {"version": "standin"})
        if method != "POST":
            raise Refusal(404, "not_found_error", "404 page not found")
        if path == "/v1/chat/completions":
            req = dict(req, model=req.get("model", "").removesuffix(":latest"))
            return self.chat(req, {}, record)
        name = (req.get("model") or "").removesuffix(":latest")
        if name not in local:
            raise Refusal(404, "not_found", f"model '{req.get('model')}' not found")
        if path == "/api/show":
            return self.send_json(200, {"modelfile": "# standin-local has no Modelfile: it is not a model\n",
                                        "parameters": "", "template": "",
                                        "details": {"format": "standin", "family": "standin"},
                                        "model_info": {"standin.context_length": MODELS[name]["window"]}})
        opts = req.get("options") or {}
        # keep_alive, as docs/api.md describes it: how long the model stays
        # loaded after this request, 5m when absent, 0 to unload now
        alive = req.get("keep_alive", "5m")
        if isinstance(alive, str):
            unit = {"s": 1, "m": 60, "h": 3600}.get(alive[-1:], 1)
            alive = float(alive.rstrip("smh") or 0) * unit
        if alive == 0:
            LOADED.pop(name, None)
        else:
            LOADED[name] = time.time() + (alive if alive > 0 else 10 ** 9)
        if path == "/api/generate" and not req.get("prompt") and not req.get("system"):
            return self.send_json(200, {"model": req["model"], "created_at": time.strftime("%Y-%m-%dT%H:%M:%S-03:00"),
                                        "response": "", "done": True, "done_reason": "unload" if alive == 0 else "load"})
        if path == "/api/chat":
            system, rest = self.split_chat(req.get("messages") or [])
        elif path == "/api/generate":
            system, rest = req.get("system"), [{"role": "user", "content": req.get("prompt", "")}]
        else:
            raise Refusal(404, "not_found_error", "404 page not found")
        window = opts.get("num_ctx", 4096)  # docs/faq.mdx: "a context window size of 4096 tokens"
        rest_trimmed = rest
        while len(rest_trimmed) > 1 and count(system, rest_trimmed) > window:
            rest_trimmed = rest_trimmed[1:]
        toks, reason, n_in = self.produce(name, system, rest_trimmed, opts.get("num_predict", 512),
                                          opts.get("temperature"), record)
        spec = MODELS[name]
        ns = lambda s: int(s * 1e9)  # noqa: E731
        final = {"model": req["model"], "created_at": time.strftime("%Y-%m-%dT%H:%M:%S-03:00"), "done": True,
                 "done_reason": {"end": "stop", "length": "length"}[reason],
                 "total_duration": ns(spec["ttft"] + spec["per_token"] * len(toks)),
                 "load_duration": ns(0), "prompt_eval_count": n_in, "prompt_eval_duration": ns(spec["ttft"]),
                 "eval_count": len(toks), "eval_duration": ns(spec["per_token"] * len(toks))}
        record["usage"] = {"prompt_eval_count": n_in, "eval_count": len(toks)}

        def piece(t):
            if path == "/api/chat":
                return {"message": {"role": "assistant", "content": t}}
            return {"response": t}
        if req.get("stream") is False:
            self.wait(name, len(toks))
            return self.send_json(200, dict(final, **piece("".join(toks))))
        self.start_stream("application/x-ndjson")
        time.sleep(self.first(name))
        for p in toks:
            time.sleep(spec["per_token"])
            line = dict({"model": req["model"], "created_at": final["created_at"], "done": False}, **piece(p))
            self.wfile.write((json.dumps(line, ensure_ascii=False) + "\n").encode())
            self.wfile.flush()
        self.wfile.write((json.dumps(dict(final, **piece(""))) + "\n").encode())


    # -- LM Studio's server, on its own port: the OpenAI shape and one model
    def lmstudio(self, method, path, req, record):
        if method == "GET" and path == "/v1/models":
            return self.send_json(200, {"object": "list", "data": [{"id": "standin-local", "object": "model"}]})
        if method == "POST" and path == "/v1/chat/completions":
            if req.get("model") != "standin-local":
                raise Refusal(404, "model_not_found", f"Model '{req.get('model')}' not found")
            return self.chat(req, {}, record)
        raise Refusal(404, "not_found", f"Unexpected endpoint or method. ({method} {path})")


def main():
    servers = []
    for port in (int(os.environ.get("STANDIN_PORT", "8500")), 11434, 1234):
        srv = ThreadingHTTPServer(("127.0.0.1", port), Handler)
        srv.daemon_threads = True
        servers.append(srv)
        threading.Thread(target=srv.serve_forever, daemon=True).start()
        print(f"standin listening on http://127.0.0.1:{port}", flush=True)
    threading.Event().wait()


if __name__ == "__main__":
    sys.exit(main())
