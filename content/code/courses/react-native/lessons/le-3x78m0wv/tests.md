---
title: Tests, with no phone
version: 1
---

**Jest runs your components in Node.js, with no screen.** `jest-expo` configures it for an Expo
project, including stand-ins for the native modules that do not exist in Node, and React Native
Testing Library renders components, finds elements by what a person sees (a text, a role, a label) and
presses them. Every lesson from 4 to 19 checks its work this way, because it is quick, exact, and
runs on any computer.

## Two test files

The first tests the rules, which need no rendering at all. Save it as `__tests__/planner.test.ts`:

```typescript
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
```

The second renders the whole app and reads it. Save it as `__tests__/App.test.tsx`:

```tsx
// __tests__/App.test.tsx: the first screen, rendered with no phone and no browser.
import { render, screen } from "@testing-library/react-native";
import App from "../App";

test("the first screen shows this week's total", async () => {
  jest.useFakeTimers({ now: new Date("2026-10-21T12:00:00Z") });
  await render(<App />);
  expect(screen.getByRole("heading")).toHaveTextContent("Study planner");
  expect(screen.getByText("This week: 75 of 125 minutes done")).toBeOnTheScreen();
});
```

`render` is awaited because React Native Testing Library 14 renders the way React does in an app,
asynchronously. `jest.useFakeTimers({ now })` replaces the clock, so the test sees the course's week
whatever day it runs; without it, `src/today.ts` reads the real date and the total changes every
Monday. `getByRole("heading")` finds the element whose role is heading, as a screen reader would, and
fails if there is none or more than one.

## Running them

Jest needs to be told to use the preset. Add these two entries to `package.json` with npm, which
edits the file for you:

```sh
npm pkg set scripts.test=jest jest.preset=jest-expo
```

Then:

```
ana@dev:~/planner$ npm pkg get scripts.test jest
{
  "scripts.test": "jest",
  "jest": {
    "preset": "jest-expo"
  }
}
ana@dev:~/planner$ npm test

> planner@1.0.0 test
> jest

PASS __tests__/App.test.tsx
PASS __tests__/planner.test.ts

Test Suites: 2 passed, 2 total
Tests:       5 passed, 5 total
Snapshots:   0 total
Time:        0.848 s, estimated 1 s
Ran all test suites.
```

Five tests in two files, all passing, in about four seconds. **A test that renders the app and finds
the total proves more than a screenshot would**: it proves the number is computed from the data, that
the heading is announced as one, and it will say so the day either stops being true.

When a test fails, Jest prints what it expected, what it received, and the line. Change `125` to `120`
in the first file and run `npm test` again to see one; then change it back.
