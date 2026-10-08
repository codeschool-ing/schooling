---
title: Ids that make re-indexing cheap
version: 2
---

Documents change one paragraph at a time. A pipeline that re-embeds the whole corpus whenever anything
changes is correct and wasteful; one that re-embeds only what changed has to know what changed, and
the cheapest way to know is to make the chunk's id depend on its content.

## A content hash as the id

`chunks_of` builds each id from the document's id and the first twelve hexadecimal characters of a
SHA-256 hash of the chunk's path and text. Same text, same id; one word different, a different id.
`main` then compares two sets of ids, what the documents produce now and what the table already holds:

```schooling-example
{
  "language": "python",
  "file": "ingest.py",
  "parts": [
    {
      "code": "def main():\n    want = [c for doc_id, (meta, body) in load().items() for c in chunks_of(doc_id, meta, body)]\n    with psycopg.connect() as conn:\n        conn.execute(SCHEMA)\n        register_vector(conn)\n        have = {row[0] for row in conn.execute(\"SELECT id FROM chunks\")}\n        new = [c for c in want if c[\"id\"] not in have]\n        gone = have - {c[\"id\"] for c in want}\n        for c, v in zip(new, embed([c[\"path\"] + \"\\n\" + c[\"text\"] for c in new])):\n            c[\"embedding\"] = v\n        with conn.cursor() as cur:\n            cur.executemany(\n                \"INSERT INTO chunks VALUES (%(id)s, %(doc_id)s, %(doc_version)s, %(status)s, %(audience)s,\"\n                \" %(owner)s, %(updated)s, %(path)s, %(position)s, %(text)s, %(tokens)s, %(model)s,\"\n                \" %(embedding)s::vector)\", new)\n            cur.executemany(\n                \"UPDATE chunks SET doc_version = %(doc_version)s, status = %(status)s,\"\n                \" audience = %(audience)s, owner = %(owner)s, updated = %(updated)s,\"\n                \" position = %(position)s WHERE id = %(id)s\", [c for c in want if c[\"id\"] in have])\n            cur.execute(\"DELETE FROM chunks WHERE id = ANY(%s)\", (list(gone),))\n    print(f\"chunks: {len(want)}  embedded: {len(new)}  removed: {len(gone)}  kept: {len(want) - len(new)}\")",
      "note": "What the documents say now (`want`) is compared with what the table holds (`have`). Only the new ids are embedded and inserted; the ids no longer wanted are deleted; every surviving chunk has its metadata rewritten, because a status can change without the text changing."
    },
    {
      "code": "if __name__ == \"__main__\":\n    main()"
    }
  ]
}
```

## Running it twice

```
ana@vm:~/rag$ python ingest.py
chunks: 137  embedded: 0  removed: 0  kept: 137
```

**Nothing embedded, 137 kept.** Every id the documents produced was already in the table, so not one
request went to the provider. This is what makes the run safe to repeat: a run that died halfway,
after embedding some batches, is finished by running it again, and only what is missing is sent.

## Changing one sentence

Suppose finance shortens the refund time. The policy's sentence about it is edited, in ana's working
copy of the corpus:

```
ana@vm:~/rag$ sed -i "s/We refund within three working days/We refund within two working days/" data/docs/returns-policy.md
ana@vm:~/rag$ python ingest.py
chunks: 137  embedded: 1  removed: 1  kept: 136
```

**One chunk embedded, one removed, 136 kept.** The edited sentence lives in one chunk; that chunk's
text changed, so its hash changed, so the old id was no longer wanted and the new one was missing. One
embedding, one insert, one delete, and the index is current. For a corpus of millions of chunks where a
few hundred change each day, this is the difference between a nightly job of minutes and one of days.

## What a content hash does not catch

**A chunk boundary moving.** If an edit adds a paragraph, `structured` may pack the following
paragraphs differently, and several chunks change text without anyone editing them. They get new ids
and are re-embedded, correctly; the cost of an edit is not always one chunk.

**A change of model.** The id says nothing about which model made the vector. Switching to another
embedding model means every vector is wrong, and none of the ids changes. The `model` column is there
so that the switch can be done deliberately: embed everything with the new model into new rows or a
new table, check it, then swap. `embeddings-vectors` lesson 18 measured what re-embedding a whole corpus
costs.

**A change of metadata.** A document marked superseded, or moved to another audience, has the same
text and therefore the same ids. That is why `main` rewrites the metadata of every surviving chunk on
every run, which is cheap because it is a database update with no embedding. The next section is that
case.
