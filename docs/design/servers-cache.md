---
format: 5
course: servers-cache
---

# servers-cache

**Web Servers and Caching** · `co-1n9pdshv` · 50 h declared · intermediate · 11 lessons · `backend` · paid

## Reach

In **2 tracks** — `backend`(8), `devops`(6).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** `linux-terminal` — a shell to configure a server from.

**Leaves ready:** **nothing.** No course requires it.

## Shape

| | |
|---|---|
| declared hours | 50 h |
| lessons | 11 |
| **hours per lesson** | **4.55** |
| section budget | ~107, about 9.7 a lesson |
| exercises | ~500, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **a web server and Redis** |
| browser · database | no · no — a cache instead |
| exercises **blocked** | **~350 (70%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~50 — a reverse proxy in front of two origins, the cache lifecycle with `ETag`, CDN edge and origin, a stampede drawn as a spike |

## Ageing

**Low.** Nginx, Redis and HTTP caching are all long-settled.

## Flags

**1 ·** **Eleven lessons for fifty hours — 9.7 sections each**, and the subject genuinely divides in two: lessons 1 to 4 are the server, 5 to 11 are caching. A hinge rather than an arc.

**2 ·** **Lesson 11 is the hardest idea and it is last** — cache stampede and warming. Everything before it is configuration; that lesson is the one a reader will meet in production. Worth the weight the position does not suggest.

**3 ·** **Two tracks — `backend`(8) and `devops`(6) — and it is one of the few backend courses that escapes its own track.** No dependents, and its prerequisite `linux-terminal` is the free ten-track course from `infra`.
