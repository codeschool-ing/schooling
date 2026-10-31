---
title: The plan as state, changed by actions
version: 1
---

**Until this lesson every screen imported the data file itself.** Marking a session done on one screen
could not change the total on another, because each held its own copy. The fix is to keep **one** plan,
as state, at the top of the app, and let every screen read it.

When state changes in more than one way, `useReducer` is clearer than `useState`. You describe each change
as an **action**, a small object saying what happened, and write one function, the **reducer**, that
takes the current plan and an action and returns the next plan. The planner's rules from lesson 3 already
are such functions, so the reducer only routes each action to one of them. Save this as
`src/planState.tsx`:

```schooling-example
{"language": "tsx", "file": "src/planState.tsx", "parts": [{"code": "// src/planState.tsx: the plan as state, changed only by actions, shared by every screen.\nimport { createContext, useContext, useReducer, type Dispatch, type ReactNode } from \"react\";\nimport { addSession, markDone, type Plan } from \"./planner\";\n", "note": "The plan's state needs React's context and reducer hooks, and the rules of lesson 3."}, {"code": "export type Action =\n  | { type: \"done\"; id: string }\n  | { type: \"add\"; course: string; date: string; minutes: number };\n", "note": "**Every change the plan can undergo, as a type.** A union: an action is one shape or the other, and TypeScript knows which fields each carries."}, {"code": "export function planReducer(plan: Plan, action: Action): Plan {\n  switch (action.type) {\n    case \"done\":\n      return markDone(plan, action.id);\n    case \"add\":\n      return addSession(plan, action.course, action.date, action.minutes);\n  }\n}\n", "note": "The reducer: the plan and an action in, the next plan out. Each case hands the work to a rule that already exists, so nothing here can disagree with `src/planner.ts`."}, {"code": "const PlanContext = createContext<{ plan: Plan; dispatch: Dispatch<Action> } | null>(null);\n", "note": "The context, holding the plan and the function that sends actions. `null` until a provider gives it a value."}, {"code": "export function PlanProvider({ initial, children }: { initial: Plan; children: ReactNode }) {\n  const [plan, dispatch] = useReducer(planReducer, initial);\n  return <PlanContext.Provider value={{ plan, dispatch }}>{children}</PlanContext.Provider>;\n}\n", "note": "The provider: `useReducer` keeps the plan, starting from `initial`, and every component below can read it."}, {"code": "export function usePlan() {\n  const value = useContext(PlanContext);\n  if (!value) throw new Error(\"usePlan must be used inside a PlanProvider\");\n  return value;\n}", "note": "The hook screens call. It fails with a sentence, not a crash later, when nobody provided a plan."}]}
```

The file has two halves. This section is the first: the `Action` type and `planReducer`. **A reducer never
changes the plan it is given**, it returns a new one, which is what `markDone` and `addSession` already
do. That is how React knows something changed: the new plan is a different object from the old.

The second half, the context, is the next section's.

## Tested with no screen

Because the reducer is a plain function, its test needs nothing rendered. Save this as
`__tests__/reducer.test.ts`:

```typescript
// __tests__/reducer.test.ts: every change to the plan is an action, checked with no screen.
import data from "../src/courses.json";
import { planReducer } from "../src/planState";
import { weekTotal, type Plan } from "../src/planner";

const plan: Plan = data;

test("marking a session done returns a new plan and leaves the old one alone", () => {
  const next = planReducer(plan, { type: "done", id: "s3" });
  expect(weekTotal(next, "2026-10-19").done).toBe(95);
  expect(weekTotal(plan, "2026-10-19").done).toBe(75);
  expect(next).not.toBe(plan);
});

test("adding a session goes through the same rules as before", () => {
  const next = planReducer(plan, { type: "add", course: "guitar", date: "2026-10-23", minutes: 25 });
  expect(next.sessions.at(-1)).toEqual({ id: "s7", course: "guitar", date: "2026-10-23", minutes: 25, done: false });
  expect(() => planReducer(plan, { type: "add", course: "chemistry", date: "2026-10-23", minutes: 25 })).toThrow("no course chemistry");
});
```

```
ana@dev:~/planner$ npx jest reducer
PASS __tests__/reducer.test.ts
  ✓ marking a session done returns a new plan and leaves the old one alone (4 ms)
  ✓ adding a session goes through the same rules as before (10 ms)

Test Suites: 1 passed, 1 total
Tests:       2 passed, 2 total
Snapshots:   0 total
Time:        0.417 s, estimated 1 s
Ran all test suites matching reducer.
```

The first test also checks the old plan is untouched, `75` minutes done before and `95` after, which is
the property the rest of this lesson depends on. The second checks that the rules of lesson 3 still apply
when a change arrives as an action: `chemistry` is still refused.
