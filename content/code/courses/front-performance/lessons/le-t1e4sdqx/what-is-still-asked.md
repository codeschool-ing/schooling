---
title: What is still asked every time
version: 1
---

**A 304 is cheap in bytes and costs a full round trip.** On a phone with 300 milliseconds to the server,
four checks that can run in parallel still cost one round trip, and the fonts and the cover the planner
checks every visit have not changed since they were made. Ask Lighthouse what it thinks of them:

```
ana@dev:~/planner$ npm run lighthouse -- http://localhost:3000/courses/git >/dev/null && node tools/report.ts report.report.json | grep -E 'performance|insight'
performance 100, throttling simulate
  insight: Improve image delivery, Est savings of 29 KiB
  insight: Network dependency tree
```

**Use efficient cache lifetimes is gone.** The scripts are kept for a year, and the files sent with
`no-cache` and an ETag are not on its list either: checking is a choice the server made on purpose, and
it costs no body. What no insight counts is the round trip each check still costs a returning visitor,
which is a number only a measurement of the second visit shows, as `revisit.ts` did.

## Two ways out

- **Give the file a hashed name**, and it falls under the first rule. Vite does this for anything the code
  or the CSS imports: a font named in a stylesheet with a relative `url()` is copied into `dist/assets/`
  with a hash. The planner keeps its fonts in `public/` because lesson 7's preload names them by a fixed
  address; a build that also wrote the preload would let them move.
- **Give it a lifetime that fits how often it changes.** A cover redrawn once a year can be kept for a
  week, `max-age=604800`, with its ETag for after. What it costs is the week: a changed cover reaches a
  returning visitor up to seven days late.

**The planner leaves them as they are**, at four 304s on a revisit, and that is a measured choice rather
than an oversight: on this page they run in parallel, the cost is one round trip, and the next lesson adds a
cache that serves them without asking the network at all.
