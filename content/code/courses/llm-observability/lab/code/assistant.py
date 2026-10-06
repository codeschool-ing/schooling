"""assistant.py: Marginalia's help assistant, rag's pipeline with a span on every step.

    python assistant.py [--user ID] [--feature help|order|summary] "QUESTION"

It is rag lesson 9's rag.py, changed in three ways: every step is a span
(lesson 1), what a person typed is redacted before it is recorded (lesson 2),
and the model's reply is streamed, with the retries in this file rather than
inside the SDK, so each attempt is a span of its own (lesson 4).
"""
import json
import os
import re
import time
from datetime import datetime

import psycopg
from openai import APIError, OpenAI
from pgvector.psycopg import register_vector

import redact
import telemetry
from telemetry import event, span

RELEASES = json.load(open("releases.json"))
REFUSAL = "I could not find that in our documents."
SYSTEM = """You answer questions from Marginalia's customers, using only the numbered sources.
Cite every sentence with the number of the source it comes from, like [1].
If the sources do not answer the question, reply: "I could not find that in our documents."
If two sources disagree, prefer the one updated most recently, and say so."""
ATTEMPTS = 3

client = OpenAI(max_retries=0, timeout=20)
db = psycopg.connect(autocommit=True)
register_vector(db)


class IncompleteReply(Exception):
    """The stream ended without a finish reason: the connection dropped mid-answer."""


def release_at(at):
    """The release in force at AT, an ISO time: the latest whose `from` is not after it."""
    live = [(r["from"], name) for name, r in RELEASES.items() if r["from"] <= at]
    name = max(live)[1]
    return name, RELEASES[name]


def retrieve(question, cfg):
    with span("embed", **{"gen_ai.operation.name": "embeddings", "gen_ai.request.model": "lab-minilm"}) as s:
        r = client.embeddings.create(model="lab-minilm", input=[question])
        s.set_attribute("gen_ai.usage.input_tokens", r.usage.prompt_tokens)
    with span("search", **{"db.system.name": "postgresql", "app.search.k": cfg["k"],
                           "app.search.floor": cfg["floor"]}) as s:
        rows = db.execute(
            "SELECT id, path, text, updated, 1 - (embedding <=> %s::vector) AS score FROM chunks"
            " WHERE status = 'current' AND audience = 'public'"
            " ORDER BY embedding <=> %s::vector LIMIT %s",
            (r.data[0].embedding, r.data[0].embedding, cfg["k"])).fetchall()
        kept = [row for row in rows if row[4] >= cfg["floor"]]
        s.set_attribute("app.search.returned", len(rows))
        s.set_attribute("app.search.kept", len(kept))
        if rows:
            s.set_attribute("app.search.top_score", round(rows[0][4], 3))
        s.set_attribute("app.search.chunks", [row[0] for row in kept])
    return kept


def chat(model, messages, max_tokens):
    """One attempt: a streamed completion, with the time to its first token."""
    with span(f"chat {model}", **{"gen_ai.operation.name": "chat", "gen_ai.provider.name": "openai",
                                  "gen_ai.request.model": model, "gen_ai.request.max_tokens": max_tokens}) as s:
        started, first, parts, finish, usage = time.monotonic(), None, [], None, None
        stream = client.chat.completions.create(model=model, max_tokens=max_tokens, messages=messages,
                                                stream=True, stream_options={"include_usage": True})
        for chunk in stream:
            if chunk.usage:
                usage = chunk.usage
            for c in chunk.choices:
                if c.delta.content:
                    if first is None:
                        first = time.monotonic()
                        event("gen_ai.first_token")
                    parts.append(c.delta.content)
                finish = c.finish_reason or finish
        if first is not None:
            s.set_attribute("app.time_to_first_token_ms", round((first - started) * 1000))
        if usage:
            s.set_attribute("gen_ai.usage.input_tokens", usage.prompt_tokens)
            s.set_attribute("gen_ai.usage.output_tokens", usage.completion_tokens)
        if finish is None:
            s.set_attribute("app.partial_pieces", len(parts))
            raise IncompleteReply(f"stream ended after {len(parts)} pieces with no finish reason")
        s.set_attribute("gen_ai.response.model", chunk.model)
        s.set_attribute("gen_ai.response.finish_reasons", [finish])
        return "".join(parts)


def generate(messages, model, max_tokens=300):
    """chat(), tried up to ATTEMPTS times on a provider error, one span per attempt."""
    with span("generate") as s:
        for attempt in range(1, ATTEMPTS + 1):
            s.set_attribute("app.attempts", attempt)
            try:
                return chat(model, messages, max_tokens)
            except (APIError, IncompleteReply) as e:
                if attempt == ATTEMPTS:
                    raise
                time.sleep(0.5 * 2 ** (attempt - 1))


def ask(question, user="anonymous", session=None, feature="help", at=None):
    at = at or datetime.now().isoformat(timespec="seconds")
    release, cfg = release_at(at)
    with span("ask", **{"app.feature": feature, "app.release": release, "gen_ai.request.model": cfg["model"],
                        "user.hash": redact.pseudonym(user), "session.id": session or "",
                        "app.question": redact.redact(question)}) as root:
        if feature == "summary":
            reply = generate([{"role": "user", "content": question}], cfg["model"], max_tokens=120)
            outcome, sources = "summarised", []
        else:
            sources = retrieve(question, cfg)
            if not sources:
                reply, outcome = REFUSAL, "refused"
            else:
                numbered = "\n\n".join(f"[{n}] {path} (updated {updated})\n{text}"
                                       for n, (_, path, text, updated, _) in enumerate(sources, 1))
                reply = generate([{"role": "system", "content": SYSTEM},
                                  {"role": "user", "content": f"{numbered}\n\nQuestion: {question}"}],
                                 cfg["model"])
                outcome = "refused" if reply.startswith(REFUSAL) else "answered"
            with span("check_citations") as c:
                cited = [int(n) for n in re.findall(r"\[(\d+)\]", reply)]
                c.set_attribute("app.citations.count", len(cited))
                c.set_attribute("app.citations.dangling", sum(1 for n in cited if not 0 < n <= len(sources)))
        root.set_attribute("app.outcome", outcome)
        root.set_attribute("app.reply", redact.redact(reply))
        trace_id = f"{root.get_span_context().trace_id:032x}"
    return reply, sources, trace_id


if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("question")
    p.add_argument("--user", default="anonymous")
    p.add_argument("--feature", default="help", choices=["help", "order", "summary"])
    a = p.parse_args()
    telemetry.setup(os.environ.get("SPANS", "spans.jsonl"))
    reply, sources, trace_id = ask(a.question, user=a.user, feature=a.feature)
    print(reply)
    print(f"trace {trace_id}")
