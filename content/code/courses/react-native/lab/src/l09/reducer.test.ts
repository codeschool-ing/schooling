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
