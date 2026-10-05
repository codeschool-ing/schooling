---
title: Keeping up with changes
version: 1
---

A help centre is not embedded once. Articles are edited, retired and added every week, and each
change has a cost of its own. **An edit costs one embedding. A delete costs almost nothing when it
happens and something later**, because most vector indexes do not remove a deleted vector: they
mark it. This section measures where that cost goes and what clears it.

## An edit is one row

When an article changes, its vector has to change with it, or the search keeps answering for the
old text. That is one call to the model, priced by its tokens like any other, and one update to
the row. The danger is not the cost but forgetting: write the text and the vector in the same
transaction, or from the same job, so that no reader sees one without the other.

## A delete leaves a tombstone

An HNSW graph cannot simply lose a node, because other nodes link through it. So hnswlib marks
it instead:

```schooling-example
{
  "language": "python",
  "file": "tombstones.py",
  "parts": [
    {
      "code": "import os\nimport hnswlib\nimport numpy as np\nfrom synth import unit_vectors\n\nX = np.load(\"v384.npy\")\nN = len(X)\nh = hnswlib.Index(space=\"ip\", dim=384)\nh.init_index(max_elements=N, M=16, ef_construction=64, allow_replace_deleted=True)\nh.add_items(X, np.arange(N))\nh.save_index(\"live.bin\")\nprint(\"built:   \", h.get_current_count(), \"elements\", os.path.getsize(\"live.bin\"), \"bytes\")",
      "note": "Build an index of the 20,000 vectors with `allow_replace_deleted=True`, which has to be decided when the index is created, and save it."
    },
    {
      "code": "for i in range(0, N, 2):\n    h.mark_deleted(i)\nh.save_index(\"live.bin\")\nprint(\"deleted: \", h.get_current_count(), \"elements\", os.path.getsize(\"live.bin\"), \"bytes\")\nlabels, _ = h.knn_query(X[:100], k=10)\nprint(\"deleted ids among 1,000 results:\", int((labels % 2 == 0).sum()))",
      "note": "Delete every other vector. hnswlib only marks them: the count and the file stay the same, and searches skip the marked ones."
    },
    {
      "code": "new = unit_vectors(5_000, 384, seed=5)\ntry:\n    h.add_items(new, np.arange(N, N + 5_000))\nexcept RuntimeError as e:\n    print(\"add:     \", e)\nh.add_items(new, np.arange(N, N + 5_000), replace_deleted=True)\nh.save_index(\"live.bin\")\nprint(\"replaced:\", h.get_current_count(), \"elements\", os.path.getsize(\"live.bin\"), \"bytes\")",
      "note": "Five thousand new vectors. Added as new elements they do not fit, because the index was sized for 20,000. Added with `replace_deleted=True`, they take the slots of deleted ones."
    }
  ]
}
```

```
ana@lab:~/emb$ python tombstones.py
built:    20000 elements 33691896 bytes
deleted:  20000 elements 33691896 bytes
deleted ids among 1,000 results: 0
add:      The number of elements exceeds the specified limit
replaced: 20000 elements 33691896 bytes
```

**Half the vectors were deleted and the index did not get smaller.** It still holds 20000 elements
and its file is still 33691896 bytes, the same as before the delete. Searches skip the marked
ones, so none of the 1,000 results named a deleted id; they still walk through them on the way.
And the space is not free for new vectors either, unless the index was created with
`allow_replace_deleted=True` and the new ones are added with `replace_deleted=True`. Then 5,000 new
vectors take 5,000 of the empty slots and the size does not move at all.

## In pgvector, VACUUM is slow and REINDEX shrinks

PostgreSQL never removes a row on `DELETE` either. It marks it dead, and `VACUUM` later clears the
dead rows from the table and from every index:

```schooling-example
{
  "language": "sql",
  "file": "vacuum.sql",
  "parts": [
    {
      "code": "SET maintenance_work_mem = '512MB';\nCREATE VIEW space AS\nSELECT (SELECT count(*) FROM v384)              AS \"rows\",\n       pg_relation_size(to_regclass('v384'))      AS heap,\n       pg_relation_size(to_regclass('v384_hnsw')) AS hnsw,\n       pg_relation_size(to_regclass('v384_ivf'))  AS ivf;",
      "note": "A view that reports the row count and the size of the table and of its two vector indexes. `to_regclass` looks each name up every time the view is read; written bare, a name would stay tied to the index that existed when the view was made. The `SET` gives the rebuild at the end room to work in memory."
    },
    {
      "code": "TABLE space;\nDELETE FROM v384 WHERE id % 2 = 0;\nTABLE space;",
      "note": "Delete half the rows, and look again."
    },
    {
      "code": "\\timing on\nVACUUM v384;\n\\timing off\nTABLE space;",
      "note": "`VACUUM` is what reclaims dead rows in PostgreSQL, and it also visits each index to remove their entries."
    },
    {
      "code": "\\timing on\nREINDEX TABLE CONCURRENTLY v384;\n\\timing off\nTABLE space;",
      "note": "`REINDEX ... CONCURRENTLY` builds fresh copies of the table's indexes beside the old ones and swaps them in, without blocking reads or writes."
    }
  ]
}
```

```
ana@lab:~/emb$ psql -f vacuum.sql
SET
CREATE VIEW
 rows  |   heap   |   hnsw   |   ivf    
-------+----------+----------+----------
 20000 | 32768000 | 40968192 | 33284096
(1 row)

DELETE 10000
 rows  |   heap   |   hnsw   |   ivf    
-------+----------+----------+----------
 10000 | 32768000 | 40968192 | 33284096
(1 row)

Timing is on.
VACUUM
Time: 128811.541 ms (02:08.812)
Timing is off.
 rows  |   heap   |   hnsw   |   ivf    
-------+----------+----------+----------
 10000 | 32768000 | 40968192 | 33284096
(1 row)

Timing is on.
REINDEX
Time: 6291.040 ms (00:06.291)
Timing is off.
 rows  |   heap   |   hnsw   |   ivf    
-------+----------+----------+----------
 10000 | 32768000 | 20488192 | 16891904
(1 row)
```

Three readings, in the order they happened.

**After the delete, nothing changed size.** 10000 rows, and the table and both indexes exactly as
large as with 20000.

**VACUUM took 128811.541 ms and still nothing changed size.** It removed the dead rows from the
indexes, and for an HNSW index that means repairing the links of every neighbour that pointed at
one, which is why it is slow. The space it freed stays inside the files, ready for new rows, and
is not given back.

**REINDEX took 6291.040 ms and halved both indexes**, to 20488192 and 16891904 bytes, because it
built them again from the 10000 rows that are left. `CONCURRENTLY` builds the new copies beside the
old ones and swaps them in, so searches keep working throughout; for that time, the index exists
twice. pgvector's own documentation suggests reindexing before vacuuming an HNSW index for this
reason. The table keeps its 32768000 bytes either way: its free space is reused by the next
inserts.

**So rebuild when a large share has been deleted or replaced**, not on a timer. A graph full of
tombstones is larger than it needs to be and slower to walk, and a rebuild costs what section 05
of this lesson measured: a build over the rows that remain.

## Versions behind a name

A bigger change, a new model, cannot be done in place, because the new vectors do not fit the old
index. The usual arrangement is a **versioned collection** for each model and a stable name the
application searches, pointed at whichever version is live. Qdrant calls that name an alias; here
it runs in local mode, inside the Python process:

```schooling-example
{
  "language": "python",
  "file": "alias.py",
  "parts": [
    {
      "code": "import json\nfrom qdrant_client import QdrantClient, models\nfrom minilm import embed\nfrom wordllama import WordLlama\n\nhelp = [json.loads(l) for l in open(\"data/help.jsonl\")]\ntexts = [h[\"title\"] + \". \" + h[\"body\"] for h in help]\nwl = WordLlama.load()\nMODEL = {\"help_v1\": embed, \"help_v2\": lambda t: wl.embed(t, norm=True)}\nclient = QdrantClient(path=\"qdrant\")",
      "note": "Two collections for the same 40 articles, one per model, and a table saying which model each was built with. Qdrant runs here in local mode, inside the Python process."
    },
    {
      "code": "def build(name):\n    V = MODEL[name](texts)\n    client.create_collection(name, vectors_config=models.VectorParams(\n        size=V.shape[1], distance=models.Distance.COSINE))\n    client.upsert(name, [models.PointStruct(id=i, vector=v.tolist(), payload={\"id\": h[\"id\"]})\n                         for i, (h, v) in enumerate(zip(help, V))])",
      "note": "Build a collection: embed every article with that collection's model and store the vectors, sized to the model's dimension."
    },
    {
      "code": "def point_alias(name):\n    ops = [models.CreateAliasOperation(create_alias=models.CreateAlias(\n        collection_name=name, alias_name=\"help\"))]\n    if behind_alias():\n        ops.insert(0, models.DeleteAliasOperation(delete_alias=models.DeleteAlias(alias_name=\"help\")))\n    client.update_collection_aliases(change_aliases_operations=ops)\n\ndef behind_alias():\n    return {a.alias_name: a.collection_name for a in client.get_aliases().aliases}.get(\"help\")",
      "note": "Point the alias `help` at a collection. Removing the old alias and creating the new one go in one call, so no query sees `help` pointing nowhere. `behind_alias` asks where it points now."
    },
    {
      "code": "def search(question, embed_with):\n    hit = client.query_points(\"help\", query=embed_with([question])[0].tolist(), limit=1).points[0]\n    return hit.payload[\"id\"], round(hit.score, 3)\n\nq = \"how do I get my money back\"\nbuild(\"help_v1\"); point_alias(\"help_v1\")\nprint(behind_alias(), search(q, embed))\nbuild(\"help_v2\"); point_alias(\"help_v2\")\nprint(behind_alias(), search(q, MODEL[behind_alias()]))\ntry:\n    print(search(q, embed))\nexcept Exception as e:\n    print(type(e).__name__, str(e)[:90])\nclient.close()",
      "note": "Search through the alias, with whichever embedding function the caller passes. The rest switches the alias from v1 to v2 and searches three times."
    }
  ]
}
```

```
ana@lab:~/emb$ python alias.py
help_v1 ('h18', 0.446)
help_v2 ('h15', 0.573)
ValueError shapes (40,256) and (384,) not aligned: 256 (dim 1) != 384 (dim 0)
```

Behind `help_v1`, the question that opened lesson 1 finds `h18` at 0.446, the score `near.py`
printed then. Behind `help_v2`, built with WordLlama, it finds `h15` at 0.573. The switch is one
call, and searches before it see v1 and searches after it see v2.

**The last line is the mistake the alias cannot catch.** The alias moved and the code still
embedded the question with MiniLM. Here it fails loudly, because 384 numbers cannot be compared
with 256; that message is local mode's own NumPy, and the Qdrant server would word its refusal
differently. Two models with the same dimension would not fail at all: they would return confident
nonsense. **Keep the model's name with the version it built, and switch the embedding and the
alias in the same release.** In PostgreSQL the same arrangement is a table per version and a view,
or a rename inside a transaction.
