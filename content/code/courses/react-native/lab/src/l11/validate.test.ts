// __tests__/validate.test.ts: each refusal, and its sentence.
import { validate } from "../src/validate";

test("a good draft has no errors", () => {
  expect(validate({ date: "2026-10-23", minutes: "25" })).toEqual({});
});

test.each([
  ["23/10/2026", "25", "date"],
  ["2026-02-30", "25", "date"],
  ["2026-10-23", "", "minutes"],
  ["2026-10-23", "2.5", "minutes"],
  ["2026-10-23", "300", "minutes"],
])("date %s and minutes %s are refused for %s", (date, minutes, field) => {
  expect(Object.keys(validate({ date, minutes }))).toEqual([field]);
});
