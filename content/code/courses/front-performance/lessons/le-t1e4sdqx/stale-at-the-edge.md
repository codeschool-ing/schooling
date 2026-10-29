---
title: Stale at the edge
version: 1
---

**A page can tell the browser one thing and a shared cache another.** `max-age=0` makes every browser
check, as `no-cache` did; `s-maxage=10` lets a CDN keep the page for ten seconds without asking. In
`server.ts`, change the page branch's call to:

```typescript
  send(req, res, "text/html; charset=utf-8", html, "max-age=0, s-maxage=10");
```

Restart `server.ts`, leave the edge running, and ask for the page three times, the third after the ten
seconds are up:

```
ana@dev:~/planner$ for wait in 0 3 8; do sleep $wait; curl -s -o /dev/null -D - http://localhost:8000/courses/git | grep -iE '^(x-cache|age)'; done
x-cache: MISS
age: 3
x-cache: HIT
x-cache: MISS
```

**MISS, HIT three seconds old, then MISS again**: the copy expired and the edge asked the origin. For those
ten seconds, every visitor's request for that page was answered by the edge, and the server was asked once.

## The price

**For as long as the edge keeps a page, a change to it is not seen.** Rename the Git course in the plan the
server reads, the build's copy in `dist/`, and ask through the edge and straight from the server:

```
ana@dev:~/planner$ curl -s localhost:8000/courses/git > /dev/null; sed -i 's/"title": "Git"/"title": "Git and GitHub"/' dist/courses.json
```

```
ana@dev:~/planner$ for host in localhost:8000 localhost:3000; do curl -s $host/courses/git | grep -o '<h1>[^<]*</h1>'; done
<h1>Git</h1>
<h1>Git and GitHub</h1>
```

**The edge still says *Git*; the server already says *Git and GitHub*.** That is lesson 3's stale page
again, in a cache this time instead of a build, and it is the trade every shared cache makes: speed for
everybody, against a change that takes up to `s-maxage` seconds to arrive. Ten seconds is nothing for a
course title. For a price, a stock level or a cancellation, the right `s-maxage` is zero.

## Purging, and serving stale on purpose

**A real CDN can be told to drop a copy**, a purge, through its API or its dashboard, which is how a
deploy makes a long `s-maxage` safe: the deploy purges what it changed. And **`stale-while-revalidate`**
turns the expiry into a background job: when a copy goes stale, the next visitor is still answered from it
at once, and the CDN fetches a fresh one behind them. Lesson 3's regeneration is that header's idea, and the
next section finds Next.js sending it.

Put the title back with the same `sed`, the two names swapped, before going on, and stop the edge with Ctrl-C.
