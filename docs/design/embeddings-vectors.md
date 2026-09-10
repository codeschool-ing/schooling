---
format: 5
course: embeddings-vectors
---

# embeddings-vectors

**Embeddings and Vector Databases** · `co-amgjc0jx` · 60 h declared · intermediate · 18 lessons · `ai` · paid

## Reach

In **1 track** — `ai`(7).

**Depends on it:** `rag`

## Assumes, and leaves ready

**Assumes:** `ai-models` — providers, SDKs, keys and quotas. The embedding APIs of lessons 7 to 10 are the same accounts.

**Leaves ready:** vector search, for `rag`. **The single most load-bearing edge in the category**: `rag` has two dependents of its own, so everything from position 8 of `ai` onward stands on this course.

## Shape

| | |
|---|---|
| declared hours | 60 h |
| lessons | 18 |
| **hours per lesson** | **3.33** |
| section budget | ~129, about 7.2 a lesson |
| exercises | ~610, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **an API key with a bill attached** — a metered third party, not a machine, **plus a vector database** |
| browser · database | no · **yes, and a kind the platform has never needed** — Chroma, Qdrant or FAISS, or `pgvector` inside a Postgres that already exists |
| exercises **blocked** | **~400 (65%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~60 — meaning as a vector, cosine similarity drawn, an HNSW graph, top-k moving, metadata filters narrowing a search |

## Ageing

**Moderate.** The idea is permanent; lessons 12 to 14 name seven vector databases, and that market is consolidating.

## Flags

**1 ·** **The environment is a vector database, and one of its own lessons names the cheap way out.** Lesson 14 is *"Vectors in databases you already use: Supabase and MongoDB Atlas"* — and `pgvector` in Postgres is the same idea. **This platform already runs Postgres**, so the environment for this course is an extension on a database the sandbox needs anyway for `sql-databases`. That is the second time the sweep has found a course whose expensive-looking environment collapses into one already being argued for.

**2 ·** **The mathematics is gradeable and nobody would guess it from the subject.** Cosine similarity between two given vectors is `numeric`; ranking four documents by distance is `ordering`; which of these top-k values returns the missing result is a `quiz`. **The half that looks hardest to assess is the half that grades today**, and the API half is what does not.

**3 ·** **Lessons 4, 5 and 6 are applications that belong to another course.** Classification, recommendation and anomaly detection are `machine-learning` lessons 16, 18 and — by way of clustering — 16 again. No track reaches both (`ai` has this, `data-science` has that), so it is not a student-facing repetition; it is an authoring one, and the two should not be written from scratch twice.
