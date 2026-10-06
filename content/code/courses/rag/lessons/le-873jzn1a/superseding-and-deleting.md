---
title: Superseding and deleting
version: 1
---

Lessons 1 and 3 kept running into `returns-policy-2025`: the replaced policy, retrieved because it is
about exactly the right thing, and quoted with confidence. There are two ways to stop that, and the
index has to support both, because they answer different needs.

## Marking a document as superseded

The first keeps the document and records that it no longer applies. Every document's front matter has
a `status`, and every chunk carries it. Suppose Marginalia replaces its gift card terms and marks the
old ones:

```
ana@lab:~/rag$ sed -i "s/^status: current$/status: superseded/" data/docs/gift-cards.md
ana@lab:~/rag$ python ingest.py
chunks: 137  embedded: 0  removed: 0  kept: 137
ana@lab:~/rag$ psql -c "SELECT status, count(*) FROM chunks GROUP BY status"
   status   | count 
------------+-------
 superseded |    12
 current    |   125
(2 rows)
```

**Nothing was embedded, and twelve chunks are now superseded**: the five of the gift card terms and
the seven of the 2025 returns policy, which was marked that way from the start. The text did not
change, so no id changed and no vector was recomputed; `main` rewrote the metadata of every chunk, and
the new status is in the table.

Marking keeps the old text available for the questions that need it. A support agent handling a
complaint about an order from 2025 needs the 2025 policy; an auditor asking what customers were told
last year needs it too. What the mark does by itself is nothing: the search still returns superseded
chunks until a query says not to. Lesson 14 adds that condition to every customer-facing search, and
lets an agent's search include old versions on purpose.

## Deleting a document

The second removes the document entirely. When a document is wrong, withdrawn, or holds personal data
somebody has asked to have erased, it should not be findable by anybody:

```
ana@lab:~/rag$ rm data/docs/returns-policy-2025.md
ana@lab:~/rag$ python ingest.py
chunks: 130  embedded: 0  removed: 7  kept: 130
ana@lab:~/rag$ psql -tc "SELECT count(*) FROM chunks WHERE doc_id = 'returns-policy-2025'"
     0
```

**Seven chunks removed, none left.** Because `ingest.py` compares what the documents produce with
what the table holds, deleting the file is enough: its ids are no longer wanted, and they are deleted
in the same run. No separate deletion step can be forgotten.

That property is the one lesson 3 relied on when it said a retrieval system can honour a deletion
request where a fine-tuned model cannot. It holds only if **the index is derived from the documents and
nothing else writes to it.** A chunk inserted by hand, or by a second program, has no document behind
it, and the next run of `ingest.py` deletes it, because no document produces its id: whatever
correction it carried disappears overnight, with nobody told. So the rule for the index is the one
this repository applies to its own catalogue: the files are the truth, one program writes the mirror,
and a correction is made in the file.

## Which to use

| | mark superseded | delete |
| --- | --- | --- |
| the text stays findable | by searches that ask for it | by nobody |
| the next answer to a customer | current documents only, once lesson 14's filter is in place | current documents only |
| fits | replaced policies, old versions of terms, anything an audit may ask about | wrong documents, withdrawn ones, personal data under an erasure request |
| undone by | changing the status back | restoring the file and re-embedding |
