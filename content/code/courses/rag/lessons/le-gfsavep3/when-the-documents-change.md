---
title: When the documents change
version: 2
---

A cached answer is a copy of what the pipeline said about the documents as they were. When a document
changes, the copy is out of date, and a cache with no way to notice serves the old policy with the
same confidence as the new. Lesson 3 argued that a RAG system is fresh the moment its index is; a cache
in front of it is fresh only if it knows when the index changed.

The exact cache's key carries the index version, a hash of every chunk id. Here is the version, then an
edit to the gift card terms and lesson 5's loader, then the version again:

```
ana@vm:~/rag$ python -c "import exact; print(exact.version())"
0acfdfa0d064
ana@vm:~/rag$ sed -i "s/valid for two years from the day it was bought/valid for three years from the day it was bought/" data/docs/gift-cards.md && python ingest.py
chunks: 137  embedded: 1  removed: 1  kept: 136
ana@vm:~/rag$ python -c "import exact; print(exact.version())"
de4849f90b4a
```

**One chunk re-embedded, one removed, and a new version.** Every key built with the old version now
misses, so the first question after the change goes to the pipeline, which reads the new text. Nothing
had to find the gift card answers in the cache; they simply stopped matching.

The cost is that one edit to one document misses every cached answer, including the ones that had
nothing to do with gift cards. A finer key, the versions of only the documents an answer cited, keeps
the unrelated answers, at the price of storing which documents each answer used, which lesson 9's log
already records. For a corpus that changes weekly, the coarse version is simpler and the misses are
cheap; for one that changes by the minute, the finer one pays for itself.

Deletion is the case that must not wait. A document withdrawn for being wrong, or removed at somebody's
request, has to leave the cache the moment it leaves the index, which a version in the key guarantees
and a time-to-live does not.
