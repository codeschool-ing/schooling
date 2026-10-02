"""labllm: the model provider this course's lab talks to, on 127.0.0.1:8400.

IT IS A STAND-IN, AND EVERYTHING IT SAYS ABOUT ITSELF SAYS SO. No model API
was reachable from the machine the course was recorded on, so the SDKs in the
lessons talk to this instead. What it copies is the WIRE: the paths, headers,
request bodies, response bodies, error shapes and streaming events of three
real APIs, closely enough that the providers' own Python SDKs talk to it
unmodified:

    POST /v1/messages                         Anthropic's Messages API
    POST /v1/messages/count_tokens            and its token counter
    POST /v1/chat/completions                 OpenAI's Chat Completions
    POST /v1beta/models/<m>:generateContent   Google's Gemini API
    POST /v1beta/models/<m>:streamGenerateContent

What it does NOT copy is a model. It serves two, and neither is a large
language model:

    tiny-1      generates for real, with tinylm: a table of which token
                followed which in a corpus. Its text is real output and
                mostly nonsense, which is the point of lesson 1.
    scripted-1  replies with text WRITTEN BY THE COURSE, chosen by the rules in
                scripted.json. Every lesson that shows one of its replies
                says so. It exists so that the code AROUND a model (the tool
                loop, validation, citations, streaming) can run for real.

Its rules, where they are its own and not a provider's, are written below and
named in the lessons: the context window of each model, a token counted with
o200k_base plus 3 per message, a cache that needs 1024 tokens, 40 ms a token.

    POST /lab/config   {"rpm": 3, "fail_next": 529, ...}   loopback only
"""
import hashlib
import itertools
import json
import os
import re
import sys
import threading
import time
from collections import deque
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import tiktoken

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from tinylm import TinyLM  # noqa: E402

ENC = tiktoken.get_encoding("o200k_base")
SHARE = os.environ.get("LABLLM_SHARE", "/opt/aidev/share")
LOG = os.environ.get("LABLLM_LOG", "/var/log/labllm")
KEYS = {"lab-anthropic-key-0001": "anthropic", "lab-openai-key-0001": "openai",
        "lab-google-key-0001": "google"}
MODELS = {
    "tiny-1": {"window": 2048, "max_output": 512},
    "scripted-1": {"window": 32768, "max_output": 4096},
}
PER_TOKEN = 0.040  # seconds a token takes to "generate"
CACHE_MIN = 1024
CACHE_TTL = 300

TINY = TinyLM.load(os.path.join(SHARE, "tiny.json"))
CONFIG = {"rpm": 50, "fail_next": None, "fail_count": 0, "stream_error_after": None}
LOCK = threading.Lock()
COUNTER = itertools.count(1)
SEEN = {}  # api key -> deque of request times, for the rate limit
CACHE = {}  # prefix hash -> expiry


def rules():
    with open(os.path.join(SHARE, "scripted.json")) as f:
        return json.load(f)


def log(record):
    os.makedirs(LOG, exist_ok=True)
    with open(os.path.join(LOG, "requests.jsonl"), "a") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")


# ---------------------------------------------------------------- counting

def text_of(content):
    """Every piece of text in a message's content, the way the counter sees it."""
    if isinstance(content, str):
        return content
    out = []
    for b in content or []:
        t = b.get("type")
        if t == "text":
            out.append(b["text"])
        elif t == "tool_use":
            out.append(b["name"] + json.dumps(b.get("input", {}), ensure_ascii=False))
        elif t == "tool_result":
            out.append(text_of(b.get("content", "")))
        elif t == "document":
            out.append(text_of(b.get("source", {}).get("data", "")))
    return "\n".join(out)


def count(system, messages, tools):
    n = len(ENC.encode(text_of(system) if system else ""))
    for m in messages:
        n += 3 + len(ENC.encode(text_of(m.get("content"))))
    if tools:
        n += len(ENC.encode(json.dumps(tools, ensure_ascii=False)))
    return n


def cached_prefix(system, messages, tools):
    """Tokens up to and including the last block marked cache_control, or 0."""
    parts, upto = [], 0
    blocks = []
    if isinstance(system, list):
        blocks += [("system", b) for b in system]
    for m in messages:
        if isinstance(m.get("content"), list):
            blocks += [(m["role"], b) for b in m["content"]]
        else:
            blocks.append((m["role"], {"type": "text", "text": m.get("content", "")}))
    for i, (role, b) in enumerate(blocks):
        parts.append(role + ":" + text_of([b]))
        if isinstance(b, dict) and b.get("cache_control"):
            upto = i + 1
    if not upto:
        return 0, None
    prefix = "\n".join(parts[:upto])
    return len(ENC.encode(prefix)), hashlib.sha256(prefix.encode()).hexdigest()


# ---------------------------------------------------------------- the models

def last_user_text(messages):
    for m in reversed(messages):
        if m["role"] == "user":
            return text_of(m["content"])
    return ""


def scripted(system, messages, tools):
    """The first rule whose conditions all hold. A rule is written by the course."""
    last = messages[-1] if messages else {}
    last_text = text_of(last.get("content"))
    results = [b for b in (last.get("content") or []) if isinstance(b, dict) and b.get("type") == "tool_result"]
    names = {t.get("name") for t in tools or []}
    sys_text = text_of(system) if system else ""
    whole = "\n".join(text_of(m.get("content")) for m in messages)
    turns = sum(1 for m in messages if m["role"] == "assistant")
    for r in rules():
        w = r.get("when", {})
        if "contains" in w and not all(s.lower() in last_text.lower() for s in w["contains"]):
            continue
        if "anywhere" in w and not all(s.lower() in whole.lower() for s in w["anywhere"]):
            continue
        if "system" in w and w["system"].lower() not in sys_text.lower():
            continue
        if "tool" in w and w["tool"] not in names:
            continue
        if "no_tools" in w and names:
            continue
        if "not_tool" in w and w["not_tool"] in names:
            continue
        if "after_tool" in w and not results:
            continue
        if "turns" in w and turns != w["turns"]:
            continue
        return r
    return {"id": "none", "reply": [{"type": "text", "text":
            "[scripted-1 has no reply written for this conversation]"}]}


def tiny_pieces(prompt, max_tokens, temperature, top_p, stop):
    seed = int(hashlib.sha256(prompt.encode()).hexdigest()[:8], 16)
    return list(TINY.generate(prompt, max_tokens=max_tokens,
                              temperature=1.0 if temperature is None else temperature,
                              top_p=1.0 if top_p is None else top_p,
                              seed=seed, stop=tuple(stop or ())))


def split_text(text):
    """A scripted reply streamed token by token, the way a real one arrives."""
    return [ENC.decode([t]) for t in ENC.encode(text)]


# ---------------------------------------------------------------- the server

class Refusal(Exception):
    def __init__(self, status, kind, message, headers=None):
        super().__init__(message)
        self.status, self.kind, self.message, self.headers = status, kind, message, headers or {}


class Handler(BaseHTTPRequestHandler):
    server_version = "labllm/1.0"
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
        data = json.dumps(obj, ensure_ascii=False, indent=None).encode()
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
        self.send_header("request-id", "req_lab_%04d" % self.n)
        self.end_headers()
        self.close_connection = True

    def event(self, name, data):
        line = (f"event: {name}\n" if name else "") + "data: " + json.dumps(data, ensure_ascii=False) + "\n\n"
        self.wfile.write(line.encode())
        self.wfile.flush()

    def gate(self, provider):
        """Authentication, the injected failures and the rate limit, in that order."""
        if provider == "anthropic":
            key = self.headers.get("x-api-key")
        elif provider == "openai":
            key = (self.headers.get("Authorization") or "").removeprefix("Bearer ").strip() or None
        else:
            key = self.headers.get("x-goog-api-key")
        if KEYS.get(key) != provider:
            raise Refusal(401, "authentication_error", "invalid x-api-key" if provider == "anthropic"
                          else "Incorrect API key provided" if provider == "openai" else "API key not valid")
        if provider == "anthropic" and not self.headers.get("anthropic-version"):
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
            if len(q) >= CONFIG["rpm"]:
                wait = int(60 - (now - q[0])) + 1
                raise Refusal(429, "rate_limit_error",
                              f"This request would exceed the rate limit of {CONFIG['rpm']} requests per minute.",
                              {"retry-after": wait, "anthropic-ratelimit-requests-limit": CONFIG["rpm"],
                               "anthropic-ratelimit-requests-remaining": 0})
            q.append(now)
            remaining = CONFIG["rpm"] - len(q)
        return {"anthropic-ratelimit-requests-limit": CONFIG["rpm"],
                "anthropic-ratelimit-requests-remaining": remaining}

    def refuse(self, e, provider):
        if provider == "openai":
            obj = {"error": {"message": e.message, "type": e.kind, "code": None}}
        elif provider == "google":
            obj = {"error": {"code": e.status, "message": e.message,
                             "status": {400: "INVALID_ARGUMENT", 401: "UNAUTHENTICATED",
                                        429: "RESOURCE_EXHAUSTED"}.get(e.status, "INTERNAL")}}
        else:
            obj = {"type": "error", "error": {"type": e.kind, "message": e.message},
                   "request_id": "req_lab_%04d" % self.n}
        self.send_json(e.status, obj, e.headers)

    def do_POST(self):
        self.n = next(COUNTER)
        path = self.path.split("?")[0]
        provider = "openai" if path.startswith("/v1/chat") else "google" if path.startswith("/v1beta") else "anthropic"
        started = time.time()
        record = {"n": self.n, "at": time.strftime("%H:%M:%S"), "path": path}
        try:
            if path == "/lab/config":
                if self.client_address[0] != "127.0.0.1":
                    raise Refusal(403, "permission_error", "loopback only")
                with LOCK:
                    CONFIG.update(self.body())
                    if CONFIG.get("fail_next") and not CONFIG.get("fail_count"):
                        CONFIG["fail_count"] = 1
                    if CONFIG.get("clear"):
                        SEEN.clear(); CACHE.clear(); CONFIG.pop("clear")
                return self.send_json(200, {k: v for k, v in CONFIG.items()})
            req = self.body()
            record["request"] = req
            headers = self.gate(provider)
            if path == "/v1/messages":
                self.messages(req, headers, record)
            elif path == "/v1/messages/count_tokens":
                self.check(req, need_max=False)
                n = count(req.get("system"), req["messages"], req.get("tools"))
                record["input_tokens"] = n
                self.send_json(200, {"input_tokens": n}, headers)
            elif path == "/v1/chat/completions":
                self.chat(req, record)
            elif path.startswith("/v1beta/models/"):
                self.gemini(path, req, record)
            else:
                raise Refusal(404, "not_found_error", f"Not found: {path}")
            record["status"] = 200
        except Refusal as e:
            record["status"] = e.status
            record["error"] = e.message
            self.refuse(e, provider)
        except (BrokenPipeError, ConnectionResetError):
            record["status"] = "client went away"
        record["ms"] = int((time.time() - started) * 1000)
        log(record)

    # -- Anthropic
    def check(self, req, need_max=True):
        model = req.get("model")
        if model not in MODELS:
            raise Refusal(404, "not_found_error", f"model: {model}")
        if need_max and not isinstance(req.get("max_tokens"), int):
            raise Refusal(400, "invalid_request_error", "max_tokens: Field required")
        msgs = req.get("messages")
        if not isinstance(msgs, list) or not msgs:
            raise Refusal(400, "invalid_request_error", "messages: at least one message is required")
        if msgs[0].get("role") != "user":
            raise Refusal(400, "invalid_request_error", "messages: the first message must use the \"user\" role")
        for a, b in zip(msgs, msgs[1:]):
            if a.get("role") == b.get("role"):
                raise Refusal(400, "invalid_request_error", "messages: roles must alternate between \"user\" and \"assistant\"")
        for k, (a, b) in enumerate(zip(msgs, msgs[1:]), 1):
            asked = [x["id"] for x in a.get("content") or [] if isinstance(x, dict) and x.get("type") == "tool_use" and x.get("id")]
            given = {x.get("tool_use_id") for x in b.get("content") or [] if isinstance(x, dict) and x.get("type") == "tool_result"}
            missing = [i for i in asked if i not in given]
            if a.get("role") == "assistant" and missing:
                raise Refusal(400, "invalid_request_error",
                              f"messages.{k}: tool_use ids without a tool_result in the next message: {', '.join(missing)}")
        if "output_config" in req:
            raise Refusal(400, "invalid_request_error",
                          "output_config: labllm does not constrain its output; validate the reply yourself")
        if need_max and req["max_tokens"] > MODELS[model]["max_output"]:
            raise Refusal(400, "invalid_request_error",
                          f"max_tokens: {req['max_tokens']} > {MODELS[model]['max_output']}, which is the maximum allowed number of output tokens for {model}")
        n = count(req.get("system"), msgs, req.get("tools"))
        if need_max and n + req["max_tokens"] > MODELS[model]["window"]:
            raise Refusal(400, "invalid_request_error",
                          f"prompt is too long: {n} tokens + {req['max_tokens']} max_tokens > {MODELS[model]['window']} maximum")
        return n

    def produce(self, req):
        """The reply as a list of content blocks, each a list of pieces, and why it stopped."""
        model, msgs = req["model"], req["messages"]
        limit = req["max_tokens"]
        if model == "tiny-1":
            prompt = (text_of(req.get("system")) + "\n" if req.get("system") else "") + last_user_text(msgs)
            pieces = tiny_pieces(prompt, limit, req.get("temperature"), req.get("top_p"), req.get("stop_sequences"))
            text = "".join(pieces)
            stop = None
            for s in req.get("stop_sequences") or []:
                if s in text:
                    stop, text = s, text[:text.index(s)]
                    pieces = split_text(text)
                    break
            reason = "stop_sequence" if stop else ("max_tokens" if len(pieces) >= limit else "end_turn")
            return [("text", pieces)], reason, stop, "none"
        r = scripted(req.get("system"), msgs, req.get("tools"))
        blocks, used = [], 0
        reason = r.get("stop_reason", "end_turn")
        for b in r["reply"]:
            if b["type"] == "text":
                pieces = split_text(b["text"])
                if used + len(pieces) > limit:
                    blocks.append(("text", pieces[:limit - used]))
                    return blocks, "max_tokens", None, r["id"]
                used += len(pieces)
                blocks.append(("text", pieces))
            else:
                js = json.dumps(b["input"], ensure_ascii=False)
                pieces = split_text(js)
                used += len(pieces)
                blocks.append(("tool_use", b["name"], b["input"], pieces))
                reason = "tool_use"
        return blocks, reason, None, r["id"]

    def usage(self, req, n_in, n_out):
        u = {"input_tokens": n_in, "output_tokens": n_out,
             "cache_creation_input_tokens": 0, "cache_read_input_tokens": 0}
        size, key = cached_prefix(req.get("system"), req["messages"], req.get("tools"))
        if key and size >= CACHE_MIN:
            with LOCK:
                hit = CACHE.get(key, 0) > time.time()
                CACHE[key] = time.time() + CACHE_TTL
            u["cache_read_input_tokens" if hit else "cache_creation_input_tokens"] = size
            u["input_tokens"] = n_in - size
        return u

    def messages(self, req, headers, record):
        n_in = self.check(req)
        blocks, reason, stop, rule = self.produce(req)
        record["model"], record["rule"] = req["model"], rule
        msg_id = "msg_lab_%04d" % self.n
        tool_ids = iter("toolu_lab_%04d_%d" % (self.n, i) for i in range(1, 10))
        n_out = sum(len(b[-1]) for b in blocks)
        usage = self.usage(req, n_in, n_out)
        record["usage"] = usage
        if not req.get("stream"):
            time.sleep(PER_TOKEN * n_out)
            content = []
            for b in blocks:
                if b[0] == "text":
                    content.append({"type": "text", "text": "".join(b[1])})
                else:
                    content.append({"type": "tool_use", "id": next(tool_ids), "name": b[1], "input": b[2]})
            return self.send_json(200, {
                "id": msg_id, "type": "message", "role": "assistant", "model": req["model"],
                "content": content, "stop_reason": reason, "stop_sequence": stop, "usage": usage}, headers)
        self.start_stream()
        start_usage = dict(usage, output_tokens=1)
        self.event("message_start", {"type": "message_start", "message": {
            "id": msg_id, "type": "message", "role": "assistant", "model": req["model"], "content": [],
            "stop_reason": None, "stop_sequence": None, "usage": start_usage}})
        sent = 0
        for i, b in enumerate(blocks):
            if b[0] == "text":
                self.event("content_block_start", {"type": "content_block_start", "index": i,
                                                   "content_block": {"type": "text", "text": ""}})
                if i == 0:
                    self.event("ping", {"type": "ping"})
                for p in b[1]:
                    time.sleep(PER_TOKEN)
                    if CONFIG["stream_error_after"] is not None and sent >= CONFIG["stream_error_after"]:
                        CONFIG["stream_error_after"] = None
                        record["stream_error_after"] = sent
                        self.event("error", {"type": "error", "error": {"type": "overloaded_error", "message": "Overloaded"}})
                        return
                    self.event("content_block_delta", {"type": "content_block_delta", "index": i,
                                                       "delta": {"type": "text_delta", "text": p}})
                    sent += 1
                    record["sent"] = sent
            else:
                self.event("content_block_start", {"type": "content_block_start", "index": i, "content_block": {
                    "type": "tool_use", "id": next(tool_ids), "name": b[1], "input": {}}})
                js = "".join(b[3])
                for chunk in [js[k:k + 12] for k in range(0, len(js), 12)]:
                    time.sleep(PER_TOKEN)
                    self.event("content_block_delta", {"type": "content_block_delta", "index": i,
                                                       "delta": {"type": "input_json_delta", "partial_json": chunk}})
            self.event("content_block_stop", {"type": "content_block_stop", "index": i})
        self.event("message_delta", {"type": "message_delta", "delta": {"stop_reason": reason, "stop_sequence": stop},
                                     "usage": {"output_tokens": n_out}})
        self.event("message_stop", {"type": "message_stop"})

    # -- OpenAI
    def chat(self, req, record):
        msgs = req.get("messages") or []
        system = "\n".join(text_of(m["content"]) for m in msgs if m.get("role") in ("system", "developer"))
        conv = []
        for m in msgs:
            if m.get("role") in ("system", "developer"):
                continue
            role = "user" if m["role"] in ("user", "tool") else "assistant"
            content = m.get("content") or ""
            if m["role"] == "tool":
                content = [{"type": "tool_result", "tool_use_id": m.get("tool_call_id"), "content": content}]
            if conv and conv[-1]["role"] == role:
                conv[-1]["content"] = text_of(conv[-1]["content"]) + "\n" + text_of(content)
            else:
                conv.append({"role": role, "content": content})
        tools = [{"name": t["function"]["name"], "description": t["function"].get("description", ""),
                  "input_schema": t["function"].get("parameters", {})} for t in req.get("tools") or []]
        limit = req.get("max_completion_tokens") or req.get("max_tokens") or 256
        inner = {"model": req.get("model"), "max_tokens": limit, "messages": conv, "system": system or None,
                 "tools": tools or None, "temperature": req.get("temperature"), "top_p": req.get("top_p"),
                 "stop_sequences": [req["stop"]] if isinstance(req.get("stop"), str) else req.get("stop")}
        n_in = self.check(inner)
        blocks, reason, _, rule = self.produce(inner)
        record["model"], record["rule"] = inner["model"], rule
        n_out = sum(len(b[-1]) for b in blocks)
        text = "".join("".join(b[1]) for b in blocks if b[0] == "text") or None
        calls = [{"id": "call_lab_%04d_%d" % (self.n, i), "type": "function",
                  "function": {"name": b[1], "arguments": json.dumps(b[2], ensure_ascii=False)}}
                 for i, b in enumerate(blocks, 1) if b[0] == "tool_use"]
        finish = {"end_turn": "stop", "stop_sequence": "stop", "max_tokens": "length", "tool_use": "tool_calls"}[reason]
        usage = {"prompt_tokens": n_in, "completion_tokens": n_out, "total_tokens": n_in + n_out}
        record["usage"] = usage
        cid = "chatcmpl-lab%04d" % self.n
        if not req.get("stream"):
            time.sleep(PER_TOKEN * n_out)
            msg = {"role": "assistant", "content": text}
            if calls:
                msg["tool_calls"] = calls
            return self.send_json(200, {"id": cid, "object": "chat.completion", "created": int(time.time()),
                                        "model": inner["model"],
                                        "choices": [{"index": 0, "message": msg, "finish_reason": finish}],
                                        "usage": usage})
        self.start_stream()
        base = {"id": cid, "object": "chat.completion.chunk", "created": int(time.time()), "model": inner["model"]}
        self.event(None, dict(base, choices=[{"index": 0, "delta": {"role": "assistant", "content": ""}, "finish_reason": None}]))
        for b in blocks:
            if b[0] == "text":
                for p in b[1]:
                    time.sleep(PER_TOKEN)
                    self.event(None, dict(base, choices=[{"index": 0, "delta": {"content": p}, "finish_reason": None}]))
        self.event(None, dict(base, choices=[{"index": 0, "delta": {}, "finish_reason": finish}]))
        self.wfile.write(b"data: [DONE]\n\n")

    # -- Google
    def gemini(self, path, req, record):
        m = re.match(r"/v1beta/models/([^:]+):(generateContent|streamGenerateContent)$", path)
        if not m:
            raise Refusal(404, "not_found_error", f"Not found: {path}")
        model, verb = m.groups()
        conv = []
        for c in req.get("contents") or []:
            role = "assistant" if c.get("role") == "model" else "user"
            conv.append({"role": role, "content": "".join(p.get("text", "") for p in c.get("parts", []))})
        si = req.get("systemInstruction") or req.get("system_instruction") or {}
        system = "".join(p.get("text", "") for p in si.get("parts", [])) or None
        cfg = req.get("generationConfig") or req.get("generation_config") or {}
        inner = {"model": model, "max_tokens": cfg.get("maxOutputTokens", 256), "messages": conv, "system": system,
                 "temperature": cfg.get("temperature"), "top_p": cfg.get("topP"),
                 "stop_sequences": cfg.get("stopSequences")}
        n_in = self.check(inner)
        blocks, reason, _, rule = self.produce(inner)
        record["model"], record["rule"] = model, rule
        n_out = sum(len(b[-1]) for b in blocks)
        finish = {"max_tokens": "MAX_TOKENS"}.get(reason, "STOP")
        usage = {"promptTokenCount": n_in, "candidatesTokenCount": n_out, "totalTokenCount": n_in + n_out}
        record["usage"] = usage
        text = "".join("".join(b[1]) for b in blocks if b[0] == "text")

        def resp(t, fin):
            c = {"content": {"role": "model", "parts": [{"text": t}]}, "index": 0}
            if fin:
                c["finishReason"] = fin
            return {"candidates": [c], "usageMetadata": usage, "modelVersion": model}
        if verb == "generateContent":
            time.sleep(PER_TOKEN * n_out)
            return self.send_json(200, resp(text, finish))
        self.start_stream()
        pieces = [p for b in blocks if b[0] == "text" for p in b[1]]
        for k, p in enumerate(pieces):
            time.sleep(PER_TOKEN)
            self.event(None, resp(p, finish if k == len(pieces) - 1 else None))


def main():
    host, port = "127.0.0.1", int(os.environ.get("LABLLM_PORT", "8400"))
    srv = ThreadingHTTPServer((host, port), Handler)
    srv.daemon_threads = True
    print(f"labllm listening on http://{host}:{port}", flush=True)
    srv.serve_forever()


if __name__ == "__main__":
    main()
