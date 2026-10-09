---
format: 5
course: ai-security
---

# ai-security

**AI Security: Defending LLM Applications** · `co-qx0k8g73` · 56 h declared · advanced · 25 lessons · `ai` · paid

## Reach

In **3 tracks** — `ai`(11), `prompt`(4), `security`(17).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** `prompt-engineering` — injection is lesson 7 there, and this course takes it as known and teaches what stands in its way.

**Leaves ready:** **nothing.** No course requires it.

## Shape

| | |
|---|---|
| declared hours | 56 h: 27 for the first twelve, at the same 2.25 for the thirteen after them |
| lessons | 25 |
| **hours per lesson** | **2.25** |
| section budget | ~130, about 5 a lesson |
| exercises | ~455, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **an API key with a bill attached** — a metered third party, not a machine. The course's lab stands in for it with declared stand-ins |
| browser · database | no · no |
| exercises **blocked** | **~350 (70%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~45 — the attack surface drawn whole, the filter chain a reply passes through, a tool call held for confirmation, the OWASP list as a map, a trust boundary on a data-flow diagram, a request answered with the reader's permissions, an incident's timeline |

## Ageing

**Low, unusually for this category.** Attacks and defences outlive the models they are aimed at, and only lesson 6 names a product class rather than a product.

## Flags

**1 ·** **The only course in the category with real reach, and the reason is that it is security rather than AI.** Three tracks — `ai`(11), `prompt`(4) and `security`(17). Every other course here except `ai-dev` sits in one. It is also the one whose material ages slowest, which makes it the best-value course in `ai` on both axes at once.

**2 ·** **It is a defender's course, and it was designed as twenty-two lessons with red teaming in the middle.** Ten topics — direct and indirect injection, jailbreaks, leaking the system prompt, poisoning, tool misuse, and the four red-team lessons from scope to report — were taken out in October 2026. The material here is written by a model, and the automatic safety filter that watches what it writes stopped every attempt at those lessons, including the four about process alone. What remains is coherent on its own: where an LLM application is exposed, how to measure the risks, and the defences that hold. Red teaming belongs in the `security` track's own courses, written by whoever can write it.

**3 ·** **And it is made larger on the defending side instead.** Thirteen lessons were added after the first twelve, in October 2026, so that the course stays complete without the ten: lessons 13 to 19 design the application — a threat model, instructions kept apart from the text the model reads, authorisation around the model, memory, secrets, budgets, the provider — and lessons 20 to 25 operate it: prompts as code, the user's side of the screen, monitoring, regression tests in CI, incident response and governance. They come after lesson 12 rather than among the first twelve because those cite one another by number nearly a hundred times, and renumbering them is a way to make every one of those citations wrong at once. Each new lesson names the threat it answers at the level a defender needs to recognise it, and shows the defence measured in the lab, never the attack. Three more were planned and are not here — uploaded files, what goes into a retrieval index, and rendering a model's output safely in a page — because the safety filter stopped the work as it reached them, and a lesson that cannot be finished is left out rather than shipped half written. Lesson 14's two boundaries are what the course says about an uploaded file; `LLM04` and `LLM08` stay uncovered on lesson 4's map, which says so.

**4 ·** **Lesson 12 is the LGPD applied to third-party models**, which dates on a legislature's schedule rather than a vendor's — the same property `data-governance` has, and the second course in the catalogue with it.
