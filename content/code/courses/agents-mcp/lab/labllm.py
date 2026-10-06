"""labllm: the model provider this course's lab talks to, on 127.0.0.1:8600.

IT IS A STAND-IN, AND EVERYTHING IT SAYS ABOUT ITSELF SAYS SO. No model API
was reachable from the machine the course was recorded on, and an API key is
a bill a course cannot hand out. So the agents in the lessons talk to this.
What it copies is the WIRE: the paths, headers, request and response bodies,
error shapes and streaming events of three real APIs, closely enough that the
providers' own SDKs, and the agent SDKs built on them, talk to it unmodified:

    POST /v1/messages                         Anthropic's Messages API
    POST /v1/messages/count_tokens            and its token counter
    POST /v1/chat/completions                 OpenAI's Chat Completions
    POST /v1beta/models/<m>:generateContent   Google's Gemini API
    POST /v1beta/models/<m>:streamGenerateContent

In all three, a model can ask for tools and receive their results: tool_use
and tool_result blocks, tool_calls and the "tool" role, functionCall and
functionResponse parts.

What it does NOT copy is a model. Its two models choose their replies from
rules WRITTEN BY THE COURSE, in lab/scripted/*.json:

    scripted-1      the model every lesson uses
    scripted-mini   the same rules, cheaper and faster per token (lesson 18)

A rule names the conversation it answers (a phrase in the task, the step it
is at, what the last tool returned) and gives the reply: text, one or more
tool calls, or both. Which tool an agent calls, with which arguments, and
what it says at the end are therefore the course's words, and every lesson
that shows one says so. Everything AROUND the model is real: the SDKs, the
loops, the tools, the validation, the MCP servers, the errors, the limits.

Its own rules, where they are not a provider's, are these, and lesson 18
quotes them:

    tokens      counted with o200k_base, plus 3 per message, plus the tool
                definitions as JSON
    window      200000 tokens; at most 32000 out
    time        200 ms before the first token, then 40 ms a token for
                scripted-1 and 10 ms for scripted-mini
    cache       a prefix marked cache_control, of 1024 tokens or more, is
                written once and read for 300 s after

    POST /lab/config   {"rpm": 3, "fail_next": 529, "fail_count": 2}  loopback only
"""
import glob
import hashlib
import itertools
import json
import os
import re
import threading
import time
from collections import deque
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import tiktoken

ENC = tiktoken.get_encoding("o200k_base")
SHARE = os.environ.get("LABLLM_SHARE", "/opt/agents/share")
LOG = os.environ.get("LABLLM_LOG", "/var/log/labllm")
KEYS = {"lab-anthropic-key-0001": "anthropic", "lab-openai-key-0001": "openai",
        "lab-google-key-0001": "google"}
MODELS = {
    "scripted-1": {"window": 200000, "max_output": 32000, "per_token": 0.040},
    "scripted-mini": {"window": 200000, "max_output": 32000, "per_token": 0.010},
}
FIRST_TOKEN = 0.200
CACHE_MIN = 1024
CACHE_TTL = 300

CONFIG = {"rpm": 50, "fail_next": None, "fail_count": 0}
LOCK = threading.Lock()
COUNTER = itertools.count(1)
SEEN = {}   # api key -> deque of request times, for the rate limit
CACHE = {}  # prefix hash -> expiry


def rules():
    out = []
    for path in sorted(glob.glob(os.path.join(SHARE, "scripted", "*.json"))):
        with open(path) as f:
            out += json.load(f)
    return out


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
        if not isinstance(b, dict):
            continue
        t = b.get("type")
        if t == "text":
            out.append(b["text"])
        elif t == "tool_use":
            out.append(b["name"] + json.dumps(b.get("input", {}), ensure_ascii=False))
        elif t == "tool_result":
            out.append(text_of(b.get("content", "")))
    return "\n".join(out)


def parts(system, messages, tools):
    """The request as the counter reads it, in the order the API reads it:
    the tools, then the system prompt, then the messages. Each part is
    (text, marked) where marked says the block carries cache_control."""
    out = [(json.dumps(t, ensure_ascii=False), bool(t.get("cache_control"))) for t in tools or []]
    if isinstance(system, list):
        out += [(text_of([b]), bool(b.get("cache_control"))) for b in system]
    elif system:
        out.append((system, False))
    for m in messages:
        c = m.get("content")
        blocks = c if isinstance(c, list) else [{"type": "text", "text": c or ""}]
        out.append((None, False))  # each message costs 3 tokens of its own
        out += [(text_of([b]), bool(isinstance(b, dict) and b.get("cache_control"))) for b in blocks]
    return out


def tokens(ps):
    return sum(3 if t is None else len(ENC.encode(t)) for t, _ in ps)


def count(system, messages, tools):
    return tokens(parts(system, messages, tools))


def cached_prefix(system, messages, tools):
    """Tokens up to and including the last block marked cache_control, or 0."""
    ps = parts(system, messages, tools)
    upto = max((i + 1 for i, (_, marked) in enumerate(ps) if marked), default=0)
    if not upto:
        return 0, None
    head = ps[:upto]
    return tokens(head), hashlib.sha256(json.dumps([t for t, _ in head]).encode()).hexdigest()


# ---------------------------------------------------------------- the rules

def user_text(messages):
    """The text people wrote: every user message's own text, never a tool's result."""
    out = []
    for m in messages:
        if m["role"] != "user":
            continue
        c = m.get("content")
        if isinstance(c, str):
            out.append(c)
        else:
            out += [b["text"] for b in c or [] if isinstance(b, dict) and b.get("type") == "text"]
    return "\n".join(out)


def scripted(system, messages, tools):
    """The first rule whose conditions all hold. A rule is written by the course.

      task      every phrase appears in what the user wrote (not in tool results)
      system    the phrase appears in the system prompt
      step      this is the Nth model call of the conversation (1 = no reply yet)
      last      every phrase appears in the last message, tool results included
      not_last  none of these phrases appears in the last message
      tools     every one of these tools is offered
      no_tools  no tool is offered
    """
    last = messages[-1] if messages else {}
    last_text = text_of(last.get("content")).lower()
    names = {t.get("name") for t in tools or []}
    sys_text = (text_of(system) if system else "").lower()
    asked = user_text(messages).lower()
    step = 1 + sum(1 for m in messages if m["role"] == "assistant")
    for r in rules():
        w = r.get("when", {})
        if "task" in w and not all(s.lower() in asked for s in w["task"]):
            continue
        if "system" in w and w["system"].lower() not in sys_text:
            continue
        if "step" in w and step != w["step"]:
            continue
        if "last" in w and not all(s.lower() in last_text for s in w["last"]):
            continue
        if "not_last" in w and any(s.lower() in last_text for s in w["not_last"]):
            continue
        if "tools" in w and not set(w["tools"]) <= names:
            continue
        if "no_tools" in w and names:
            continue
        return r
    return {"id": "none", "reply": [{"type": "text", "text":
            "[scripted-1 has no reply written for this conversation]"}]}


def split_text(text):
    """A reply cut into tokens, the way a real one is generated and streamed."""
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
        data = json.dumps(obj, ensure_ascii=False).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("request-id", "req_lab_%04d" % self.n)
        for k, v in (headers or {}).items():
            self.send_header(k, str(v))
        self.end_headers()
        self.wfile.write(data)

    def start_stream(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
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
            key = self.headers.get("x-api-key") or (self.headers.get("Authorization") or "").removeprefix("Bearer ").strip()
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
                raise Refusal(status, "overloaded_error" if status == 529 else
                              "rate_limit_error" if status == 429 else "api_error",
                              "Overloaded" if status == 529 else
                              "Rate limited" if status == 429 else "Internal server error",
                              {"retry-after": 1} if status == 429 else {})
            now = time.time()
            q = SEEN.setdefault(key, deque())
            while q and now - q[0] >= 60:
                q.popleft()
            if len(q) >= CONFIG["rpm"]:
                wait = int(60 - (now - q[0])) + 1
                raise Refusal(429, "rate_limit_error",
                              f"This request would exceed the rate limit of {CONFIG['rpm']} requests per minute.",
                              {"retry-after": wait})
            q.append(now)

    def refuse(self, e, provider):
        if provider == "openai":
            obj = {"error": {"message": e.message, "type": e.kind, "code": None}}
        elif provider == "google":
            obj = {"error": {"code": e.status, "message": e.message,
                             "status": {400: "INVALID_ARGUMENT", 401: "UNAUTHENTICATED", 404: "NOT_FOUND",
                                        429: "RESOURCE_EXHAUSTED", 529: "UNAVAILABLE"}.get(e.status, "INTERNAL")}}
        else:
            obj = {"type": "error", "error": {"type": e.kind, "message": e.message},
                   "request_id": "req_lab_%04d" % self.n}
        self.send_json(e.status, obj, e.headers)

    def do_GET(self):
        self.n = next(COUNTER)
        self.send_json(200, {"labllm": "a stand-in provider; see lab/labllm.py", "models": sorted(MODELS)})

    def do_HEAD(self):
        self.send_response(200)
        self.end_headers()

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
                    if CONFIG.pop("clear", None):
                        SEEN.clear()
                        CACHE.clear()
                return self.send_json(200, dict(CONFIG))
            req = self.body()
            record["request"] = req
            self.gate(provider)
            if path == "/v1/messages":
                self.messages(req, record)
            elif path == "/v1/messages/count_tokens":
                self.check(req, need_max=False)
                n = count(req.get("system"), req["messages"], req.get("tools"))
                record["input_tokens"] = n
                self.send_json(200, {"input_tokens": n})
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

    # -- the model, in Anthropic's terms, which the other two wires are translated into
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
        for k, (a, b) in enumerate(zip(msgs, msgs[1:]), 1):
            if a.get("role") == b.get("role"):
                raise Refusal(400, "invalid_request_error",
                              "messages: roles must alternate between \"user\" and \"assistant\"")
            asked = [x["id"] for x in a.get("content") or [] if isinstance(x, dict) and x.get("type") == "tool_use"]
            given = {x.get("tool_use_id") for x in b.get("content") or [] if isinstance(x, dict) and x.get("type") == "tool_result"}
            missing = [i for i in asked if i not in given]
            if a.get("role") == "assistant" and missing:
                raise Refusal(400, "invalid_request_error",
                              f"messages.{k}: tool_use ids were found without tool_result blocks immediately after: {', '.join(missing)}")
        if need_max and req["max_tokens"] > MODELS[model]["max_output"]:
            raise Refusal(400, "invalid_request_error",
                          f"max_tokens: {req['max_tokens']} > {MODELS[model]['max_output']}, which is the maximum allowed number of output tokens for {model}")
        n = count(req.get("system"), msgs, req.get("tools"))
        if need_max and n + req["max_tokens"] > MODELS[model]["window"]:
            raise Refusal(400, "invalid_request_error",
                          f"prompt is too long: {n} tokens + {req['max_tokens']} max_tokens > {MODELS[model]['window']} maximum")
        return n

    def produce(self, req):
        """The reply as content blocks, each carrying its tokens, and why it stopped.

        A stop sequence ends the reply where it first appears in the text, as it
        does at a provider: the sequence itself is not returned, and nothing
        after it is, tool calls included."""
        r = scripted(req.get("system"), req["messages"], req.get("tools"))
        blocks, used, limit = [], 0, req["max_tokens"]
        reason = "end_turn"
        stops = req.get("stop_sequences") or []
        for b in r["reply"]:
            if b["type"] == "text":
                text, hit = b["text"], None
                for s in stops:
                    k = text.find(s)
                    if k >= 0 and (hit is None or k < text.find(hit)):
                        hit = s
                if hit is not None:
                    blocks.append(("text", split_text(text[:text.find(hit)])))
                    self.stopped_on = hit
                    return blocks, "stop_sequence", r["id"]
                pieces = split_text(text)
                if used + len(pieces) > limit:
                    blocks.append(("text", pieces[:limit - used]))
                    return blocks, "max_tokens", r["id"]
                used += len(pieces)
                blocks.append(("text", pieces))
            else:
                pieces = split_text(json.dumps(b["input"], ensure_ascii=False))
                used += len(pieces)
                blocks.append(("tool_use", b["name"], b["input"], pieces))
                reason = "tool_use"
        return blocks, reason, r["id"]

    def wait(self, model, n_out):
        time.sleep(FIRST_TOKEN + MODELS[model]["per_token"] * n_out)

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

    # -- Anthropic
    def messages(self, req, record):
        n_in = self.check(req)
        blocks, reason, rule = self.produce(req)
        record["model"], record["rule"] = req["model"], rule
        msg_id = "msg_lab_%04d" % self.n
        tool_ids = iter("toolu_lab_%04d_%d" % (self.n, i) for i in range(1, 20))
        n_out = sum(len(b[-1]) for b in blocks)
        usage = self.usage(req, n_in, n_out)
        record["usage"] = usage
        stop_seq = getattr(self, "stopped_on", None) if reason == "stop_sequence" else None
        if not req.get("stream"):
            self.wait(req["model"], n_out)
            content = []
            for b in blocks:
                if b[0] == "text":
                    content.append({"type": "text", "text": "".join(b[1])})
                else:
                    content.append({"type": "tool_use", "id": next(tool_ids), "name": b[1], "input": b[2]})
            return self.send_json(200, {
                "id": msg_id, "type": "message", "role": "assistant", "model": req["model"],
                "content": content, "stop_reason": reason, "stop_sequence": stop_seq, "usage": usage})
        self.start_stream()
        time.sleep(FIRST_TOKEN)
        per = MODELS[req["model"]]["per_token"]
        self.event("message_start", {"type": "message_start", "message": {
            "id": msg_id, "type": "message", "role": "assistant", "model": req["model"], "content": [],
            "stop_reason": None, "stop_sequence": None, "usage": dict(usage, output_tokens=1)}})
        for i, b in enumerate(blocks):
            if b[0] == "text":
                self.event("content_block_start", {"type": "content_block_start", "index": i,
                                                   "content_block": {"type": "text", "text": ""}})
                for p in b[1]:
                    time.sleep(per)
                    self.event("content_block_delta", {"type": "content_block_delta", "index": i,
                                                       "delta": {"type": "text_delta", "text": p}})
            else:
                self.event("content_block_start", {"type": "content_block_start", "index": i, "content_block": {
                    "type": "tool_use", "id": next(tool_ids), "name": b[1], "input": {}}})
                js = "".join(b[3])
                for chunk in [js[k:k + 12] for k in range(0, len(js), 12)]:
                    time.sleep(per)
                    self.event("content_block_delta", {"type": "content_block_delta", "index": i,
                                                       "delta": {"type": "input_json_delta", "partial_json": chunk}})
            self.event("content_block_stop", {"type": "content_block_stop", "index": i})
        self.event("message_delta", {"type": "message_delta", "delta": {"stop_reason": reason, "stop_sequence": stop_seq},
                                     "usage": {"output_tokens": n_out}})
        self.event("message_stop", {"type": "message_stop"})

    # -- OpenAI
    def chat(self, req, record):
        msgs = req.get("messages") or []
        system = "\n".join(text_of(m["content"]) for m in msgs if m.get("role") in ("system", "developer"))
        conv = []

        def add(role, blocks):
            if conv and conv[-1]["role"] == role:
                conv[-1]["content"] += blocks
            else:
                conv.append({"role": role, "content": blocks})
        for m in msgs:
            role = m.get("role")
            if role in ("system", "developer"):
                continue
            if role == "tool":
                add("user", [{"type": "tool_result", "tool_use_id": m.get("tool_call_id"),
                              "content": text_of(m.get("content") or "")}])
            elif role == "assistant":
                blocks = [{"type": "text", "text": text_of(m["content"])}] if m.get("content") else []
                for c in m.get("tool_calls") or []:
                    try:
                        args = json.loads(c["function"].get("arguments") or "{}")
                    except json.JSONDecodeError:
                        args = {}
                    blocks.append({"type": "tool_use", "id": c["id"], "name": c["function"]["name"], "input": args})
                add("assistant", blocks)
            else:
                add("user", [{"type": "text", "text": text_of(m.get("content") or "")}])
        tools = [{"name": t["function"]["name"], "description": t["function"].get("description", ""),
                  "input_schema": t["function"].get("parameters", {})} for t in req.get("tools") or []]
        limit = req.get("max_completion_tokens") or req.get("max_tokens") or 1024
        stop = req.get("stop")
        inner = {"model": req.get("model"), "max_tokens": limit, "messages": conv,
                 "system": system or None, "tools": tools or None,
                 "stop_sequences": [stop] if isinstance(stop, str) else stop}
        n_in = self.check(inner)
        blocks, reason, rule = self.produce(inner)
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
        msg = {"role": "assistant", "content": text}
        if calls:
            msg["tool_calls"] = calls
        if not req.get("stream"):
            self.wait(inner["model"], n_out)
            return self.send_json(200, {"id": cid, "object": "chat.completion", "created": int(time.time()),
                                        "model": inner["model"],
                                        "choices": [{"index": 0, "message": msg, "finish_reason": finish}],
                                        "usage": usage})
        self.start_stream()
        time.sleep(FIRST_TOKEN)
        per = MODELS[inner["model"]]["per_token"]
        base = {"id": cid, "object": "chat.completion.chunk", "created": int(time.time()), "model": inner["model"]}
        self.event(None, dict(base, choices=[{"index": 0, "delta": {"role": "assistant", "content": ""}, "finish_reason": None}]))
        for b in blocks:
            if b[0] == "text":
                for p in b[1]:
                    time.sleep(per)
                    self.event(None, dict(base, choices=[{"index": 0, "delta": {"content": p}, "finish_reason": None}]))
        for k, c in enumerate(calls):
            time.sleep(per)
            self.event(None, dict(base, choices=[{"index": 0, "delta": {"tool_calls": [dict(c, index=k)]}, "finish_reason": None}]))
        self.event(None, dict(base, choices=[{"index": 0, "delta": {}, "finish_reason": finish}]))
        if (req.get("stream_options") or {}).get("include_usage"):
            self.event(None, dict(base, choices=[], usage=usage))
        self.wfile.write(b"data: [DONE]\n\n")

    # -- Google
    def gemini(self, path, req, record):
        m = re.match(r"/v1beta/models/([^:]+):(generateContent|streamGenerateContent)$", path)
        if not m:
            raise Refusal(404, "not_found_error", f"Not found: {path}")
        model, verb = m.groups()
        conv, ids = [], itertools.count(1)
        pending = {}  # function name -> the ids of calls not yet answered

        def add(role, blocks):
            if conv and conv[-1]["role"] == role:
                conv[-1]["content"] += blocks
            else:
                conv.append({"role": role, "content": blocks})
        for c in req.get("contents") or []:
            role = "assistant" if c.get("role") == "model" else "user"
            blocks = []
            for p in c.get("parts", []):
                if "text" in p and not p.get("thought"):
                    blocks.append({"type": "text", "text": p["text"]})
                elif "functionCall" in p:
                    fc = p["functionCall"]
                    cid = fc.get("id") or "fc_%d" % next(ids)
                    pending.setdefault(fc["name"], []).append(cid)
                    blocks.append({"type": "tool_use", "id": cid, "name": fc["name"], "input": fc.get("args", {})})
                elif "functionResponse" in p:
                    fr = p["functionResponse"]
                    cid = fr.get("id") or (pending.get(fr["name"]) or ["fc_?"]).pop(0)
                    blocks.append({"type": "tool_result", "tool_use_id": cid,
                                   "content": json.dumps(fr.get("response", {}), ensure_ascii=False)})
            add(role, blocks)
        si = req.get("systemInstruction") or req.get("system_instruction") or {}
        system = "".join(p.get("text", "") for p in si.get("parts", [])) or None
        tools = []
        for t in req.get("tools") or []:
            for d in t.get("functionDeclarations") or t.get("function_declarations") or []:
                tools.append({"name": d["name"], "description": d.get("description", ""),
                              "input_schema": d.get("parametersJsonSchema") or d.get("parameters_json_schema")
                              or d.get("parameters") or {}})
        cfg = req.get("generationConfig") or req.get("generation_config") or {}
        inner = {"model": model, "max_tokens": cfg.get("maxOutputTokens", 1024), "messages": conv,
                 "system": system, "tools": tools or None}
        n_in = self.check(inner)
        blocks, reason, rule = self.produce(inner)
        record["model"], record["rule"] = model, rule
        n_out = sum(len(b[-1]) for b in blocks)
        finish = "MAX_TOKENS" if reason == "max_tokens" else "STOP"
        usage = {"promptTokenCount": n_in, "candidatesTokenCount": n_out, "totalTokenCount": n_in + n_out}
        record["usage"] = usage
        parts = []
        for k, b in enumerate(blocks, 1):
            if b[0] == "text":
                parts.append({"text": "".join(b[1])})
            else:
                parts.append({"functionCall": {"id": "fc_lab_%04d_%d" % (self.n, k), "name": b[1], "args": b[2]}})

        def resp(ps, fin):
            c = {"content": {"role": "model", "parts": ps}, "index": 0}
            if fin:
                c["finishReason"] = fin
            return {"candidates": [c], "usageMetadata": usage, "modelVersion": model,
                    "responseId": "resp_lab_%04d" % self.n}
        if verb == "generateContent":
            self.wait(model, n_out)
            return self.send_json(200, resp(parts, finish))
        self.start_stream()
        time.sleep(FIRST_TOKEN)
        for k, p in enumerate(parts):
            time.sleep(MODELS[model]["per_token"] * len(blocks[k][-1]))
            self.event(None, resp([p], finish if k == len(parts) - 1 else None))


def main():
    host, port = "127.0.0.1", int(os.environ.get("LABLLM_PORT", "8600"))
    srv = ThreadingHTTPServer((host, port), Handler)
    srv.daemon_threads = True
    print(f"labllm listening on http://{host}:{port}", flush=True)
    srv.serve_forever()


if __name__ == "__main__":
    main()
