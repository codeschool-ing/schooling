---
title: Leaving, with something typed
version: 1
---

**The form asks before throwing away what the person typed**, with the `beforeRemove` listener that
lesson 8 sketched, now for real. It runs whatever way the person leaves: the header's back button, the
iOS swipe, Android's back action, or code calling `goBack`.

Two refinements over the sketch, both visible in the screen:

- **Nothing typed, nothing asked.** `dirty` is true only when a field has something in it.
- **After a successful save, nothing asked.** The screen sets `saved.current = true` before going back.
  It is a ref rather than state on purpose: the save goes back in the same function, before React would
  have rendered a new value of state, and a listener reading stale state would ask *Discard this
  session?* about a session that was just saved.

On the web, `Alert.alert` from `react-native-web` shows nothing, so the listener would block the
navigation with no question asked. An app that ships its web build uses `window.confirm` there, chosen
with `Platform.OS`, which is a difference of lesson 6's kind; the planner's web build is a stand-in for
this course, and the tests below exercise the phones' behaviour.

## Four tests

Save this as `__tests__/AddSession.test.tsx`:

```tsx
// __tests__/AddSession.test.tsx: the form refuses, saves, reports the server, and asks before discarding.
import { createNavigationContainerRef, NavigationContainer } from "@react-navigation/native";
import { act, fireEvent, render, screen } from "@testing-library/react-native";
import { Alert } from "react-native";
import data from "../src/courses.json";
import { createSession, fetchPlan } from "../src/api";
import { RootNavigator, type RootParams } from "../src/navigation";
import { withPlan } from "../test-utils";

jest.mock("../src/api");
const nav = createNavigationContainerRef<RootParams>();

async function openForm() {
  jest.clearAllMocks();
  jest.mocked(fetchPlan).mockResolvedValue(structuredClone(data)); // what the plan is refetched as
  await render(withPlan(<NavigationContainer ref={nav}><RootNavigator /></NavigationContainer>));
  await fireEvent.press(screen.getByRole("button", { name: /^Guitar/ }));
  await fireEvent.press(screen.getByRole("button", { name: "Add a session" }));
}

test("wrong entries are refused with a sentence each, and nothing is sent", async () => {
  await openForm();
  await fireEvent.changeText(screen.getByLabelText("Date"), "23/10/2026");
  await fireEvent.changeText(screen.getByLabelText("Minutes"), "300");
  await fireEvent.press(screen.getByRole("button", { name: "Save session" }));
  expect(screen.getAllByRole("alert").map((a) => a.props.children)).toEqual([
    "Write the date as YYYY-MM-DD, for example 2026-10-23.",
    "A session is between 5 and 240 minutes.",
  ]);
  expect(createSession).not.toHaveBeenCalled();
});

test("a good session is sent as numbers, and the form closes", async () => {
  jest.mocked(createSession).mockResolvedValue({ id: "s7", course: "guitar", date: "2026-10-23", minutes: 25, done: false });
  await openForm();
  await fireEvent.changeText(screen.getByLabelText("Date"), "2026-10-23");
  await fireEvent.changeText(screen.getByLabelText("Minutes"), "25");
  await fireEvent.press(screen.getByRole("button", { name: "Save session" }));
  expect(createSession).toHaveBeenCalledWith({ course: "guitar", date: "2026-10-23", minutes: 25 });
  expect(nav.getCurrentRoute()?.name).toBe("Course");
});

test("a refusal from the server is shown, and the form stays", async () => {
  jest.mocked(createSession).mockRejectedValue(new Error("POST /sessions answered 503"));
  await openForm();
  await fireEvent.changeText(screen.getByLabelText("Date"), "2026-10-23");
  await fireEvent.changeText(screen.getByLabelText("Minutes"), "25");
  await fireEvent.press(screen.getByRole("button", { name: "Save session" }));
  expect(await screen.findByText("The server refused it: POST /sessions answered 503")).toBeOnTheScreen();
  expect(nav.getCurrentRoute()?.name).toBe("AddSession");
});

test("leaving with something typed asks first", async () => {
  const ask = jest.spyOn(Alert, "alert");
  await openForm();
  await fireEvent.changeText(screen.getByLabelText("Minutes"), "25");
  await act(async () => nav.goBack());
  expect(ask).toHaveBeenCalledWith("Discard this session?", "What you typed will be lost.", expect.any(Array));
  expect(nav.getCurrentRoute()?.name).toBe("AddSession");
});
```

`createNavigationContainerRef` gives the test a handle on the navigation, to ask which screen is current
and to call `goBack` the way the system would. `jest.spyOn(Alert, "alert")` records the question instead
of showing it. The plan is refetched after a save, so each test also says what the server would answer.

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npx jest AddSession --forceExit
PASS __tests__/AddSession.test.tsx
  ✓ wrong entries are refused with a sentence each, and nothing is sent (315 ms)
  ✓ a good session is sent as numbers, and the form closes (115 ms)
  ✓ a refusal from the server is shown, and the form stays (95 ms)
  ✓ leaving with something typed asks first (87 ms)

Test Suites: 1 passed, 1 total
Tests:       4 passed, 4 total
Snapshots:   0 total
Time:        1.645 s, estimated 7 s
Ran all test suites matching AddSession.
Force exiting Jest: Have you considered using `--detectOpenHandles` to detect async operations that kept running after all tests finished?
```

The first test checks both sentences, word for word, and that **nothing was sent**; the second that the
minutes are sent as a number, `25`, not `"25"`; the third that a refusal is shown and the form stays,
with what was typed; the fourth that leaving asks.
