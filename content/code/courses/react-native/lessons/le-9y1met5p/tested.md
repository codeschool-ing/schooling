---
title: Testing without a phone that buzzes
version: 1
---

The project compiles; the tests that render `App` do not:

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npx jest App.test --forceExit 2>&1 | grep -A2 "●"
  ● Test suite failed to run

    TypeError: handleSubscription.remove is not a function
```

**`setNotificationHandler` runs when `App.tsx` is imported**, and in Jest the library has no native side
to register the handler with: the subscription it gets back has no `remove`. The library ships no
stand-in, so the planner writes one, with exactly the functions it calls. Add it to `jest.setup.ts`:

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
```

Each function is a `jest.fn`, so a test can say what it answers and ask how it was called. The two enums
are plain objects with the values the planner uses.

Now `__tests__/reminders.test.ts` asks `remindersFor` about the plan at noon and at seven in the evening,
checks what reached the scheduler, and checks the order of the two calls on Android, with
`jest.replaceProperty` making `Platform.OS` say `"android"` for one test:

```ts
// __tests__/reminders.test.ts: which reminders a plan asks for, and what reaches the phone's scheduler.
import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Notifications from "expo-notifications";
import { Platform } from "react-native";
import data from "../src/courses.json";
import { remindersFor, scheduleReminders, setReminders } from "../src/reminders";

const notifications = jest.mocked(Notifications);
const noon = new Date("2026-10-21T12:00:00"); // local time, as the phone would have it

beforeEach(() => jest.clearAllMocks());

test("one reminder per session not done, at six in the evening of its day", () => {
  const reminders = remindersFor(data, noon);
  expect(reminders.map((r) => r.id)).toEqual(["s3", "s4", "s5", "s6"]);
  expect(reminders[0]).toMatchObject({ title: "Guitar: 20 min today", url: "planner://course/guitar" });
  expect([reminders[0].at.getDate(), reminders[0].at.getHours()]).toEqual([21, 18]);
});

test("a reminder whose time has passed is not asked for", () => {
  expect(remindersFor(data, new Date("2026-10-21T19:00:00")).map((r) => r.id)).toEqual(["s4", "s5", "s6"]);
});

test("scheduling replaces everything that was scheduled before", async () => {
  await scheduleReminders(data, noon);
  expect(notifications.cancelAllScheduledNotificationsAsync).toHaveBeenCalledTimes(1);
  expect(notifications.scheduleNotificationAsync).toHaveBeenCalledTimes(4);
  expect(notifications.scheduleNotificationAsync.mock.calls[0][0]).toMatchObject({
    identifier: "s3",
    content: { data: { url: "planner://course/guitar" } },
    trigger: { type: "date", channelId: "reminders" },
  });
});

test("refused, reminders stay off", async () => {
  notifications.requestPermissionsAsync.mockResolvedValue({ granted: false } as Notifications.NotificationPermissionsStatus);
  expect(await setReminders(true)).toBe("refused");
  expect(await AsyncStorage.getItem("reminders")).toBeNull();
});

test("on Android, the channel exists before the question is asked", async () => {
  jest.replaceProperty(Platform, "OS", "android");
  notifications.requestPermissionsAsync.mockResolvedValue({ granted: true } as Notifications.NotificationPermissionsStatus);
  expect(await setReminders(true)).toBe("on");
  const channel = notifications.setNotificationChannelAsync.mock.invocationCallOrder[0];
  const question = notifications.requestPermissionsAsync.mock.invocationCallOrder[0];
  expect(channel).toBeLessThan(question);
});
```

`invocationCallOrder` is a number Jest gives every call to every mock, in the order they happened, which is
what makes "the channel before the question" a thing a test can check. And `__tests__/tap.test.tsx` finds
the listener the navigation container registered, and taps:

```tsx
// __tests__/tap.test.tsx: tapping a reminder opens the course it names, through the same addresses as a link.
import { NavigationContainer } from "@react-navigation/native";
import * as Notifications from "expo-notifications";
import { act, render, screen } from "@testing-library/react-native";
import { linking, RootNavigator } from "../src/navigation";
import { withPlan } from "../test-utils";

test("a tapped reminder opens its course", async () => {
  await render(withPlan(<NavigationContainer linking={linking}><RootNavigator /></NavigationContainer>));
  const [[onTap]] = jest.mocked(Notifications.addNotificationResponseReceivedListener).mock.calls;
  await act(async () => {
    onTap({ notification: { request: { content: { data: { url: "planner://course/guitar" } } } } } as never);
  });
  expect(screen.getAllByRole("heading").map((h) => h.props.children)).toEqual(["2026-10-21", "2026-10-28"]);
});
```

```
ana@dev:~/planner$ npx jest reminders tap --verbose --forceExit 2>&1 | grep -E "✓|Tests:"
  ✓ one reminder per session not done, at six in the evening of its day (5 ms)
  ✓ a reminder whose time has passed is not asked for (1 ms)
  ✓ scheduling replaces everything that was scheduled before (2 ms)
  ✓ refused, reminders stay off (5 ms)
  ✓ on Android, the channel exists before the question is asked (1 ms)
  ✓ a tapped reminder opens its course (247 ms)
Tests:       6 passed, 6 total
ana@dev:~/planner$ npx jest --forceExit 2>&1 | tail -5
Tests:       58 passed, 58 total
Snapshots:   0 total
Time:        9.652 s
Ran all test suites.
Force exiting Jest: Have you considered using `--detectOpenHandles` to detect async operations that kept running after all tests finished?
```

**The tap opened the guitar course**, its two dates as the only headings on screen, through the same
`linking` a phone would use.
