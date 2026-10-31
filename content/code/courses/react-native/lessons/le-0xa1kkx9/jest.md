---
title: A stand-in for your own module
version: 1
---

The project compiles. Jest does not:

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npx jest PlanScreen --forceExit 2>&1 | grep -A2 "●"
  ● Test suite failed to run

    Cannot find native module 'WeekStart'
```

**Jest has no native side, and this module is nobody else's, so nobody wrote it a stand-in.** The fix is
the same as for `expo-notifications` in lesson 16, but smaller: replace the one file that calls
`requireNativeModule`, and leave the types and the day names real. At the end of `jest.setup.ts`:

```ts
// jest.setup.ts: runs before every test file.
// The libraries' own stand-ins: there is no native side in Jest to measure or to ask.
jest.mock("react-native-safe-area-context", () => require("react-native-safe-area-context/jest/mock").default);
jest.mock("@react-native-community/netinfo", () => require("@react-native-community/netinfo/jest/netinfo-mock.js"));
// Reanimated 4.7 cannot start inside jest-expo 58, not even as its own stand-in, so the one
// component that uses it is replaced by its children. The rule it applies is tested on its own.
jest.mock("./src/SwipeRow", () => ({ SwipeRow: ({ children }: { children: unknown }) => children }));
// AsyncStorage's own stand-in keeps everything in memory, so every test file starts with nothing stored,
// and SQLite is Node's own, for real: see test-sqlite.tsx.
jest.mock("@react-native-async-storage/async-storage", () =>
  require("@react-native-async-storage/async-storage/jest/async-storage-mock"),
);
jest.mock("expo-sqlite", () => require("./test-sqlite"));
// expo-notifications has no native side here, and setNotificationHandler fails without one. The stand-in
// has the functions the planner calls; a test that cares says what they answer.
jest.mock("expo-notifications", () => ({
  setNotificationHandler: jest.fn(),
  getLastNotificationResponseAsync: jest.fn(async () => null),
  addNotificationResponseReceivedListener: jest.fn(() => ({ remove: jest.fn() })),
  cancelAllScheduledNotificationsAsync: jest.fn(async () => {}),
  scheduleNotificationAsync: jest.fn(async () => "id"),
  setNotificationChannelAsync: jest.fn(async () => null),
  requestPermissionsAsync: jest.fn(),
  SchedulableTriggerInputTypes: { DATE: "date" },
  AndroidImportance: { DEFAULT: 5 },
}));
// A local native module has no stand-in but the one we write. Sunday, so a test sees a day the planner's
// own weeks do not start on.
jest.mock("./modules/week-start/src/WeekStartModule", () => ({ __esModule: true, default: { firstWeekday: () => 0 } }));
```

The stand-in answers Sunday, a day the planner's weeks do not start on, so a test can tell the phone's
answer from the planner's own. Save `__tests__/weekStart.test.tsx`:

```tsx
// __tests__/weekStart.test.tsx: the Courses tab says what the phone's calendar answered.
import { NavigationContainer } from "@react-navigation/native";
import { render, screen } from "@testing-library/react-native";
import { RootNavigator } from "../src/navigation";
import { withPlan } from "../test-utils";

test("the note names the phone's first day of the week", async () => {
  await render(withPlan(<NavigationContainer><RootNavigator /></NavigationContainer>));
  expect(screen.getByText(/starts the week on Sunday;/)).toBeOnTheScreen();
});
```

```
ana@dev:~/planner$ npx jest weekStart PlanScreen --verbose --forceExit 2>&1 | grep -E "✓|Tests:"
  ✓ the note names the phone's first day of the week (209 ms)
  ✓ every course is a button named for what it holds, beside the two tabs (190 ms)
Tests:       2 passed, 2 total
```

**This tests what JavaScript does with the answer, and only that.** Whether Kotlin gives the right
answer is a question for Kotlin, and the next section asks it there.
