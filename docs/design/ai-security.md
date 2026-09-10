---
format: 5
course: ai-security
---

# ai-security

**AI Security and Red Teaming** · `co-qx0k8g73` · 50 h declared · advanced · 22 lessons · `ai` · paid

## Reach

In **3 tracks** — `ai`(11), `prompt`(4), `security`(17).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** `prompt-engineering` — injection is lesson 7 there and lessons 2 and 3 here, so the ordering is right and the overlap is deliberate.

**Leaves ready:** **nothing.** No course requires it.

## Shape

| | |
|---|---|
| declared hours | 50 h |
| lessons | 22 |
| **hours per lesson** | **2.27** |
| section budget | ~107, about 4.9 a lesson |
| exercises | ~500, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **an API key with a bill attached** — a metered third party, not a machine, and something deliberately vulnerable to attack |
| browser · database | no · lesson 6 poisons a vector store, so one of those |
| exercises **blocked** | **~350 (70%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~55 — the attack surface drawn whole, an indirect injection arriving through a document, a tool call escaping its permission, the OWASP list as a map |

## Ageing

**Low, unusually for this category.** Attacks and defences outlive the models they are aimed at, and only lesson 16 names a product class rather than a product.

## Flags

**1 ·** **The only course in the category with real reach, and the reason is that it is security rather than AI.** Three tracks — `ai`(11), `prompt`(4) and `security`(17). Every other course here except `ai-dev` sits in one. It is also the one whose material ages slowest, which makes it the best-value course in `ai` on both axes at once.

**2 ·** **It needs a target, and building a deliberately vulnerable application is authored work.** Red teaming (lessons 11 to 14) requires something to attack, with known weaknesses, that resets. That is a fixture in `content/` rather than an environment — **the third course in two batches to need authored adversarial material**, with `rag`'s corpus and `data-cleaning`'s broken tables.

**3 ·** **Lesson 11 is a legal boundary inside a technical lesson** — *"Red teaming: scope, rules of engagement and written authorisation"* — and it is the one lesson that must not be softened. A course that teaches attacks without teaching authorisation is a liability, and it is the lesson most likely to be trimmed for length.

**4 ·** **Lesson 22 is the LGPD applied to third-party models**, which dates on a legislature's schedule rather than a vendor's — the same property `data-governance` has, and the second course in the catalogue with it.
