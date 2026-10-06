import hashlib

import psycopg
import tiktoken
from chunking import load, structured
from openai import OpenAI
from pgvector.psycopg import register_vector

MODEL = "lab-minilm"
SIZE = 60
enc = tiktoken.get_encoding("cl100k_base")
client = OpenAI(max_retries=5)

SCHEMA = """
CREATE TABLE IF NOT EXISTS chunks (
    id          text PRIMARY KEY,
    doc_id      text NOT NULL,
    doc_version text NOT NULL,
    status      text NOT NULL,
    audience    text NOT NULL,
    owner       text NOT NULL,
    updated     date NOT NULL,
    path        text NOT NULL,
    position    int  NOT NULL,
    text        text NOT NULL,
    tokens      int  NOT NULL,
    model       text NOT NULL,
    embedding   vector(384) NOT NULL
);
CREATE INDEX IF NOT EXISTS chunks_doc ON chunks (doc_id);
"""


def chunks_of(doc_id, meta, body):
    """Every chunk of one document, with the metadata the search will filter on."""
    for position, (path, text) in enumerate(structured(body, SIZE)):
        digest = hashlib.sha256(f"{path}\n{text}".encode()).hexdigest()[:12]
        yield {"id": f"{doc_id}:{digest}", "doc_id": doc_id, "doc_version": meta["version"],
               "status": meta["status"], "audience": meta["audience"], "owner": meta["owner"],
               "updated": meta["updated"], "path": path, "position": position, "text": text,
               "tokens": len(enc.encode(text)), "model": MODEL}


def embed(texts, batch=32):
    vectors = []
    for i in range(0, len(texts), batch):
        reply = client.embeddings.create(model=MODEL, input=texts[i:i + batch])
        vectors += [d.embedding for d in reply.data]
    return vectors


def main():
    want = [c for doc_id, (meta, body) in load().items() for c in chunks_of(doc_id, meta, body)]
    with psycopg.connect() as conn:
        conn.execute(SCHEMA)
        register_vector(conn)
        have = {row[0] for row in conn.execute("SELECT id FROM chunks")}
        new = [c for c in want if c["id"] not in have]
        gone = have - {c["id"] for c in want}
        for c, v in zip(new, embed([c["path"] + "\n" + c["text"] for c in new])):
            c["embedding"] = v
        with conn.cursor() as cur:
            cur.executemany(
                "INSERT INTO chunks VALUES (%(id)s, %(doc_id)s, %(doc_version)s, %(status)s, %(audience)s,"
                " %(owner)s, %(updated)s, %(path)s, %(position)s, %(text)s, %(tokens)s, %(model)s,"
                " %(embedding)s::vector)", new)
            cur.executemany(
                "UPDATE chunks SET doc_version = %(doc_version)s, status = %(status)s,"
                " audience = %(audience)s, owner = %(owner)s, updated = %(updated)s,"
                " position = %(position)s WHERE id = %(id)s", [c for c in want if c["id"] in have])
            cur.execute("DELETE FROM chunks WHERE id = ANY(%s)", (list(gone),))
    print(f"chunks: {len(want)}  embedded: {len(new)}  removed: {len(gone)}  kept: {len(want) - len(new)}")


if __name__ == "__main__":
    main()
