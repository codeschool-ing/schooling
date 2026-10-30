---
title: A change that shows at once and can be taken back
version: 1
---

**A mutation is a write.** `useMutation` takes the function that makes the request and three hooks that
run around it, and `useMarkDone` in `src/planState.tsx` uses all three:

| hook | when | what the planner does |
|---|---|---|
| `onMutate` | before the request | stops any fetch of `["plan"]` in flight, keeps the plan as it was, and writes the change into the cache **now** |
| `onError` | if the request fails | puts back the plan it kept |
| `onSettled` | after success or failure | invalidates `["plan"]`, so the server's own version is fetched |

**This is an optimistic update**: the screen shows the session done before the server has said anything,
because the server almost always agrees, and waiting for it would make every press feel slow. The change
written into the cache is `planReducer(p, { type: "done", id })`, the reducer of lesson 9, so the
optimistic plan is computed by exactly the rule the server applies. Cancelling queries first matters: a
fetch that was already on its way could otherwise land after the optimistic write and overwrite it with
the old plan.

**When the server refuses, the screen must say so, not only undo.** The planner's `usePlan` returns the
mutation's `error` for that; lesson 11 shows it beside the form that adds sessions.

## Three tests

Save this as `__tests__/done.test.tsx`. Each test marks guitar's session of the 21st done from the *This
week* tab and reads the total on *Courses*:

```tsx
// __tests__/done.test.tsx: marking done shows at once, reaches the server, and is undone if the server refuses.
import { NavigationContainer } from "@react-navigation/native";
import { onlineManager } from "@tanstack/react-query";
import { fireEvent, render, screen, waitFor } from "@testing-library/react-native";
import data from "../src/courses.json";
import { fetchPlan, sendDone } from "../src/api";
import { markDone } from "../src/planner";
import { RootNavigator } from "../src/navigation";
import { withPlan } from "../test-utils";

jest.mock("../src/api");
// What the server holds after the press: the same plan, with s3 done.
beforeEach(() => {
  jest.clearAllMocks();
  jest.mocked(fetchPlan).mockResolvedValue(markDone(structuredClone(data), "s3"));
});
const markGuitar = { name: "Mark 20 min on 2026-10-21 done" };

async function openWeekAndMark() {
  jest.useFakeTimers({ now: new Date("2026-10-21T12:00:00Z") });
  await render(withPlan(<NavigationContainer><RootNavigator /></NavigationContainer>));
  await fireEvent.press(screen.getByText("This week"));
  await fireEvent.press(screen.getByRole("button", markGuitar));
  await fireEvent.press(screen.getByText("Courses"));
}

test("the total moves at once, and the server is told", async () => {
  jest.mocked(sendDone).mockResolvedValue({ id: "s3", course: "guitar", date: "2026-10-21", minutes: 20, done: true });
  await openWeekAndMark();
  expect(await screen.findByText("This week: 95 of 125 minutes done")).toBeOnTheScreen();
  await waitFor(() => expect(sendDone).toHaveBeenCalledWith("s3", expect.anything()));
});

test("a refusal puts the total back", async () => {
  jest.mocked(sendDone).mockRejectedValue(new Error("POST /sessions/s3/done answered 500"));
  jest.mocked(fetchPlan).mockResolvedValue(structuredClone(data)); // the server did not change
  await openWeekAndMark();
  expect(await screen.findByText("This week: 75 of 125 minutes done")).toBeOnTheScreen();
});

test("offline, the request waits; online again, it is sent", async () => {
  jest.mocked(sendDone).mockResolvedValue({ id: "s3", course: "guitar", date: "2026-10-21", minutes: 20, done: true });
  onlineManager.setOnline(false);
  await openWeekAndMark();
  expect(await screen.findByText("This week: 95 of 125 minutes done")).toBeOnTheScreen();
  expect(sendDone).not.toHaveBeenCalled();
  onlineManager.setOnline(true);
  await waitFor(() => expect(sendDone).toHaveBeenCalledTimes(1));
});
```

```
ana@dev:~/planner$ npx jest done
PASS __tests__/done.test.tsx
  ✓ the total moves at once, and the server is told (324 ms)
  ✓ a refusal puts the total back (75 ms)
  ✓ offline, the request waits; online again, it is sent (83 ms)

Test Suites: 1 passed, 1 total
Tests:       3 passed, 3 total
Snapshots:   0 total
Time:        1.448 s, estimated 2 s
Ran all test suites matching done.
```

The first test shows the change at once and the request made. The second has the server refuse, and the
total goes back to 75: that is `onError`. The third is the next section's.
