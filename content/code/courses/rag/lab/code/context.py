"""What goes into the window, and in what order: lesson 12's decisions in one place."""
import re

import tiktoken
from answer import FLOOR, REFUSAL, ask
from minilm import embed
from search import conn, vector

enc = tiktoken.get_encoding("cl100k_base")
SAME = 0.9      # two sources this similar say the same thing
KEEP = 0.45     # a sentence this similar to the question stays in its source
BUDGET = 200    # tokens of sources, headers included


def tokens(text):
    return len(enc.encode(text))


def candidates(question, k=10, where="status = %s AND audience = %s", params=("current", "public")):
    """Up to K chunks above the floor, best first, with what a source header needs."""
    found = [r for r in vector(question, k, where, params) if r[3] >= FLOOR]
    meta = {i: (u, v) for i, u, v in conn.execute(
        "SELECT id, updated, doc_version FROM chunks WHERE id = ANY(%s)", ([r[0] for r in found],))}
    return [{"id": i, "path": p, "text": t, "score": s, "updated": meta[i][0], "version": meta[i][1]}
            for i, p, t, s in found]


def dedupe(sources, same=SAME):
    """Drop a source that says what a better one already said."""
    if not sources:
        return []
    v = embed([s["text"] for s in sources])
    kept = []
    for i in range(len(sources)):
        if all(v[i] @ v[j] < same for j in kept):
            kept.append(i)
    return [sources[i] for i in kept]


def sentences(text):
    return [s for s in re.split(r"(?<=[.!?])\s+(?=[A-Z0-9])|\n(?=- )|\n\n", text) if s.strip()]


def compress(question, source, keep=KEEP):
    """Keep the sentences of a source that are about the question, in their order, and always its best."""
    parts = sentences(source["text"])
    scores = embed(parts) @ embed(question)[0]
    chosen = [p for p, s in zip(parts, scores) if s >= keep or s == scores.max()]
    return {**source, "text": " ".join(" ".join(p.split()) for p in chosen)}


def ends(sources):
    """Best first, second best last, the weakest in the middle."""
    return sources[0::2] + sources[1::2][::-1]


def header(n, source):
    return f"[{n}] {source['path']} (updated {source['updated']})\n"


def pack(question, budget=BUDGET, k=10, **filters):
    """Floor, then duplicates out, then each source cut to what is about the question, then as many
    as fit the budget, best first, and finally the strongest two at the two ends."""
    kept, used = [], 0
    for s in dedupe(candidates(question, k, **filters)):
        s = compress(question, s)
        cost = tokens(header(0, s) + s["text"])
        if used + cost <= budget:
            kept.append(s)
            used += cost
    return ends(kept)


def answer(question, **filters):
    sources = pack(question, **filters)
    if not sources:
        return REFUSAL, []
    return ask(question, sources), sources
