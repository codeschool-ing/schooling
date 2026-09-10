---
format: 5
course: llm-observability
---

# llm-observability

**LLM Observability and Evaluation in Production** · `co-qkg01xe0` · 50 h declared · advanced · 16 lessons · `ai` · paid

## Reach

In **1 track** — `ai`(12).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** `rag` — you cannot trace a chain of calls before there is a chain.

**Leaves ready:** **nothing.** No course requires it.

## Shape

| | |
|---|---|
| declared hours | 50 h |
| lessons | 16 |
| **hours per lesson** | **3.12** |
| section budget | ~107, about 6.7 a lesson |
| exercises | ~500, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **an API key with a bill attached** — a metered third party, not a machine, and a tracing service — LangSmith, Langfuse or a self-hosted one |
| browser · database | **yes** — every tool in lessons 6 and 7 is a dashboard · no |
| exercises **blocked** | **~350 (65%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~50 — a trace tree, cost broken down three ways, a quality dashboard, an evaluation set versioned across model changes |

## Ageing

**Moderate to severe.** Lessons 6, 7 and 12 name six SaaS products. Lessons 1 to 5 and 8 to 16 are the discipline, and the discipline is stable.

## Flags

**1 ·** **It is the missing half of the platform's own grading argument, seen from the other side.** Lesson 8 is deterministic evaluation — exact match, format and rules — which is precisely what `internal/grade`'s eight graders do. Lessons 9 to 11 are what you do when that is not enough: sample live traffic, score it against a rubric, measure inter-rater agreement. **The catalogue contains a course on the problem the catalogue has**, and both halves of the answer are in its lesson list.

**2 ·** **Lesson 15 is the one that turns the course from advice into practice** — wiring evaluation into continuous integration. That is the shape this repository already uses for `validate-content`, and it is the lesson most likely to be written as a paragraph when it should be the spine.

**3 ·** **Fifty hours behind four prerequisites, in one track, with nothing after it.** Same shape as `agents-mcp` and the same conclusion: valuable, narrow, and late in any sensible order of writing.
