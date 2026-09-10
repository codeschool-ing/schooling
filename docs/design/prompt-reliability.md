---
format: 5
course: prompt-reliability
---

# prompt-reliability

**Reliable Prompts: Evaluation and Good Practice** · `co-sh3qqvjw` · 50 h declared · intermediate · 21 lessons · `ai` · paid

## Reach

In **2 tracks** — `ai`(5), `prompt`(3).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** `prompt-engineering` — every technique it makes reliable was introduced there.

**Leaves ready:** **nothing.** No course requires it.

## Shape

| | |
|---|---|
| declared hours | 50 h |
| lessons | 21 |
| **hours per lesson** | **2.38** |
| section budget | ~107, about 5.1 a lesson |
| exercises | ~500, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **an API key with a bill attached** — a metered third party, not a machine, plus a test harness that calls it repeatedly |
| browser · database | no · no |
| exercises **blocked** | **~350 (70%)** — reliability is measured over many runs, which means many calls |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~45 — a prompt versioned across changes, a scoring rubric, an ensemble voting, a calibration curve |

## Ageing

**Low.** It teaches discipline rather than products, and names almost none.

## Flags

**1 ·** **It overlaps `prompt-engineering` and the two are adjacent in both tracks that reach them.** Few-shot examples (its lesson 1) is lessons 20 and 21 there; temperature and top-p (lesson 8) is lessons 13 and 14; injection (lesson 10) is lesson 7. `ai` reaches them at 4 and 5, `prompt` at 2 and 3 — **back to back in both**. The overlap is defensible as deliberate reinforcement and indefensible as an accident, and nothing in either course says which it is. **Whoever writes the second should read the first**, which is the third time the sweep has had to write that sentence.

**2 ·** **Lesson 13 is the technique this platform has refused, and the course should say so honestly.** *"LLM as judge: model-based evaluation and its limits"* is exactly the mechanism that would grade the prose exercises `management` cannot grade — and `PLAN.md`'s founding constraint is that without a human reviewer the only thing between a wrong answer key and a student is **automatic verification**, which a non-deterministic judge is not. So the catalogue teaches a technique its own platform declines to use, for a reason the course itself is about. **That is material, not embarrassment** — the limits half of that lesson title is a real argument with a real example behind it.

**3 ·** **The most gradeable half of the category.** Versioning prompts, test sets, measuring format and correctness, latency and cost — these produce numbers, and `numeric` grades numbers. Lessons 11 to 17 are publishable against the graders that exist.
