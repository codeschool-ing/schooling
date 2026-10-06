---
title: all, allSettled, race and any
version: 1
---

`Promise.all` has three siblings, and **they differ in what they do when some of the promises fail**.
Three mirrors of a book catalogue, one of which is down:

```javascript
const wait = (ms, v) => new Promise((ok) => setTimeout(() => ok(v), ms));
const fail = (ms, m) => new Promise((_, no) => setTimeout(() => no(new Error(m)), ms));

const jobs = () => [wait(300, "mirror A"), fail(100, "mirror B is down"), wait(200, "mirror C")];

try {
  await Promise.all(jobs());
} catch (e) {
  console.log("all:       ", e.message);
}

const settled = await Promise.allSettled(jobs());
console.log("allSettled:", settled.map((r) => r.status === "fulfilled" ? r.value : `(${r.reason.message})`));

try {
  console.log("race:      ", await Promise.race(jobs()));
} catch (e) {
  console.log("race:       rejected,", e.message);
}

console.log("any:       ", await Promise.any(jobs()));
```

```
ana@dev:~/js$ node combinators.mjs
all:        mirror B is down
allSettled: [ 'mirror A', '(mirror B is down)', 'mirror C' ]
race:       rejected, mirror B is down
any:        mirror C
```

| | waits for | succeeds when | fails when |
|---|---|---|---|
| **`all`** | every promise | **all** fulfil, giving every value in order | **any one** rejects, at once |
| **`allSettled`** | every promise | always, giving each one's outcome | never |
| **`race`** | the first to settle | the first settles by fulfilling | the first settles by rejecting |
| **`any`** | the first to fulfil | **any one** fulfils | every one rejects |

Read the output against the table. **`all` failed as soon as mirror B did**, after 100 ms, without
waiting for the others. `allSettled` reported all three, with B's reason in place of a value. `race`
took the first to settle, which was B's failure. `any` ignored the failure and took the first success,
**mirror C, at 200 ms, ahead of A at 300**.

Each has its use: `all` when you need every result, `allSettled` for a report of what worked,
`any` for the fastest working copy of the same thing, and `race` for a timeout, racing the real
work against a promise that rejects after a while. Lesson 16 does the timeout with the tool built for
it, `AbortSignal.timeout`.
