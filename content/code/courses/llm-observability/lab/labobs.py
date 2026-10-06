"""labobs: the model provider this course's lab talks to, on 127.0.0.1:8600.

IT IS rag's labgen WITH A CLOCK, A SECOND VERSION AND A JUDGE. rag's lab
starts labgen (../rag/lab/labgen.py) on this port; llm-observability's lab.sh
stops it and starts this instead. Everything labgen does is inherited and
unchanged: the wire formats, extract-1's four rules, the token counts, the
forwarding of embeddings to labembed. Read labgen's docstring for those.

IT IS NOT A LANGUAGE MODEL, and neither is anything it serves. No model API
was reachable from the machine the course was recorded on, and an API key is
a bill a course cannot hand out. Every lesson that shows a reply, a latency
or a verdict from it says so.

WHAT THIS FILE ADDS, all of it on OpenAI's Chat Completions only, which is
the only API the assistant in this course calls.

  1. TIME. labgen answers at once. A provider does not, and lessons 4, 5 and
     16 are about the shape of the waiting, so this one waits by these rules,
     which are the course's and not any provider's:

       first token   180 ms, plus 0.12 ms for every input token
       each token    25 ms more for every output token after it
       jitter        both multiplied by one factor per request, drawn from a
                     log-normal with sigma 0.25 by a generator seeded with
                     `seed` (7 unless /lab/config sets another)
       a cold start  with probability `slow_rate` (0.01), 4 s more before the
                     first token

     A request without `stream` waits the whole time and then answers; a
     streamed one sends each token at its moment.

  2. FAILURES. `fail_rate` (0 unless set) is the probability that a request
     is refused before any work, with `fail_status` (503 unless set). The
     inherited `fail`/`status` pair still refuses the next N requests.
     `cut_after` N, when set, ends the next streamed reply after N tokens
     without a finish reason, as a dropped connection would.

  3. extract-2. A second version of extract-1, served beside it, as a
     provider serves a new snapshot of a model. Same rules, three numbers
     changed: it keeps sentences down to a similarity of 0.48 (extract-1:
     0.53), within 0.20 of the best (0.12), and up to four of them (three).
     It answers more questions, and more of what it says is beside the
     point. Lesson 14 is what changing to it does.

  4. judge-1. A grader, for lessons 9 to 12. It reads a request whose system
     prompt names a criterion ("Criterion: faithfulness", "relevance" or
     "correctness") and whose user message carries <question>, <reply>,
     <sources> and, for correctness, <expected>. It answers a JSON object,
     {"criterion", "score", "verdict", "reason"}, decided by these rules,
     with every sentence embedded by all-MiniLM-L6-v2 as labgen does:

       faithfulness  the reply's sentences, citation marks removed; each is
                     supported if its cosine similarity to some sentence of
                     the sources is 0.75 or more. score = the share
                     supported; verdict pass only if all are. A reply with
                     no sentence, or the assistant's refusal, scores 1.
       relevance     the cosine similarity of the question to the whole
                     reply, citation marks removed; pass at 0.40 or more.
       correctness   the cosine similarity of the reply to <expected>; pass
                     at 0.70 or more. If both are the refusal, pass.

     Those thresholds were chosen by the course. The judge has blind spots
     on purpose, as every judge has them by accident: relevance rewards a
     reply that repeats the question's words, and faithfulness cannot tell a
     true sentence copied from the wrong source from a right one. Lesson 10
     measures it against people.

    POST /lab/config  {"seed", "slow_rate", "fail_rate", "fail_status",
                       "cut_after", "fail", "status"}   loopback only;
                      {"reset": true} puts every one back as it starts
"""
import json
import math
import random
import re
import time

import numpy as np

import labgen
import minilm
from labgen import Refusal, count, pieces, sentences, split_sources, question_of, text_of

MODELS = {
    "extract-1": {"floor": 0.53, "spread": 0.12, "most": 3},
    "extract-2": {"floor": 0.48, "spread": 0.20, "most": 4},
    "judge-1": None,
}
FIRST_MS, PER_INPUT_MS, PER_TOKEN_MS, SIGMA, COLD_MS = 180.0, 0.12, 25.0, 0.25, 4000.0
DEFAULTS = {"seed": 7, "slow_rate": 0.01, "fail_rate": 0.0, "fail_status": 503, "cut_after": None,
            "fail": 0, "status": 429}
REFUSAL = "I could not find that in our documents."
SUPPORTED, RELEVANT, CORRECT = 0.75, 0.40, 0.70

labgen.CONFIG.update(DEFAULTS)
RNG = random.Random(DEFAULTS["seed"])


def draw():
    """(factor, cold, fails) for the next request, in the order requests arrive."""
    with labgen.LOCK:
        factor = math.exp(RNG.gauss(0, SIGMA))
        cold = RNG.random() < labgen.CONFIG["slow_rate"]
        fails = RNG.random() < labgen.CONFIG["fail_rate"]
    return factor, cold, fails


# ---------------------------------------------------------------- extract-1 and extract-2

def answer(system, conv, rules):
    """labgen's produce(), with the three numbers of rule 3 taken from RULES."""
    saved = labgen.FLOOR, labgen.SPREAD, labgen.MOST
    with labgen.LOCK:  # labgen reads them as globals; one request at a time sets them
        labgen.FLOOR, labgen.SPREAD, labgen.MOST = rules["floor"], rules["spread"], rules["most"]
        try:
            text, rule, _ = labgen.produce(system, conv)
        finally:
            labgen.FLOOR, labgen.SPREAD, labgen.MOST = saved
    return text, rule


# ---------------------------------------------------------------- judge-1

def tag(text, name):
    m = re.search(rf"<{name}>(.*?)</{name}>", text, re.S)
    return m.group(1).strip() if m else None


def clean(text):
    return re.sub(r"\s*\[\d+\]", "", text).strip()


def judge(system, conv):
    crit = re.search(r"Criterion:\s*(\w+)", system or "")
    last = text_of(conv[-1]["content"]) if conv else ""
    question, reply = tag(last, "question"), tag(last, "reply")
    if not crit or question is None or reply is None:
        raise Refusal(400, "invalid_request_error",
                      "judge-1 needs a system prompt naming a Criterion and <question> and <reply>")
    crit = crit.group(1).lower()
    if crit == "faithfulness":
        claims = [] if reply.startswith(REFUSAL) else [clean(s) for s in sentences(reply)]
        found = split_sources(tag(last, "sources") or "")[0]
        source = [s for _, body in found for s in sentences(body)] or sentences(tag(last, "sources") or "")
        if not claims:
            return {"criterion": crit, "score": 1.0, "verdict": "pass", "reason": "the reply claims nothing"}
        if not source:
            return {"criterion": crit, "score": 0.0, "verdict": "fail", "reason": "no sources to support it"}
        sims = minilm.embed(claims) @ minilm.embed(source).T
        ok = sims.max(axis=1) >= SUPPORTED
        score = round(float(ok.mean()), 2)
        worst = int(np.argmin(sims.max(axis=1)))
        reason = (f"all {len(claims)} sentences are supported" if ok.all() else
                  f"{int((~ok).sum())} of {len(claims)} sentences unsupported, e.g. \"{claims[worst][:80]}\"")
        return {"criterion": crit, "score": score, "verdict": "pass" if ok.all() else "fail", "reason": reason}
    if crit == "relevance":
        v = minilm.embed([question, clean(reply)])
        score = round(float(v[0] @ v[1]), 2)
        return {"criterion": crit, "score": score, "verdict": "pass" if score >= RELEVANT else "fail",
                "reason": f"similarity of question and reply {score:.2f}, threshold {RELEVANT}"}
    if crit == "correctness":
        expected = tag(last, "expected")
        if expected is None:
            raise Refusal(400, "invalid_request_error", "correctness needs <expected>")
        if expected.startswith(REFUSAL) or reply.startswith(REFUSAL):
            same = expected.startswith(REFUSAL) and reply.startswith(REFUSAL)
            return {"criterion": crit, "score": 1.0 if same else 0.0, "verdict": "pass" if same else "fail",
                    "reason": "both refuse" if same else "one refuses and the other answers"}
        v = minilm.embed([clean(reply), expected])
        score = round(float(v[0] @ v[1]), 2)
        return {"criterion": crit, "score": score, "verdict": "pass" if score >= CORRECT else "fail",
                "reason": f"similarity to the expected answer {score:.2f}, threshold {CORRECT}"}
    raise Refusal(400, "invalid_request_error", f"judge-1 knows no criterion called {crit}")


# ---------------------------------------------------------------- the server

class Handler(labgen.Handler):
    server_version = "labobs/1.0"

    def do_POST(self):
        if self.path.split("?")[0] == "/lab/config" and self.client_address[0] == "127.0.0.1":
            n = int(self.headers.get("Content-Length") or 0)
            body = json.loads(self.rfile.read(n) or b"{}")
            with labgen.LOCK:
                if body.pop("reset", None):
                    labgen.CONFIG.update(DEFAULTS)
                    RNG.seed(DEFAULTS["seed"])
                labgen.CONFIG.update(body)
                if "seed" in body:
                    RNG.seed(body["seed"])
            self.n = next(labgen.COUNTER)
            return self.send_json(200, labgen.CONFIG)
        return super().do_POST()

    def do_GET(self):
        self.n = next(labgen.COUNTER)
        self.send_json(200, {"labobs": "ok", "models": list(MODELS)})

    def check(self, model, system, messages, limit):
        """labgen's check, for any of the three models."""
        if model not in MODELS:
            raise Refusal(404, "not_found_error", f"model: {model}")
        if not messages:
            raise Refusal(400, "invalid_request_error", "messages: at least one message is required")
        if limit > labgen.MAX_OUTPUT:
            raise Refusal(400, "invalid_request_error",
                          f"max_tokens: {limit} > {labgen.MAX_OUTPUT}, the most {model} can write")
        n = count(system, messages)
        if n + limit > labgen.WINDOW:
            raise Refusal(400, "invalid_request_error",
                          f"prompt is too long: {n} tokens + {limit} max_tokens > {labgen.WINDOW} maximum")
        return n

    def chat(self, req, record):
        msgs = req.get("messages") or []
        system = "\n".join(text_of(m.get("content")) for m in msgs if m.get("role") in ("system", "developer"))
        conv = [{"role": m["role"], "content": text_of(m.get("content"))}
                for m in msgs if m.get("role") in ("user", "assistant")]
        limit = req.get("max_completion_tokens") or req.get("max_tokens") or 256
        model = req.get("model")
        n_in = self.check(model, system, conv, limit)
        factor, cold, fails = draw()
        if fails:
            st = labgen.CONFIG["fail_status"]
            raise Refusal(st, "rate_limit_error" if st == 429 else "overloaded_error",
                          "Rate limit reached" if st == 429 else "The server is overloaded")
        if model == "judge-1":
            text, rule = json.dumps(judge(system, conv)), "judge"
        else:
            text, rule = answer(system, conv, MODELS[model])
        out = pieces(text)
        finish = "stop"
        if len(out) > limit:
            out, finish = out[:limit], "length"
        text = "".join(out)
        usage = {"prompt_tokens": n_in, "completion_tokens": len(out), "total_tokens": n_in + len(out)}
        first = (FIRST_MS + PER_INPUT_MS * n_in) * factor + (COLD_MS if cold else 0)
        each = PER_TOKEN_MS * factor
        record.update(model=model, rule=rule, usage=usage, first_ms=round(first), cold=cold)
        cid = "chatcmpl-lab%04d" % self.n
        if not req.get("stream"):
            time.sleep((first + each * max(len(out) - 1, 0)) / 1000)
            return self.send_json(200, {"id": cid, "object": "chat.completion", "created": 1791255600,
                                        "model": model, "choices": [{"index": 0, "finish_reason": finish,
                                        "message": {"role": "assistant", "content": text}}], "usage": usage})
        cut = labgen.CONFIG["cut_after"]
        if cut is not None:
            with labgen.LOCK:
                labgen.CONFIG["cut_after"] = None
        self.start_stream()
        base = {"id": cid, "object": "chat.completion.chunk", "created": 1791255600, "model": model}
        time.sleep(first / 1000)
        self.event(None, dict(base, choices=[{"index": 0, "delta": {"role": "assistant", "content": ""},
                                              "finish_reason": None}]))
        for i, p in enumerate(out):
            if cut is not None and i == cut:
                record["cut"] = cut
                return
            if i:
                time.sleep(each / 1000)
            self.event(None, dict(base, choices=[{"index": 0, "delta": {"content": p}, "finish_reason": None}]))
        last = dict(base, choices=[{"index": 0, "delta": {}, "finish_reason": finish}])
        if (req.get("stream_options") or {}).get("include_usage"):
            self.event(None, last)
            last = dict(base, choices=[], usage=usage)
        self.event(None, last)
        self.wfile.write(b"data: [DONE]\n\n")


def main():
    import os
    from http.server import ThreadingHTTPServer
    port = int(os.environ.get("LABGEN_PORT", "8600"))
    srv = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    srv.daemon_threads = True
    print(f"labobs listening on http://127.0.0.1:{port}", flush=True)
    srv.serve_forever()


if __name__ == "__main__":
    main()
