---
format: 5
course: html-css
---

# html-css

**HTML and CSS** · `co-8t9zrmc7` · 70 h declared · beginner · 13 lessons · `frontend` · paid

## Reach

In **3 tracks** — `backend`(2), `frontend`(2), `qa`(6).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** `web-fundamentals` — what a browser does, before what to send it.

**Leaves ready:** **nothing** by name, and in practice everything: `javascript` manipulates the DOM this course builds, and all four framework courses render into it.

## Shape

| | |
|---|---|
| declared hours | 70 h |
| lessons | 13 |
| **hours per lesson** | **5.38** |
| section budget | ~150, about 11.5 a lesson |
| exercises | ~700, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **a browser** |
| browser · database | **yes, and it is the whole environment** · no |
| exercises **blocked** | **~400 (55%), and blocked differently from everything else in the sweep** — see flag 1 |
| exercises that would **improve** | the remainder |
| diagrams to draw | **~90** — the box model, specificity resolved, every flex axis, grid areas, each position value, container queries. The pictures are the subject |

## Ageing

**Low.** Grid and flexbox are settled; lesson 13 is Tailwind and is the one that moves.

## Flags

**1 ·** **Its exercises produce a *picture*, and no grader looks at one.** "Does this layout centre" is not a string comparison, an ordering or a number. `expected-output` would not help even if it existed, because the output is rendered rather than printed. **This is a third missing answer type**, after prose (`management`) and diagrams (`architecture-modeling`, `threat-modeling`) — and it is the one with a mechanical answer available: **a screenshot diffed against a reference**, which is what `tools/graph-test` and `tools/landing-test` already do in this repository.

**2 ·** **Thirteen lessons for seventy hours — 11.5 sections each.** Lesson 9 is the whole of CSS Grid. Wide, and in three tracks — `backend`(2), `frontend`(2) and `qa`(6).

**3 ·** **Position 2 of two tracks, immediately after the free course**, so it is the first thing many students pay for. That is the same position `bi-business` holds in `bi`, and it deserves the same attention for the same reason.
