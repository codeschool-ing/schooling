---
format: 5
course: rag
---

# rag

**RAG and Context Engineering** · `co-gdk6kptp` · 70 h declared · intermediate · 17 lessons · `ai` · paid

## Reach

In **1 track** — `ai`(8).

**Depends on it:** `agents-mcp`, `llm-observability`

## Assumes, and leaves ready

**Assumes:** `embeddings-vectors` — chunks have to be embedded and stored before anything retrieves them.

**Leaves ready:** retrieval and context engineering, for `agents-mcp` and `llm-observability`. **Two dependents, the most in the category.**

## Shape

| | |
|---|---|
| declared hours | 70 h |
| lessons | 17 |
| **hours per lesson** | **4.12** |
| section budget | ~150, about 8.8 a lesson |
| exercises | ~700, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **an API key with a bill attached** — a metered third party, not a machine, a vector store, and a document corpus worth searching |
| browser · database | no · **yes, the same vector store** |
| exercises **blocked** | **~450 (70%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~65 — the retrieve-then-generate loop, chunking with and without overlap, reranking reordering results, a context window packed three different ways |

## Ageing

**Moderate.** Lessons 10 and 11 name LangChain, LlamaIndex, Haystack and RAGFlow; the rest — chunking, reranking, citation, compaction — is the durable part and is most of the course.

## Flags

**1 ·** **The corpus is authored material and nobody has counted it.** Every other blocked course in the sweep needs a *machine*; this one needs **documents with the right properties** — long enough to chunk, ambiguous enough that retrieval can fail, structured enough that a citation means something. Those are fixtures, they live in `content/`, and they are the same kind of authoring cost `data-cleaning`'s deliberately-broken tables are. **Two courses now need authored data rather than an environment**, which is a category of work no sheet before this batch had named.

**2 ·** **Context engineering is the newest idea here and the most durable.** Lessons 12 to 16 — filling the window with only what matters, external memory, dynamic filters, compaction, isolation — are about a constraint that does not go away when models get bigger, because the window grows and so does what people put in it. **That is where the course should be weighted**, against the instinct to spend it on the three framework lessons.

**3 ·** **Position 8 of `ai`, with three courses behind it and two in front.** `prompt-engineering` → `ai-models` → `embeddings-vectors` → here → `agents-mcp` and `llm-observability`. **A five-deep chain, and 330 of the track's hours sit inside it.** A gap anywhere strands the rest.
