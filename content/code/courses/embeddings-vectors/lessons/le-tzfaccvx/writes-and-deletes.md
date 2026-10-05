---
title: Writes and deletes
version: 1
---

A help centre changes. An article is corrected, another is withdrawn, a new one appears. The
natural expectation is that a vector database edits a record in place and removes a deleted one
on the spot, the way a row disappears from a spreadsheet. **Most of them do neither straight away.**
An edit writes a new version and retires the old one; a delete marks the record as gone and leaves
it where it is until a later clean-up. The small store does both the same way, and `writes.py`
shows the counts:

```schooling-example
{
  "language": "python",
  "file": "writes.py",
  "parts": [
    {
      "code": "import json\nfrom minilm import embed\nfrom tinystore import Store\n\nstore = Store.load(\"store\")\nask = lambda: [id for id, _ in store.search(q, k=3, model=\"all-MiniLM-L6-v2\")]\nq = embed(\"how do I get my money back\")[0]\nprint(\"before:      \", ask(), \"rows\", len(store.ids), \"alive\", int(store.alive.sum()))",
      "note": "Load the store and ask the question of lesson 1. Print the top three ids, the rows in the array and the rows still alive."
    },
    {
      "code": "help = {h[\"id\"]: h for h in map(json.loads, open(\"data/help.jsonl\"))}\nh = help[\"h15\"]\ntext = h[\"title\"] + \". \" + h[\"body\"].replace(\"three working days\", \"five working days\")\nstore.upsert(\"h15\", embed(text)[0], {\"category\": \"returns\", \"lang\": \"en\", \"updated\": \"2026-10-05\"}, text)\nprint(\"after edit:  \", ask(), \"rows\", len(store.ids), \"alive\", int(store.alive.sum()))",
      "note": "Edit an article: h15 now says five working days instead of three. Its new text is embedded again and upserted under the same id."
    },
    {
      "code": "store.delete(\"h18\")\nprint(\"after delete:\", ask(), \"rows\", len(store.ids), \"alive\", int(store.alive.sum()))",
      "note": "Delete the gift article, h18, and ask again."
    },
    {
      "code": "store.save()\nprint(\"saved:       \", len(Store.load(\"store\").ids), \"records\")",
      "note": "Save, which compacts, and count the records that come back from disk."
    }
  ]
}
```

```
ana@lab:~/emb$ python writes.py
before:       ['h18', 'h15', 'h22'] rows 40 alive 40
after edit:   ['h18', 'h15', 'h22'] rows 41 alive 40
after delete: ['h15', 'h22', 'h14'] rows 41 alive 39
saved:        39 records
ana@lab:~/emb$ ls -l store
total 76
-rw-r--r-- 1 ana ana 13796 Oct  5 14:21 records.json
-rw-r--r-- 1 ana ana 60032 Oct  5 14:21 vectors.npy
```

## An upsert, not an insert or an update

**Writing an id that exists replaces the record; writing a new id adds one.** That operation is
called an upsert, and it is the usual write in vector databases (Chroma, Qdrant and Pinecone all
name a method after it) because it makes a write safe to repeat. A job that re-embeds the help
centre every night can upsert all 40 articles without first asking which ones exist.

The edit to `h15` went in that way, and the second line shows what it cost inside. **The rows went
from 40 to 41 while the live records stayed at 40.** The old vector of `h15` is still in the array,
marked dead; the new one was appended. The ranking did not move, because changing *three* to *five*
working days hardly moves the meaning, and that is the right result: the vector was computed again
from the new text.

**That is the rule the store cannot enforce for you: a vector has to be recomputed whenever its
text changes.** `upsert` takes the vector and the text as two arguments, and nothing stops a caller
from passing new text with the old vector. The record then answers questions about what the
article used to say and shows what it says now. Every real database has the same gap, because none
of them can check that a vector belongs to a text; the code that writes has to embed in the same
step, every time.

## A delete leaves a tombstone

`delete("h18")` took the gift article out of the results: the third line ranks `h15` first and
brings in `h14`. **But the rows stayed at 41.** The delete only cleared the row's `alive` flag, so
the vector is still there, still multiplied by every query and then discarded. A marker like that,
standing in for something deleted, is called a **tombstone**.

Tombstones are not laziness. Removing a row from the middle of an array means moving every row after
it, and in a real index it is worse: an approximate index, which lesson 15 builds, is a structure
of links between vectors, and taking one vector out of it means repairing every link that passed
through it. Marking it dead is instant. The cost is paid later, all at once.

**Saving is where the store pays it.** `save()` writes only the live rows, so the store on disk
holds 39 records, and the files shrank by exactly one vector: `vectors.npy` went from 61568 to
60032 bytes, a difference of 1,536, which is 384 numbers of 4 bytes. Real databases call that step
compaction, vacuuming or rebuilding, run it in the background, and get slower while too many
tombstones pile up. Lesson 18 measures what rebuilding an index costs, and when it is worth doing.
