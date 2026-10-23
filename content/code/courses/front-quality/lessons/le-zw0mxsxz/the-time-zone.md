---
title: The bug is the time zone
version: 1
---

**`new Date("2026-10-21")` is midnight in London, not midnight where you are.** A date written
with no time is read as UTC, and every `get…` method of a `Date` answers in the computer's own
time zone. This course was recorded in São Paulo, three hours behind UTC, where that midnight is
21:00 on Tuesday the 20th.

So `weekOf` asks the wrong day what day it is. `getDay()` says Tuesday, Monday is one day back, and
the code steps back to 21:00 on Monday the 19th in São Paulo, which is midnight on the **20th** in
UTC. `toISOString()` writes UTC, and prints `2026-10-20`. Every step is correct on its own, and the
answer is a day late.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l02-midnight\" aria-label=\"Two timelines, one above the other, covering Tuesday 20 and Wednesday 21 October 2026. The upper one is UTC, the lower one is São Paulo, three hours behind. new Date(&quot;2026-10-21&quot;) is marked at midnight on the 21st in UTC, and the same instant falls at 21:00 on Tuesday the 20th in São Paulo. getDay() reads the lower line and answers Tuesday, so the week computed from it starts a day late.\"><text x=\"138\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">UTC</text><path d=\"M150 70 L690 70\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M150.0 62 L150.0 78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"154.0\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Tuesday 20</text><path d=\"M420.0 62 L420.0 78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"424.0\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Wednesday 21</text><text x=\"138\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">São Paulo (UTC−3)</text><path d=\"M150 160 L690 160\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M183.75 152 L183.75 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"187.75\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Tuesday 20</text><path d=\"M453.75 152 L453.75 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"457.75\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Wednesday 21</text><path d=\"M420.0 40 L420.0 172\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"420.0\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">new Date(\"2026-10-21\")</text><text x=\"426.0\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">the same instant</text><rect x=\"183.75\" y=\"176\" width=\"270.0\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"318.75\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">getDay() reads this line: Tuesday</text><text x=\"414.0\" y=\"145\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">21:00</text><text x=\"414.0\" y=\"84\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">00:00</text></svg>", "caption": "A date with no time is read as midnight in UTC. Three hours behind, that instant is still the evening before, and every local method answers for the evening before."}
```

The test proves it is the time zone, because it passes in a time zone where the two midnights
fall on the same day:

```
ana@dev:~/planner$ TZ=UTC npm test

> planner@0.0.0 test
> vitest run


 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  3 passed (3)
   Start at  22:31:27
   Duration  150ms (transform 50%, import 29%, tests 12%, worker 9%)
```

`TZ` tells a program which time zone to use, for that one command. In UTC there is nothing to get
wrong, and **a developer in Lisbon or London would have seen this test pass**, shipped the planner,
and heard about it from a student in Brazil. A test that depends on the machine's time zone has
an answer that depends on who runs it.

## The fix

Do every step of the arithmetic in one time zone. A day with no time belongs to no zone at all, so
read it as UTC on purpose and stay in UTC: `getUTCDay` and `setUTCDate` instead of `getDay` and
`setDate`, and `toISOString` stays as it is, because it was already UTC.

```
ana@dev:~/planner$ git diff src/planner.ts
diff --git a/src/planner.ts b/src/planner.ts
index 50c1b3f..979e7ab 100644
--- a/src/planner.ts
+++ b/src/planner.ts
@@ -38,11 +38,11 @@ export function today(now: Date = new Date()): string {
 }
 
 export function weekOf(day: string): [string, string] {
-  const d = new Date(day);
+  const d = new Date(`${day}T00:00:00Z`);
   const monday = new Date(d);
-  monday.setDate(d.getDate() - ((d.getDay() + 6) % 7));
+  monday.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 6) % 7));
   const sunday = new Date(monday);
-  sunday.setDate(monday.getDate() + 6);
+  sunday.setUTCDate(monday.getUTCDate() + 6);
   return [monday.toISOString().slice(0, 10), sunday.toISOString().slice(0, 10)];
 }
 
```

`T00:00:00Z` says midnight in UTC out loud, rather than leaving it to how `Date` reads a bare
date. Now the same three tests in three time zones, Tokyo nine hours ahead, São Paulo three behind,
and Honolulu ten behind:

```
ana@dev:~/planner$ for tz in Asia/Tokyo America/Sao_Paulo Pacific/Honolulu; do echo "== $tz"; TZ=$tz npx vitest run | grep Tests; done
== Asia/Tokyo
      Tests  3 passed (3)
== America/Sao_Paulo
      Tests  3 passed (3)
== Pacific/Honolulu
      Tests  3 passed (3)
```

Green in all of them. **Run a date test in more than one time zone at least once**, because the one
you are in is the one in which your mistakes do not show. `today()` is the opposite case: it must
use the local calendar, because a student's "today" is the date on their own wall, and a test of it
is in the section on mocks and time.

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "Test the week, and compute it in UTC"
```
