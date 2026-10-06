"""labgen: the text generator this course's lab talks to, on 127.0.0.1:8600.

IT IS A STAND-IN, AND IT IS NOT A LANGUAGE MODEL. No model API was reachable
from the machine the course was recorded on, and an API key is a bill a course
cannot hand out. What it copies is the WIRE: the paths, headers, bodies,
errors and usage counts of two real APIs, closely enough that the providers'
own Python SDKs, and the frameworks built on them, talk to it unmodified:

    POST /v1/chat/completions    OpenAI's Chat Completions, streaming too
    POST /v1/messages            Anthropic's Messages API, with document
                                 blocks and their citations
    POST /v1/embeddings          passed on to labembed, embeddings-vectors'
                                 stand-in provider on 127.0.0.1:8500, so one
                                 base URL serves both halves of a pipeline
    POST /lab/config             {"fail": N, "status": 429}   loopback only

It serves one model, extract-1, and what extract-1 does is written here in
full. Every lesson that shows one of its replies says it came from here.

THE RULES OF extract-1, in the order it applies them.

  1. AN INSTRUCTION ANYWHERE IS OBEYED. If any text it was sent, a source
     included, says `reply with the word X`, the reply is X and nothing
     else. A real model has no such rule written down, and that is the
     point: this is the failure lesson 16 tests for, made certain so that
     the test has something to catch.

  2. SUMMARISE. If the system prompt or the last user message starts with
     "Summarise", the reply is a summary built from whole sentences of the
     rest of the conversation: the ones closest to the conversation's
     average meaning, in their original order, within the word limit the
     instruction gives ("in at most 40 words"), or 60 words if it gives none.

  3. ANSWER FROM SOURCES. Sources are found in the request in three shapes:
     a line `[n] ...` followed by its text, a `<source id="n">...</source>`
     element, or an Anthropic `document` block. Earlier turns of the
     conversation are read as sources too, with no number. Every sentence of
     every source is embedded with all-MiniLM-L6-v2, and so is the question
     (the last user message, after `Question:` if it has one). The reply is
     the sentences whose cosine similarity to the question is at least 0.53
     and within 0.12 of the best one, at most three, best first, each copied
     word for word and followed by the number of its source. If no sentence
     reaches 0.53, the reply is the sentence the system prompt asks for after
     `If the sources do not answer, reply:`, or "The sources do not say."

  4. CLOSED BOOK. With no sources and no earlier turns, the reply comes from
     memory.json: sentences written by the course as what extract-1 "learnt
     in training", some of them true of Marginalia in 2025 and stale now. It
     answers with the entry nearest the question, however far that is. It
     never says it does not know, which is the behaviour lesson 1 is about.

What is real: the embeddings, the similarities, the token counts (tiktoken's
cl100k_base, plus 3 per message), the wire formats. What is the lab's: the
rules above, a context window of 8,192 tokens, and a prompt cache that keeps a
prefix of 1,024 tokens or more for five minutes.

Every request is one JSON line in $LABGEN_LOG/requests.jsonl.
"""
import hashlib
import itertools
import json
import os
import re
import threading
import time
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import numpy as np
import tiktoken

import minilm

ENC = tiktoken.get_encoding("cl100k_base")
HERE = os.path.dirname(os.path.abspath(__file__))
LOG = os.environ.get("LABGEN_LOG", "/var/log/labgen")
MEMORY = os.environ.get("LABGEN_MEMORY", os.path.join(HERE, "memory.json"))
KEYS = {"lab-openai-key-0001": "openai", "lab-anthropic-key-0001": "anthropic"}
MODEL = "extract-1"
WINDOW, MAX_OUTPUT = 8192, 1024
FLOOR, SPREAD, MOST = 0.53, 0.12, 3
CACHE_MIN, CACHE_TTL = 1024, 300
NOT_FOUND = "The sources do not say."
EMBED_URL = os.environ.get("LABEMBED_URL", "http://127.0.0.1:8500/v1/embeddings")

LOCK = threading.Lock()
COUNTER = itertools.count(1)
CONFIG = {"fail": 0, "status": 429}
CACHE = {}


def log(record):
    os.makedirs(LOG, exist_ok=True)
    with open(os.path.join(LOG, "requests.jsonl"), "a") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")


# ---------------------------------------------------------------- reading the request

def text_of(content):
    if content is None:
        return ""
    if isinstance(content, str):
        return content
    out = []
    for b in content:
        if isinstance(b, str):
            out.append(b)
        elif b.get("type") == "text":
            out.append(b.get("text", ""))
        elif b.get("type") == "document":
            out.append(b.get("source", {}).get("data", ""))
    return "\n".join(out)


def count(system, messages):
    n = len(ENC.encode(text_of(system)))
    for m in messages:
        n += 3 + len(ENC.encode(text_of(m.get("content"))))
    return n


SOURCE_EL = re.compile(r'<source\b[^>]*\bid="([^"]+)"[^>]*>(.*?)</source>', re.S)
SOURCE_LINE = re.compile(r"^\[(\d+)\][^\n]*\n", re.M)


def split_sources(text):
    """[(label, text)] for the sources in TEXT, and TEXT with them taken out."""
    found = [(m.group(1), m.group(2)) for m in SOURCE_EL.finditer(text)]
    if found:
        return found, SOURCE_EL.sub("", text)
    heads = list(SOURCE_LINE.finditer(text))
    if not heads:
        return [], text
    found, tail = [], ""
    for i, m in enumerate(heads):
        end = heads[i + 1].start() if i + 1 < len(heads) else len(text)
        body = text[m.end():end]
        q = re.search(r"^(Question|QUESTION):", body, re.M)
        if q:
            body, tail = body[:q.start()], body[q.start():]
        found.append((m.group(1), body))
    return found, text[:heads[0].start()] + tail


def sentences(text):
    """Whole sentences. Lines of a paragraph are joined first; headings and blank
    lines are dropped, a table row is one sentence, a list item starts a new one."""
    items, buf = [], []
    if text.startswith("---\n") and "\n---\n" in text[4:]:
        text = text[text.index("\n---\n", 4) + 5:]
    for line in text.splitlines():
        raw, line = line, line.strip()
        starts_item = re.match(r"([-*]|\d+(\.\d+)*\.?)\s+", line) and not raw.startswith(("  ", "\t"))
        if not line or line.startswith(("#", "|")) or starts_item:
            if buf:
                items.append(" ".join(buf))
            buf = []
            if line.startswith("|") and not set(line) <= set("|-: "):
                items.append(" ".join(c.strip() for c in line.strip("|").split("|")))
            elif starts_item:
                buf = [re.sub(r"^([-*]|\d+(\.\d+)*\.?)\s+", "", line)]
            continue
        buf.append(line)
    if buf:
        items.append(" ".join(buf))
    out = []
    for item in items:
        out.extend(s for s in re.split(r"(?<=[.!?;])\s+(?=[A-Z0-9\"'(])", item) if len(s.split()) > 2)
    return out


def question_of(text):
    m = re.search(r"(?:^|\n)(?:Question|QUESTION):\s*(.+)", text, re.S)
    return (m.group(1) if m else text).strip()


# ---------------------------------------------------------------- the model

def rule_instruction(everything):
    m = re.search(r"reply (?:only )?with the word \W?(\w+)", everything, re.I)
    return m.group(1) if m else None


def rule_summarise(system, messages):
    instr = text_of(system)
    last = text_of(messages[-1]["content"]) if messages else ""
    head = instr if re.match(r"\s*summari[sz]e", instr, re.I) else last
    if not re.match(r"\s*summari[sz]e", head, re.I):
        return None
    m = re.search(r"in at most (\d+) words", head, re.I)
    limit = int(m.group(1)) if m else 60
    body = [text_of(x["content"]) for x in messages]
    if head is last:
        first, _, after = last.partition("\n")
        body[-1] = after
    sents = [s for t in body for s in sentences(t)]
    if not sents:
        return ""
    v = minilm.embed(sents)
    centre = v.mean(axis=0)
    order = np.argsort(-(v @ centre), kind="stable")
    keep, words = [], 0
    for i in order:
        n = len(sents[i].split())
        if words + n > limit:
            continue
        keep.append(i)
        words += n
    return " ".join(sents[i] for i in sorted(keep))


def rule_sources(system, messages, documents):
    """(reply text, [(sentence, label, doc_index, start, end)]) or None without sources."""
    last = text_of(messages[-1]["content"])
    pool = []  # (sentence, label, doc_index, start, end)
    for k, d in enumerate(documents):
        data = d.get("source", {}).get("data", "")
        for s in sentences(data):
            start = data.find(s)
            pool.append((s, str(k + 1), k, start, start + len(s) if start >= 0 else -1))
    found, rest = split_sources(last)
    for label, body in found:
        pool += [(s, label, None, -1, -1) for s in sentences(body)]
    for label, body in split_sources(text_of(system))[0]:
        pool += [(s, label, None, -1, -1) for s in sentences(body)]
    for m in messages[:-1]:
        pool += [(s, None, None, -1, -1) for s in sentences(text_of(m["content"]))]
    if not pool:
        return None
    q = question_of(rest if found else last)
    qv = minilm.embed([q])[0]
    scores = minilm.embed([p[0] for p in pool]) @ qv
    order = np.argsort(-scores, kind="stable")
    best = float(scores[order[0]])
    if best < FLOOR:
        m = re.search(r"If the sources do not answer, reply:\s*\"?([^\"\n]+)\"?", text_of(system))
        return (m.group(1).strip() if m else NOT_FOUND), []
    chosen = [pool[i] for i in order if scores[i] >= FLOOR and scores[i] >= best - SPREAD][:MOST]
    parts = [s + (f" [{label}]" if label else "") for s, label, *_ in chosen]
    return " ".join(parts), chosen


def rule_memory(question):
    with open(MEMORY) as f:
        memory = json.load(f)
    qv = minilm.embed([question])[0]
    keys = minilm.embed([m["q"] for m in memory])
    return memory[int(np.argmax(keys @ qv))]["a"]


def produce(system, messages, documents=()):
    """(text, rule, cited) for a conversation."""
    everything = "\n".join([text_of(system)] + [text_of(m["content"]) for m in messages]
                           + [d.get("source", {}).get("data", "") for d in documents])
    word = rule_instruction(everything)
    if word:
        return word, "instruction", []
    s = rule_summarise(system, messages)
    if s is not None:
        return s, "summarise", []
    r = rule_sources(system, messages, documents)
    if r is not None:
        return r[0], "sources", r[1]
    return rule_memory(question_of(text_of(messages[-1]["content"]))), "memory", []


def pieces(text):
    return [ENC.decode([t]) for t in ENC.encode(text)]


# ---------------------------------------------------------------- the server

class Refusal(Exception):
    def __init__(self, status, kind, message):
        super().__init__(message)
        self.status, self.kind, self.message = status, kind, message


class Handler(BaseHTTPRequestHandler):
    server_version = "labgen/1.0"
    sys_version = ""
    protocol_version = "HTTP/1.1"

    def log_message(self, *a):
        pass

    def body(self):
        n = int(self.headers.get("Content-Length") or 0)
        try:
            return json.loads(self.rfile.read(n) or b"{}")
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
        self.end_headers()
        self.close_connection = True

    def event(self, name, data):
        line = (f"event: {name}\n" if name else "") + "data: " + json.dumps(data, ensure_ascii=False) + "\n\n"
        self.wfile.write(line.encode())
        self.wfile.flush()

    def gate(self, provider):
        if provider == "anthropic":
            key = self.headers.get("x-api-key")
        else:
            key = (self.headers.get("Authorization") or "").removeprefix("Bearer ").strip()
        if KEYS.get(key) != provider:
            raise Refusal(401, "authentication_error",
                          "invalid x-api-key" if provider == "anthropic" else "Incorrect API key provided")
        with LOCK:
            if CONFIG["fail"]:
                CONFIG["fail"] -= 1
                st = CONFIG["status"]
                raise Refusal(st, "rate_limit_error" if st == 429 else "api_error",
                              "Rate limit reached" if st == 429 else "Internal server error")

    def check(self, model, system, messages, limit):
        if model != MODEL:
            raise Refusal(404, "not_found_error", f"model: {model}")
        if not messages:
            raise Refusal(400, "invalid_request_error", "messages: at least one message is required")
        if limit > MAX_OUTPUT:
            raise Refusal(400, "invalid_request_error",
                          f"max_tokens: {limit} > {MAX_OUTPUT}, the most {MODEL} can write")
        n = count(system, messages)
        if n + limit > WINDOW:
            raise Refusal(400, "invalid_request_error",
                          f"prompt is too long: {n} tokens + {limit} max_tokens > {WINDOW} maximum")
        return n

    def do_GET(self):
        self.n = next(COUNTER)
        self.send_json(200, {"labgen": "ok", "models": [MODEL]})

    def do_POST(self):
        self.n = next(COUNTER)
        path = self.path.split("?")[0]
        provider = "openai" if path.startswith(("/v1/chat", "/v1/embeddings")) else "anthropic"
        record = {"n": self.n, "path": path}
        try:
            if path == "/lab/config":
                if self.client_address[0] != "127.0.0.1":
                    raise Refusal(403, "permission_error", "loopback only")
                with LOCK:
                    CONFIG.update(self.body())
                    if CONFIG.pop("clear_cache", None):
                        CACHE.clear()
                return self.send_json(200, CONFIG)
            req = self.body()
            record["request"] = req
            self.gate(provider)
            if path == "/v1/embeddings":
                return self.forward(req, record)
            if path == "/v1/chat/completions":
                self.chat(req, record)
            elif path == "/v1/messages":
                self.messages(req, record)
            else:
                raise Refusal(404, "not_found_error", f"Not found: {path}")
            record["status"] = 200
        except Refusal as e:
            record["status"], record["error"] = e.status, e.message
            if provider == "openai":
                self.send_json(e.status, {"error": {"message": e.message, "type": e.kind, "code": None}})
            else:
                self.send_json(e.status, {"type": "error", "error": {"type": e.kind, "message": e.message}})
        except (BrokenPipeError, ConnectionResetError):
            record["status"] = "client went away"
        log(record)

    def forward(self, req, record):
        """An embeddings request, sent on to labembed as it came and answered as labembed answered."""
        r = urllib.request.Request(EMBED_URL, data=json.dumps(req).encode(), method="POST", headers={
            "Content-Type": "application/json", "Authorization": self.headers.get("Authorization", "")})
        try:
            with urllib.request.urlopen(r) as resp:
                status, data = resp.status, resp.read()
        except urllib.error.HTTPError as e:
            status, data = e.code, e.read()
        record["status"], record["forwarded"] = status, EMBED_URL
        record.pop("request", None)
        log(record)
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    # -- OpenAI
    def chat(self, req, record):
        msgs = req.get("messages") or []
        system = "\n".join(text_of(m.get("content")) for m in msgs if m.get("role") in ("system", "developer"))
        conv = [{"role": m["role"], "content": text_of(m.get("content"))}
                for m in msgs if m.get("role") in ("user", "assistant")]
        limit = req.get("max_completion_tokens") or req.get("max_tokens") or 256
        n_in = self.check(req.get("model"), system, conv, limit)
        text, rule, _ = produce(system, conv)
        out = pieces(text)
        finish = "stop"
        if len(out) > limit:
            out, finish = out[:limit], "length"
        text = "".join(out)
        usage = {"prompt_tokens": n_in, "completion_tokens": len(out), "total_tokens": n_in + len(out)}
        record.update(model=MODEL, rule=rule, usage=usage)
        cid = "chatcmpl-lab%04d" % self.n
        if not req.get("stream"):
            return self.send_json(200, {"id": cid, "object": "chat.completion", "created": 1791255600,
                                        "model": MODEL, "choices": [{"index": 0, "finish_reason": finish,
                                        "message": {"role": "assistant", "content": text}}], "usage": usage})
        self.start_stream()
        base = {"id": cid, "object": "chat.completion.chunk", "created": 1791255600, "model": MODEL}
        self.event(None, dict(base, choices=[{"index": 0, "delta": {"role": "assistant", "content": ""},
                                              "finish_reason": None}]))
        for p in out:
            time.sleep(0.01)
            self.event(None, dict(base, choices=[{"index": 0, "delta": {"content": p}, "finish_reason": None}]))
        last = dict(base, choices=[{"index": 0, "delta": {}, "finish_reason": finish}])
        if (req.get("stream_options") or {}).get("include_usage"):
            self.event(None, last)
            last = dict(base, choices=[], usage=usage)
        self.event(None, last)
        self.wfile.write(b"data: [DONE]\n\n")

    # -- Anthropic
    def messages(self, req, record):
        if not self.headers.get("anthropic-version"):
            raise Refusal(400, "invalid_request_error", "anthropic-version: header is required")
        if not isinstance(req.get("max_tokens"), int):
            raise Refusal(400, "invalid_request_error", "max_tokens: Field required")
        msgs = req.get("messages") or []
        system = req.get("system")
        documents = [b for b in (msgs[-1].get("content") if msgs and isinstance(msgs[-1].get("content"), list)
                                 else []) if isinstance(b, dict) and b.get("type") == "document"]
        n_in = self.check(req.get("model"), system, msgs, req["max_tokens"])
        conv = [{"role": m["role"], "content": [b for b in m["content"] if b.get("type") != "document"]
                 if isinstance(m["content"], list) else m["content"]} for m in msgs]
        text, rule, cited = produce(system, conv, documents)
        blocks = []
        if documents and cited:
            for s, label, k, start, end in cited:
                d = documents[k] if k is not None else None
                c = []
                if d is not None and (d.get("citations") or {}).get("enabled"):
                    c = [{"type": "char_location", "cited_text": s, "document_index": k,
                          "document_title": d.get("title"), "start_char_index": start, "end_char_index": end}]
                blocks.append({"type": "text", "text": s, **({"citations": c} if c else {})})
                blocks.append({"type": "text", "text": " "})
            blocks = blocks[:-1]
        else:
            blocks = [{"type": "text", "text": text}]
        n_out = sum(len(pieces(b["text"])) for b in blocks)
        usage = {"input_tokens": n_in, "output_tokens": n_out,
                 "cache_creation_input_tokens": 0, "cache_read_input_tokens": 0}
        size, key = self.cached_prefix(system, msgs)
        if key and size >= CACHE_MIN:
            with LOCK:
                hit = CACHE.get(key, 0) > time.time()
                CACHE[key] = time.time() + CACHE_TTL
            usage["cache_read_input_tokens" if hit else "cache_creation_input_tokens"] = size
            usage["input_tokens"] = n_in - size
        record.update(model=MODEL, rule=rule, usage=usage)
        msg = {"id": "msg_lab_%04d" % self.n, "type": "message", "role": "assistant", "model": MODEL,
               "content": blocks, "stop_reason": "end_turn", "stop_sequence": None, "usage": usage}
        if not req.get("stream"):
            return self.send_json(200, msg)
        self.start_stream()
        self.event("message_start", {"type": "message_start", "message": dict(msg, content=[],
                                                                                stop_reason=None)})
        for i, b in enumerate(blocks):
            self.event("content_block_start", {"type": "content_block_start", "index": i,
                                               "content_block": {"type": "text", "text": ""}})
            for p in pieces(b["text"]):
                time.sleep(0.01)
                self.event("content_block_delta", {"type": "content_block_delta", "index": i,
                                                   "delta": {"type": "text_delta", "text": p}})
            for c in b.get("citations", []):
                self.event("content_block_delta", {"type": "content_block_delta", "index": i,
                                                   "delta": {"type": "citations_delta", "citation": c}})
            self.event("content_block_stop", {"type": "content_block_stop", "index": i})
        self.event("message_delta", {"type": "message_delta", "delta": {"stop_reason": "end_turn",
                                     "stop_sequence": None}, "usage": {"output_tokens": n_out}})
        self.event("message_stop", {"type": "message_stop"})

    @staticmethod
    def cached_prefix(system, messages):
        """Tokens up to and including the last block marked cache_control, and a key for them."""
        blocks = [("system", b) for b in system] if isinstance(system, list) else []
        for m in messages:
            c = m.get("content")
            blocks += [(m["role"], b) for b in c] if isinstance(c, list) else [(m["role"], {"type": "text", "text": c})]
        upto = max((i + 1 for i, (_, b) in enumerate(blocks) if isinstance(b, dict) and b.get("cache_control")),
                   default=0)
        if not upto:
            return 0, None
        prefix = "\n".join(r + ":" + text_of([b]) for r, b in blocks[:upto])
        return len(ENC.encode(prefix)), hashlib.sha256(prefix.encode()).hexdigest()


def main():
    port = int(os.environ.get("LABGEN_PORT", "8600"))
    srv = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    srv.daemon_threads = True
    print(f"labgen listening on http://127.0.0.1:{port}", flush=True)
    srv.serve_forever()


if __name__ == "__main__":
    main()
