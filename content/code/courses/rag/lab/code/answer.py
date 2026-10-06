import re
import sys

from openai import OpenAI
from search import conn, vector

SYSTEM = """You answer questions from Marginalia's customers, using only the numbered sources.
Cite every sentence with the number of the source it comes from, like [1].
If the sources do not answer the question, reply: "I could not find that in our documents."
If two sources disagree, prefer the one updated most recently, and say so."""
FLOOR = 0.5
REFUSAL = "I could not find that in our documents."
client = OpenAI()


def sources_for(question, k=3, where="status = %s AND audience = %s", params=("current", "public")):
    """The chunks worth showing the model: filtered, and above the floor lesson 6 chose."""
    found = [r for r in vector(question, k, where, params) if r[3] >= FLOOR]
    meta = {i: (u, v) for i, u, v in conn.execute(
        "SELECT id, updated, doc_version FROM chunks WHERE id = ANY(%s)", ([r[0] for r in found],))}
    return [{"id": i, "path": p, "text": t, "score": s, "updated": meta[i][0], "version": meta[i][1]}
            for i, p, t, s in found]


def prompt(question, sources):
    blocks = [f"[{n}] {s['path']} (updated {s['updated']})\n{s['text']}" for n, s in enumerate(sources, 1)]
    return "\n\n".join(blocks + [f"Question: {question}"])


def ask(question, sources):
    reply = client.chat.completions.create(model="extract-1", messages=[
        {"role": "system", "content": SYSTEM},
        {"role": "user", "content": prompt(question, sources)}])
    return reply.choices[0].message.content


def answer(question, **filters):
    """The reply and its sources; with no source above the floor, the refusal, and no model call."""
    sources = sources_for(question, **filters)
    if not sources:
        return REFUSAL, []
    return ask(question, sources), sources


def citations(reply, sources):
    """Each [n] in the reply, with the source it points at, or None if there is no such source."""
    return [(int(n), sources[int(n) - 1] if 0 < int(n) <= len(sources) else None)
            for n in re.findall(r"\[(\d+)\]", reply)]


if __name__ == "__main__":
    reply, sources = answer(sys.argv[1])
    print(reply)
    shown = set()
    for n, s in citations(reply, sources):
        if n not in shown:
            shown.add(n)
            print(f"  [{n}] {s['path']}, updated {s['updated']}" if s else f"  [{n}] points at no source")
