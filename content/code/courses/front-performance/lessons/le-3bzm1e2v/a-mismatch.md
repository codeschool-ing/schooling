---
title: A mismatch, made on purpose
version: 1
---

**24 October 2026 is a Saturday, and the person in São Paulo was told it is a Friday.** The server was
right and the browser was wrong, and the browser's version is the one on the screen, because the
script drew over the server's page when the two disagreed. Two bugs met here, and they are worth
separating, because each one is common on its own.

## Why the browser said Friday

`new Date("2026-10-24")` does not mean "the 24th of October" to JavaScript. A date written as
`YYYY-MM-DD` is read as **midnight in UTC** on that day. `toLocaleDateString` then shows that instant
in the reader's own time zone. In UTC, which the server ran in, midnight on the 24th is the 24th. In
São Paulo, three hours behind, the same instant is 21:00 on the 23rd, a Friday.

So the same function, with the same input, gives different answers on two computers, and the
difference is not in the code. **Anything that depends on where or when it runs is a mismatch waiting
to happen**: the time zone, the language, the current time, a random number, the width of the
window, whether somebody is signed in.

## Why a mismatch matters

In the planner the script noticed, warned and redrew. The person saw the server's *Sat* replaced by
*Fri* a few milliseconds later, which is a flicker and a wrong answer. Each of the four frameworks of
lesson 2 checks for the same thing while it hydrates and reports a mismatch while you develop; what
each does about it in production differs, and has changed between versions, so it is each framework
course's business and not something to rely on.

What is common is the rule: **the server and the browser must compute the same HTML from the same
data**. A difference is never a feature of hydration; it is a bug in the page, and the only good
place to find it is a test that opens the page with a time zone and a language that differ from the
server's, which is exactly what `hydrate.ts` did.

## The fix

A calendar date has no time zone, so show it as one. `timeZone: "UTC"` tells `toLocaleDateString` to
show the instant in UTC, the zone the date was read in, on every computer. In `src/view.ts`, change
the line that defines `day`:

```typescript
const day = (date: string) => `${new Date(date).toLocaleDateString("en-GB", { weekday: "short", timeZone: "UTC" })} ${date}`;
```

Build again, restart `server.ts` with `TZ=UTC`, and open the page from São Paulo once more:

```
ana@dev:~/planner$ node tools/hydrate.ts http://localhost:3000/courses/git
painted at 108 ms, taken over by the script at 76 ms
Sat 2026-10-24 · 25 min Mark done
Tue 2026-10-27 · 40 min Mark done
```

**No warning, and Saturday on both sides.** The same mistake in `mondayOf` would have put a session in
the wrong week, and it never did, because lesson 1 wrote `planner.ts` to do its date arithmetic in UTC
from the start. Lesson 1's comment above `mondayOf` says why: a date is a calendar day.
