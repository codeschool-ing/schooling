---
format: 5
course: front-multiplatform
---

# front-multiplatform

**Desktop and Mobile Apps with Web** · `co-stctzkdq` · 50 h declared · intermediate · 16 lessons · `frontend` · paid

## Reach

In **1 track** — `frontend`(10).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** **nothing declared.** Position 10 of `frontend`, the last subject course, after the fork.

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
| runtime | **Node, and the platform toolchains it wraps** — including, for the iOS half, a Mac |
| browser · database | **yes** · no |
| exercises **blocked** | **~350 (70%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~45 — the wrapper against the native path, Capacitor's bridge, Electron's two processes, the signing chain |

## Ageing

**Moderate to severe.** Capacitor, Expo, Tauri and Electron all move, and the store requirements they package for move independently.

## Flags

**1 ·** **It reaches the same wall `ios-apps` does, and only for part of the course.** Lessons 3 and 14 need Xcode and a signing identity; everything else — Capacitor, Electron, Tauri, the Android side — does not. **Declare the boundary** rather than let a student find it at the packaging lesson.

**2 ·** **Lesson 6 is the most valuable in the course and the easiest to leave out** — *"What a wrapped app cannot do, and finding that out before the store does"*. It is the lesson that stops the reader making an expensive mistake, and it is judgement rather than technique.

**3 ·** **Lesson 16 is a portfolio project, and `frontend` reaches `portfolio-project` one position later.** *"Final project: an app published in your portfolio"* at position 10, then the portfolio course at 11. **Second instance of this collision** after `data-storytelling` lesson 16 in `bi` — and here the two are adjacent, which makes it starker.
