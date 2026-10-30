// __tests__/planner.test.ts: the rules, checked with no screen at all.
import data from "../src/courses.json";
import { addSession, markDone, mondayOf, weekTotal, type Plan } from "../src/planner";

const plan: Plan = data;

test("a week starts on Monday", () => {
  expect(mondayOf("2026-10-21")).toBe("2026-10-19");
  expect(mondayOf("2026-10-25")).toBe("2026-10-19");
});

test("the week's total counts planned and done minutes", () => {
  expect(weekTotal(plan, "2026-10-19")).toEqual({ planned: 125, done: 75 });
});

test("marking a session done moves the done total", () => {
  expect(weekTotal(markDone(plan, "s3"), "2026-10-19").done).toBe(95);
});

test("a session for a course that does not exist is refused", () => {
  expect(() => addSession(plan, "chemistry", "2026-10-23", 30)).toThrow("no course chemistry");
});
