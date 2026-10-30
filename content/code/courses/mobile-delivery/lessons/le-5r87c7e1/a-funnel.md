---
title: A funnel, from events
version: 1
---

**A funnel counts how many people reached each step of a path, in order, and so shows where they
stop.** For the planner the path is the four events of the last section: open the app, add a
course, plan a session, finish it. Every analytics product draws funnels; here the same thing is
done with a table in SQLite, so every number can be checked.

## The code that records events

Save this as `analytics.ts` in `~/planner`. It uses `better-sqlite3`, installed in lesson 1:

```schooling-example
{"language": "typescript", "file": "analytics.ts", "parts": [{"code": "// analytics.ts: record product events, and refuse any property nobody decided to collect\nimport Database from \"better-sqlite3\";\n\nexport const SCHEMA: Record<string, string[]> = {\n  app_open: [],\n  course_added: [\"course_count\"],\n  session_added: [\"minutes\"],\n  session_done: [\"minutes\"],\n};", "note": "The schema: each event the app may send, and the properties it may carry. It lives in the repository and changes by pull request."}, {"code": "const db = new Database(\"events.db\");\ndb.exec(\"create table if not exists events (install text, name text, props text, at text)\");\nconst insert = db.prepare(\"insert into events values (?, ?, ?, ?)\");", "note": "One table, one row per event. On a phone this would be the queue of events waiting to be sent."}, {"code": "export function track(install: string, name: string, props: Record<string, number> = {}, at: string) {\n  const allowed = SCHEMA[name];\n  if (!allowed) throw new Error(`event ${name} is not in the schema`);\n  const extra = Object.keys(props).filter((k) => !allowed.includes(k));\n  if (extra.length) throw new Error(`event ${name}: property ${extra.join(\", \")} is not in the schema`);\n  insert.run(install, name, JSON.stringify(props), at);\n}\n\nexport { db };", "note": "An unknown event or property is an error, thrown where the code that sent it runs, before anything is written. Properties are numbers by type."}]}
```

## A week of installs

A real week of events comes from phones. This one is made by a short program: 500 installations,
each opening the app on a day of the week of 19 October 2026, then adding a course, planning a
session and finishing it with chances of 70%, 60% and 55%, from a seeded generator, so every run
makes the same week. At the end it tries to send one event with a property the schema does not
have. Save this as `simulate.ts`:

```typescript
// simulate.ts: a week of installs of the planner, as the events they would send
import { db, track } from "./analytics.ts";

let seed = 16;
const random = () => ((seed = (seed * 1103515245 + 12345) % 2147483648) / 2147483648);
db.exec("delete from events");

for (let i = 0; i < 500; i++) {
  const install = `i${String(i).padStart(3, "0")}`;
  const day = `2026-10-${String(19 + (i % 7)).padStart(2, "0")}`;
  track(install, "app_open", {}, `${day}T09:00`);
  if (random() < 0.7) track(install, "course_added", { course_count: 1 }, `${day}T09:02`);
  else continue;
  if (random() < 0.6) track(install, "session_added", { minutes: 30 }, `${day}T09:05`);
  else continue;
  if (random() < 0.55) track(install, "session_done", { minutes: 30 }, `${day}T19:40`);
}
console.log(db.prepare("select name, count(*) as n from events group by name order by n desc").all());

try {
  track("i000", "course_added", { course_count: 2, course_name: 1 }, "2026-10-26T10:00");
} catch (e) {
  console.log(`refused: ${(e as Error).message}`);
}
```

## The funnel

Save this as `funnel.ts`. For each installation it finds the first time of each step, and counts an
installation as having reached a step only if it reached every earlier step first:

```typescript
// funnel.ts: how many installs reached each step, in order, and how many were lost between steps
import Database from "better-sqlite3";

const STEPS = ["app_open", "course_added", "session_added", "session_done"];
const db = new Database("events.db", { readonly: true });
const firsts = db.prepare(`
  select install, ${STEPS.map((s) => `min(case when name = '${s}' then at end) as ${s}`).join(", ")}
  from events group by install`).all() as Record<string, string | null>[];

const pct = (a: number, b: number) => `${Math.round((100 * a) / b)}%`;
const total = firsts.length;
let previous = total;
console.log("step            installs  of previous  of first");
STEPS.forEach((step, i) => {
  const reached = firsts.filter((f) =>
    STEPS.slice(0, i + 1).every((s, j) => f[s] !== null && (j === 0 || f[s]! >= f[STEPS[j - 1]]!)),
  ).length;
  console.log(`${step.padEnd(15)} ${String(reached).padStart(8)}  ${pct(reached, previous).padStart(11)}  ${pct(reached, total).padStart(8)}`);
  previous = reached;
});
```

```
ana@dev:~/planner$ node simulate.ts
[
  { name: 'app_open', n: 500 },
  { name: 'course_added', n: 374 },
  { name: 'session_added', n: 231 },
  { name: 'session_done', n: 127 }
]
refused: event course_added: property course_name is not in the schema
ana@dev:~/planner$ node funnel.ts
step            installs  of previous  of first
app_open             500         100%      100%
course_added         374          75%       75%
session_added        231          62%       46%
session_done         127          55%       25%
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l16-funnel\" aria-label=\"The planner's funnel as four bars. 500 installs opened the app; 374 added a course, 75% of them; 231 planned a session, 62% of those; 127 finished a session, 55% of those and 25% of everybody who opened the app. The largest loss in people is between adding a course and planning a session, 143 installs; the largest loss in share is the last step, 45%.\"><text x=\"150\" y=\"39\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app_open</text><rect x=\"160\" y=\"24\" width=\"400\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"39\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">500</text><text x=\"150\" y=\"85\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">course_added</text><rect x=\"160\" y=\"70\" width=\"299\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"469\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">374</text><text x=\"509\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">75%</text><text x=\"150\" y=\"131\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">session_added</text><rect x=\"160\" y=\"116\" width=\"185\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">231</text><text x=\"395\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">62%</text><text x=\"150\" y=\"177\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">session_done</text><rect x=\"160\" y=\"162\" width=\"102\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"272\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">127</text><text x=\"312\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">55%</text><text x=\"160\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">most people lost: 143 added a course and never planned a session</text><text x=\"160\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">largest share lost: 45% of planners did not study</text></svg>", "caption": "The middle step loses the most people; the last loses the largest share. A funnel tells the two problems apart."}
```

## Reading it

**A quarter of the people who opened the planner finished a session.** The biggest loss, in people,
is in the middle: 143 installations added a course and never planned a session. The biggest loss in
**share** is the last step: 45% of the people who planned a session did not do it. Those two are
different problems, a course screen that does not lead anywhere and a reminder that does not bring
people back, and a funnel is useful precisely because it tells them apart.

The refusal at the end of the simulation is the schema working: `course_name` is the person's own
words, nobody decided to collect it, and the event was never written.
