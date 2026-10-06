"""rag.py: the whole pipeline in one file, with the provider's SDK and nothing else.

    python rag.py "QUESTION"
"""
import json
import re
import sys
import time

import psycopg
from openai import OpenAI
from pgvector.psycopg import register_vector

EMBED_MODEL, CHAT_MODEL = "lab-minilm", "extract-1"
K, FLOOR = 3, 0.5
REFUSAL = "I could not find that in our documents."
SYSTEM = """You answer questions from Marginalia's customers, using only the numbered sources.
Cite every sentence with the number of the source it comes from, like [1].
If the sources do not answer the question, reply: "I could not find that in our documents."
If two sources disagree, prefer the one updated most recently, and say so."""

client = OpenAI(max_retries=3, timeout=20)
db = psycopg.connect(autocommit=True)
register_vector(db)


def retrieve(question):
    vector = client.embeddings.create(model=EMBED_MODEL, input=[question]).data[0].embedding
    rows = db.execute(
        "SELECT id, path, text, updated, 1 - (embedding <=> %s::vector) AS score FROM chunks"
        " WHERE status = 'current' AND audience = 'public'"
        " ORDER BY embedding <=> %s::vector LIMIT %s", (vector, vector, K)).fetchall()
    return [r for r in rows if r[4] >= FLOOR]


def generate(question, sources):
    numbered = "\n\n".join(f"[{n}] {path} (updated {updated})\n{text}"
                           for n, (_, path, text, updated, _) in enumerate(sources, 1))
    reply = client.chat.completions.create(model=CHAT_MODEL, max_tokens=300, messages=[
        {"role": "system", "content": SYSTEM},
        {"role": "user", "content": f"{numbered}\n\nQuestion: {question}"}])
    return reply.choices[0].message.content, reply.usage


def ask(question):
    started = time.monotonic()
    sources = retrieve(question)
    reply, usage = generate(question, sources) if sources else (REFUSAL, None)
    cited = sorted({int(n) for n in re.findall(r"\[(\d+)\]", reply)})
    record = {"question": question, "sources": [[s[0], round(s[4], 3)] for s in sources],
              "reply": reply, "cited": [sources[n - 1][0] for n in cited if 0 < n <= len(sources)],
              "prompt_tokens": usage.prompt_tokens if usage else 0,
              "completion_tokens": usage.completion_tokens if usage else 0,
              "ms": round((time.monotonic() - started) * 1000)}
    with open("queries.jsonl", "a") as log:
        log.write(json.dumps(record) + "\n")
    return reply, sources, cited


if __name__ == "__main__":
    reply, sources, cited = ask(sys.argv[1])
    print(reply)
    for n in cited:
        _, path, _, updated, _ = sources[n - 1]
        print(f"  [{n}] {path}, updated {updated}")
