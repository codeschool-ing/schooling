---
format: 5
course: secure-code
---

# secure-code

**Secure Coding** · `co-7mjsrkbg` · 60 h declared · intermediate · 20 lessons · `security` · paid

## Reach

In **2 tracks** — `devsecops`(8), `security`(8).

**Depends on it:** `threat-modeling`

## Assumes, and leaves ready

**Assumes:** `attacks-threats` — you cannot defend against an injection you have not seen work.

**Leaves ready:** secure development, for `threat-modeling`.

## Shape

| | |
|---|---|
| declared hours | 60 h |
| lessons | 20 |
| **hours per lesson** | **3.00** |
| section budget | ~129, about 6.5 a lesson |
| exercises | ~610, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **an application with known flaws, that resets** — authored material rather than an environment, and a language to fix it in |
| browser · database | **yes** — CSP, SameSite and DOM-based XSS are browser behaviour · **yes** |
| exercises **blocked** | **~350 (55%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~55 — escaping by context shown four ways, a CSRF token flow, a session lifecycle, an IDOR drawn as two requests |

## Ageing

**Low.** OWASP ASVS revises slowly and the flaws do not change. The framework-specific half of "using an ORM correctly" is the part that dates.

## Flags

**1 ·** **The most directly useful course in the category for the largest audience**, and it reaches only two tracks. Every developer in the catalogue writes the code this course is about, and `backend`, `frontend` and `mobile` never reach it. That is a catalogue-shape observation rather than a defect to fix in this sheet — but it is the clearest case found of valuable material fenced inside a specialist track.

**2 ·** **It shares the language problem `design-patterns` has, in a milder form.** Parameterised queries, escaping and session handling look different in every language, and this course names none — it is reached from `security` and `devsecops`, whose students arrive from anywhere. **Pseudocode fails here worse than in `design-patterns`**, because the whole point is the exact call. Naming one language and saying so on the first page is the honest option.

**3 ·** **Lesson 19 is where this course meets `secure-pipeline`** — automated security testing inside the project — and lesson 17 is dependencies, which is `secure-pipeline`'s lesson 5. Two lessons of overlap between a course and its own grand-dependent, and the ordering means this one should introduce and that one should operate.
