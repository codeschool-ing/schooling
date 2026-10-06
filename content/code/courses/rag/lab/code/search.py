import re

import minilm
import numpy as np
import psycopg
from minilm import embed
from pgvector.psycopg import register_vector
from rank_bm25 import BM25Okapi

conn = psycopg.connect(autocommit=True)
register_vector(conn)


def rows(where="TRUE", params=()):
    return conn.execute(f"SELECT id, path, text FROM chunks WHERE {where} ORDER BY id", params).fetchall()


def vector(question, k=3, where="TRUE", params=()):
    """The K chunks nearest the question, by cosine similarity, among those WHERE allows."""
    q = embed(question)[0]
    return conn.execute(
        f"SELECT id, path, text, 1 - (embedding <=> %s) FROM chunks WHERE {where}"
        " ORDER BY embedding <=> %s LIMIT %s", (q, *params, q, k)).fetchall()


TOKEN = re.compile(r"[a-z0-9]+(?:[-.%][a-z0-9]+)*%?")


def words(text):
    return TOKEN.findall(text.lower())


def lexical(question, k=3, where="TRUE", params=()):
    """The K chunks BM25 scores highest for the question's words."""
    found = rows(where, params)
    bm25 = BM25Okapi([words(path + " " + text) for _, path, text in found])
    scores = bm25.get_scores(words(question))
    return [(*found[i], float(scores[i])) for i in np.argsort(-scores, kind="stable")[:k]]


def hybrid(question, k=3, depth=20, where="TRUE", params=()):
    """Reciprocal rank fusion of the two lists, each DEPTH long."""
    fused = {}
    for ranking in (vector(question, depth, where, params), lexical(question, depth, where, params)):
        for rank, row in enumerate(ranking, 1):
            fused.setdefault(row[0], [row[:3], 0.0])[1] += 1 / (60 + rank)
    best = sorted(fused.values(), key=lambda item: -item[1])[:k]
    return [(*row, score) for row, score in best]


def token_vectors(texts):
    """One unit vector per word piece, from the same MiniLM, before it averages them."""
    enc = minilm._tok.encode_batch(list(texts))
    ids = np.array([e.ids for e in enc], dtype=np.int64)
    mask = np.array([e.attention_mask for e in enc], dtype=np.int64)
    hidden = minilm._model.run(None, {"input_ids": ids, "attention_mask": mask,
                                      "token_type_ids": np.zeros_like(ids)})[0]
    out = []
    for h, m in zip(hidden, mask):
        h = h[m.astype(bool)][1:-1]
        out.append(h / np.linalg.norm(h, axis=1, keepdims=True))
    return out


def rerank(question, candidates, k=3):
    """Late interaction: each question piece takes its best match in the chunk, and the matches add up."""
    q = token_vectors([question])[0]
    chunks = token_vectors([path + "\n" + text for _, path, text, _ in candidates])
    scores = [float((q @ c.T).max(axis=1).sum()) for c in chunks]
    order = np.argsort(-np.array(scores), kind="stable")[:k]
    return [(*candidates[i][:3], scores[i]) for i in order]
