---
title: Fixing it at the door
version: 1
---

**`weekTotal` was not wrong; it trusted a value nobody had checked.** The server is another program,
deployed on its own schedule, and anything it sends can change shape. The place to check is where its
answer comes in, once, so that every screen behind it can trust the plan it is given. In `src/api.ts`,
`fetchPlan` checks before it returns:

```ts
// src/api.ts: the requests the planner makes, and nothing about screens.
import type { Plan, Session } from "./planner";

const BASE = process.env.EXPO_PUBLIC_API_URL ?? "http://localhost:8008";

async function json<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(BASE + path, init);
  if (!res.ok) {
    const body = await res.json().catch(() => null); // a refusal may explain itself
    throw new Error(body?.error ?? `${init?.method ?? "GET"} ${path} answered ${res.status}`);
  }
  return (await res.json()) as T;
}

export type NewSession = { course: string; date: string; minutes: number };

// The server is another program, deployed on its own schedule: what it sends is checked, not trusted.
function isPlan(x: unknown): x is Plan {
  const p = x as Plan | null;
  return typeof p === "object" && p !== null && Array.isArray(p.courses) && Array.isArray(p.sessions);
}

export async function fetchPlan(): Promise<Plan> {
  const plan = await json<unknown>("/plan");
  if (!isPlan(plan)) throw new Error("the server sent a plan this version of the planner cannot read");
  return plan;
}

export const sendDone = (id: string) => json<Session>(`/sessions/${id}/done`, { method: "POST" });
export const createSession = (s: NewSession) =>
  json<Session>("/sessions", { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(s) });
```

**`isPlan` checks only what the app relies on**: two arrays. It is a *type guard*: when it returns true,
TypeScript treats the value as a `Plan` from then on. A thorough check of every field is what libraries
such as Zod do, and for a larger API it is worth it. A plan that fails throws an error with a sentence, and
the error goes where every failed request of lesson 10 goes: TanStack Query retries, then shows *The plan
could not be loaded* with the reason.

Two tests, with `fetch` replaced for each. Save `__tests__/api.test.ts`:

```ts
// __tests__/api.test.ts: a plan in a shape the app cannot read is refused at the door, with a sentence.
import { fetchPlan } from "../src/api";

const answer = (body: unknown) =>
  jest.spyOn(globalThis, "fetch").mockResolvedValue(new Response(JSON.stringify(body), { status: 200 }));

test("a plan with courses and sessions is accepted", async () => {
  answer({ courses: [], sessions: [] });
  await expect(fetchPlan()).resolves.toEqual({ courses: [], sessions: [] });
});

test("a plan whose sessions were renamed is refused", async () => {
  answer({ courses: [], items: [] });
  await expect(fetchPlan()).rejects.toThrow("cannot read");
});
```

Then the same broken server again, against a new export:

```
ana@dev:~/planner$ npx jest api.test --verbose --forceExit 2>&1 | grep -E "✓|Tests:"
  ✓ a plan with courses and sessions is accepted (334 ms)
  ✓ a plan whose sessions were renamed is refused (2 ms)
Tests:       2 passed, 2 total
ana@dev:~/planner$ node crash.mjs 'http://localhost:8082/?today=2026-10-21'
screen: The plan could not be loaded: the server sent a plan this version of the planner cannot read
ana@dev:~/planner$ npx jest --forceExit 2>&1 | tail -5
Tests:       62 passed, 62 total
Snapshots:   0 total
Time:        9.362 s
Ran all test suites.
Force exiting Jest: Have you considered using `--detectOpenHandles` to detect async operations that kept running after all tests finished?
```

**A crash became a sentence.** The person sees that the plan could not be read and can try again later; the
team sees exactly which version could not read what. That message took a few seconds to appear, because
TanStack Query tried three more times first, which is the right thing for a network and the wrong thing for
a server that will answer the same way every time. *Telling the two apart, and not retrying a refusal, is a
small change to the query's `retry` option that this course leaves to you.*
