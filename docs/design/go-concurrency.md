---
format: 5
course: go-concurrency
---

# go-concurrency

**Go: Concurrency and Testing** · `co-wc7r5ak4` · 70 h declared · intermediate · 30 lessons · `programming` · paid

## Reach

In **1 track** — `backend`(5, choice *Go*).

**Reached through a choice**, never in sequence — so **no course after that fork may assume it was taken**.

**Depends on it:** `go-back`, `go-production`

## Assumes, and leaves ready

**Assumes:** `go` — the language, in full.

**Leaves ready:** concurrency and the standard library, for `go-back` and `go-production`.

## Shape

| | |
|---|---|
| declared hours | 70 h |
| lessons | 30 |
| **hours per lesson** | **2.33** |
| section budget | ~150, about 5.0 a lesson |
| exercises | ~700, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **the Go toolchain, with `-race`** |
| browser · database | no · no |
| exercises **blocked** | **~500 (75%) — and one lesson is unblockable without it**: the race detector cannot be read from a description |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~65 — goroutines against threads, an unbuffered channel rendezvous, fan-out and fan-in, a pipeline closing correctly, a leak |

## Ageing

**None.** The concurrency model has not changed since Go 1.

## Flags

**1 ·** **It is two courses in one file, and the seam is at lesson 17.** Lessons 1 to 16 are concurrency; 17 to 30 are the standard library and testing. Different subjects, different difficulty, no dependency between them. **Second instance in the sweep** after `api-mobile-automation`, and here it is disguised because both halves are "Go".

**2 ·** **Lesson 16 is the course's best exercise and it needs the runtime absolutely.** Running `-race`, reading the output, fixing the race — there is no paper version. Where `git` is publishable degraded, this lesson is not.

**3 ·** **The pivot of the most expensive fork option.** Two dependents, both 70 hours, both behind it, both in the same track position. Nothing else in the catalogue has a language course with a second language course between it and its practical courses.
