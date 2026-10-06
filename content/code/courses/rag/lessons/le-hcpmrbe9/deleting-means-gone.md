---
title: Deleting means gone
version: 1
---

Lesson 2 listed deletion that works among the things internal knowledge asks of a pipeline: when a
document is withdrawn, its chunks must leave the index the same day. Withdrawing is a permission
change too, the most complete one, to nobody, and it deserves the same kind of proof as the filters.
`deleted.py` asks two questions of the system: how many chunks of the warehouse runbook are in the
table, and how many of the agent's five nearest chunks for a question only the runbook answers come
from it.

```
ana@lab:~/rag$ python deleted.py
chunks of warehouse-runbook in the table: 7
of the agent's 5 nearest for 'What is a SEV-2 incident?', from the runbook: 4
ana@lab:~/rag$ rm data/docs/warehouse-runbook.md && python ingest.py
chunks: 130  embedded: 0  removed: 7  kept: 130
ana@lab:~/rag$ python deleted.py
chunks of warehouse-runbook in the table: 0
of the agent's 5 nearest for 'What is a SEV-2 incident?', from the runbook: 0
```

Before: **7 chunks, and 4 of the agent's 5 results.** The file is removed and lesson 5's `ingest.py`
runs, comparing the ids it wants with the ids it has: **7 removed**. After: **0 chunks, and 0 of the
agent's results.** After a deletion both numbers have one passing value, zero, so a check in CI
asserts them rather than printing them, and a deletion that left one chunk behind fails the first and
very likely the second.

That is the index. A document's text also travels to places the index does not cover, and an erasure
that stops at the table has stopped early:

- **The query log.** Lesson 9's `queries.jsonl` records the chunk ids each answer used, and its
  replies quote their sentences. A withdrawn document is still being read back from a log of what was
  answered.
- **Caches.** Lesson 17 caches answers by question. A cached answer built from a deleted chunk keeps
  serving it until it expires.
- **Memories and summaries**, lesson 13's and 15's, where a reply that quoted the document was kept.
- **Backups**, which a team cannot edit, and which therefore need a retention period short enough that
  a deletion eventually reaches them too.

For each, the test is the same shape as `deleted.py`: after the deletion, ask the place for the
document and count what comes back. Zero is the only passing number.
