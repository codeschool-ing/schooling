---
format: 5
course: front-quality
---

# front-quality

**Testing, Security and Accessibility** · `co-8kbjja72` · 60 h declared · intermediate · 13 lessons · `frontend` · paid

## Reach

In **1 track** — `frontend`(7).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** **nothing declared, and a framework in practice.** Position 7 of `frontend`, after the fork — so it is written for a student holding any of four and names none.

**Leaves ready:** **nothing.** No course requires it.

## Shape

| | |
|---|---|
| declared hours | 60 h |
| lessons | 13 |
| **hours per lesson** | **4.62** |
| section budget | ~129, about 9.9 a lesson |
| exercises | ~610, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **a browser, a test runner and a screen reader** |
| browser · database | **yes** · no |
| exercises **blocked** | **~350 (55%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~55 — the pyramid applied to the front-end, the OAuth flows, CORS failing, tab order over a page, contrast pairs |

## Ageing

**Low.** WCAG and the OWASP list revise slowly; Vitest, Jest, Playwright and Cypress move.

## Flags

**1 ·** **Three subjects in thirteen lessons** — testing (1 to 4), security (5 to 9), accessibility (10 to 13) — and each has a different grader. It is `non-functional-testing`'s shape at half the length, and the two courses cover much the same ground for different readers in different tracks.

**2 ·** **The accessibility third is this repository's own tooling**, exactly as it is in `non-functional-testing`: `tools/a11y-test` runs AXE against the student interface in CI, and lesson 12 is ARIA and screen readers.

**3 ·** **Written to the fork and naming no framework**, like every `front-*` course. Lesson 2 names Vitest and Jest; lesson 4 names Playwright and Cypress — tools, not frameworks. **That is the discipline the whole post-fork half of `frontend` keeps**, and it is what makes the fork work.
