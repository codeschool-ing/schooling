---
title: The plan as a query
version: 1
---

**A query is a read with a key.** `useQuery({ queryKey: ["plan"], queryFn: fetchPlan })` asks for the
plan; the first component to ask makes the request, every other one asking for `["plan"]` shares the
answer, and the result stays in a cache that outlives the screens. Install the library, and NetInfo,
which tells it when the phone is online:

```
ana@dev:~/planner$ npm install -E @tanstack/react-query@5.105.0 @react-native-community/netinfo@12.0.1

added 3 packages, and audited 1094 packages in 6s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

## planState, behind the same hook

`src/planState.tsx` keeps its `Action` type and its reducer, and puts a query and a mutation behind
`usePlan()`. Replace it with:

```tsx
// src/planState.tsx: the plan comes from the server through TanStack Query; every change is an action.
import { onlineManager, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import NetInfo from "@react-native-community/netinfo";
import { fetchPlan, sendDone } from "./api";
import { addSession, markDone, type Plan } from "./planner";

export type Action =
  | { type: "done"; id: string }
  | { type: "add"; course: string; date: string; minutes: number };

export function planReducer(plan: Plan, action: Action): Plan {
  switch (action.type) {
    case "done":
      return markDone(plan, action.id);
    case "add":
      return addSession(plan, action.course, action.date, action.minutes);
  }
}

// TanStack Query pauses requests while offline; on a phone, NetInfo is what knows.
onlineManager.setEventListener((setOnline) => NetInfo.addEventListener((s) => setOnline(!!s.isConnected)));

export function usePlanQuery() {
  return useQuery({ queryKey: ["plan"], queryFn: fetchPlan, staleTime: 30_000 });
}

function useMarkDone() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: sendDone,
    onMutate: async (id: string) => {
      await client.cancelQueries({ queryKey: ["plan"] });
      const before = client.getQueryData<Plan>(["plan"]);
      client.setQueryData<Plan>(["plan"], (p) => p && planReducer(p, { type: "done", id }));
      return { before };
    },
    onError: (_error, _id, context) => client.setQueryData(["plan"], context?.before),
    onSettled: () => client.invalidateQueries({ queryKey: ["plan"] }),
  });
}

// The screens' view of all this is the same as in lesson 9.
export function usePlan() {
  const { data } = usePlanQuery();
  const markDone = useMarkDone();
  if (!data) throw new Error("usePlan must be used once the plan has loaded");
  const dispatch = (action: Action) => {
    if (action.type === "done") markDone.mutate(action.id);
  };
  return { plan: data, dispatch, error: markDone.error };
}
```

This section is the query half. `usePlanQuery` reads `["plan"]` with a `staleTime` of 30 seconds: for that
long after an answer, a screen that mounts takes the cached plan without asking again. After it, the plan
is **stale**, which does not mean thrown away; it means the next screen to want it gets the cached copy at
once **and** a request in the background, whose answer replaces it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l10-stale\" aria-label=\"A timeline of the plan query. At 0 seconds the plan is fetched and is fresh. Until 30 seconds, the staleTime, a screen that asks gets the cached plan with no request. After 30 seconds the plan is stale: a screen that asks gets the cached plan at once and a request in the background, whose answer replaces it. A mutation invalidates the query, making it stale at once.\"><defs><marker id=\"l10-stale-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10-stale-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M30 132 L700 132\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-stale-ah-paper-dim)\"></path><rect x=\"40\" y=\"80\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">fresh: no request</text><rect x=\"300\" y=\"80\" width=\"380\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"490\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">stale: cached at once, refetched behind</text><text x=\"40\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 s</text><text x=\"300\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">30 s</text><text x=\"60\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper)\">fetched</text><path d=\"M60 66 L60 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-stale-ah-paper-dim)\"></path><text x=\"170\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper)\">a screen asks</text><path d=\"M170 46 L170 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-stale-ah-paper-dim)\"></path><text x=\"430\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper)\">a screen asks</text><path d=\"M430 46 L430 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-stale-ah-paper-dim)\"></path><text x=\"220\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">a mutation invalidates: stale now</text><path d=\"M220 164 L220 120\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l10-stale-ah-amber)\"></path></svg>", "caption": "Stale is not empty: a stale plan is shown at once, and replaced when the background request answers."}
```

`usePlan` throws if the plan has not arrived. That is a promise the root keeps: no screen is drawn until it
has.

## The root waits, and says so

`App.tsx` gains a `QueryClientProvider`, which holds the cache, and a component that draws the navigators
only once the plan is there. Until then it says what is happening, in a `status` a screen reader
announces, and when loading failed it says why and offers to try again. Replace it with:

```tsx
// App.tsx: the planner's root: safe areas, the query client, and the plan once it has arrived.
import { NavigationContainer } from "@react-navigation/native";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { StatusBar } from "expo-status-bar";
import { Pressable, Text, View } from "react-native";
import { initialWindowMetrics, SafeAreaProvider } from "react-native-safe-area-context";
import { linking, RootNavigator } from "./src/navigation";
import { usePlanQuery } from "./src/planState";

const client = new QueryClient();

function Loaded() {
  const { data, error, refetch, isFetching } = usePlanQuery();
  if (data) {
    return (
      <NavigationContainer linking={linking}>
        <RootNavigator />
      </NavigationContainer>
    );
  }
  return (
    <View style={{ flex: 1, justifyContent: "center", padding: 24, gap: 12 }}>
      <Text role="status">{error ? `The plan could not be loaded: ${error.message}` : "Loading the plan"}</Text>
      {error && !isFetching && (
        <Pressable role="button" onPress={() => refetch()}>
          <Text>Try again</Text>
        </Pressable>
      )}
    </View>
  );
}

export default function App() {
  return (
    <SafeAreaProvider initialMetrics={initialWindowMetrics}>
      <QueryClientProvider client={client}>
        <Loaded />
      </QueryClientProvider>
      <StatusBar style="auto" />
    </SafeAreaProvider>
  );
}
```

**A failed load is a sentence and a button, never a blank screen.** TanStack Query retries a failed query
three times by default, waiting longer each time, before it gives up; the message appears after those
retries. `isFetching` hides the button while a retry is under way, so it cannot be pressed twice.

## Tests, with no server

A test cannot rely on a server running. **`jest.mock("../src/api")` replaces every export of that file with
a mock** that does nothing until a test says what it returns, which turns *what the server answers* into
one line per test.

NetInfo has a native side, so it needs its stand-in in `jest.setup.ts` beside lesson 6's. Replace it:

```typescript
// jest.setup.ts: runs before every test file.
// The libraries' own stand-ins: there is no native side in Jest to measure or to ask.
jest.mock("react-native-safe-area-context", () => require("react-native-safe-area-context/jest/mock").default);
jest.mock("@react-native-community/netinfo", () => require("@react-native-community/netinfo/jest/netinfo-mock.js"));
```

Screens below the root need the plan already loaded. One helper does that for every test, by putting the
plan straight into a fresh cache. Save it as `test-utils.tsx`, outside `__tests__/` so Jest does not take
it for a test:

```tsx
// test-utils.tsx: what a screen test puts around a screen: a query client whose plan has already loaded.
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { ReactElement } from "react";
import data from "./src/courses.json";
import type { Plan } from "./src/planner";

export function withPlan(ui: ReactElement, plan: Plan = data) {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  client.setQueryData(["plan"], plan);
  return <QueryClientProvider client={client}>{ui}</QueryClientProvider>;
}
```

The app's own test now checks the loading state and then the plan. Replace `__tests__/App.test.tsx`:

```tsx
// __tests__/App.test.tsx: the app waits for the plan, and says so when it cannot have it.
import { render, screen } from "@testing-library/react-native";
import data from "../src/courses.json";
import App from "../App";
import { fetchPlan } from "../src/api";

jest.mock("../src/api"); // no server in a test: each test says what the server answers

beforeEach(() => jest.useFakeTimers({ now: new Date("2026-10-21T12:00:00Z") }));

test("loading, then the plan", async () => {
  jest.mocked(fetchPlan).mockResolvedValue(structuredClone(data));
  await render(<App />);
  expect(screen.getByRole("status")).toHaveTextContent("Loading the plan");
  expect(await screen.findByText("This week: 75 of 125 minutes done")).toBeOnTheScreen();
});
```

And a new one checks the failure. Save it as `__tests__/failure.test.tsx`:

```tsx
// __tests__/failure.test.tsx: a server that is down is a sentence and a button, not a blank screen.
import { render, screen } from "@testing-library/react-native";
import App from "../App";
import { fetchPlan } from "../src/api";

jest.mock("../src/api");

test("the plan cannot be loaded", async () => {
  jest.mocked(fetchPlan).mockRejectedValue(new Error("GET /plan answered 503"));
  await render(<App />);
  expect(await screen.findByText("The plan could not be loaded: GET /plan answered 503", {}, { timeout: 10_000 })).toBeOnTheScreen();
  expect(screen.getByRole("button", { name: "Try again" })).toBeOnTheScreen();
}, 15_000);
```

It allows ten seconds, because the three retries take several seconds of real time. The two navigation
tests wrap their navigators in `withPlan(…)` instead of lesson 9's provider. Replace both:

```tsx
// __tests__/navigation.test.tsx: pressing a course opens its screen, and an address opens it too.
import { getStateFromPath, NavigationContainer } from "@react-navigation/native";
import { fireEvent, render, screen } from "@testing-library/react-native";
import { linking, RootNavigator } from "../src/navigation";
import { withPlan } from "../test-utils";

test("pressing a course pushes its screen", async () => {
  await render(
    withPlan(
      <NavigationContainer>
        <RootNavigator />
      </NavigationContainer>,
    ),
  );
  await fireEvent.press(screen.getByRole("button", { name: /^Guitar/ }));
  expect(screen.getAllByRole("heading").map((h) => h.props.children)).toEqual(["2026-10-21", "2026-10-28"]);
  expect(screen.getAllByText("20 min")).toHaveLength(2);
});

test("the address course/statistics reaches the Course screen with its id", () => {
  const state = getStateFromPath("course/statistics", linking.config);
  expect(state?.routes.at(-1)).toMatchObject({ name: "Course", params: { id: "statistics" } });
});
```

```tsx
// __tests__/PlanScreen.test.tsx: the Courses tab, read the way a screen reader reads it,
// inside a safe-area provider that pretends to be a phone with a notch.
import { NavigationContainer } from "@react-navigation/native";
import { render, screen } from "@testing-library/react-native";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { RootNavigator } from "../src/navigation";
import { withPlan } from "../test-utils";

const phone = { frame: { x: 0, y: 0, width: 390, height: 844 }, insets: { top: 47, left: 0, right: 0, bottom: 34 } };

test("every course is a button named for what it holds, beside the two tabs", async () => {
  jest.useFakeTimers({ now: new Date("2026-10-21T12:00:00Z") });
  await render(
    <SafeAreaProvider initialMetrics={phone}>
      {withPlan(
        <NavigationContainer>
          <RootNavigator />
        </NavigationContainer>,
      )}
    </SafeAreaProvider>,
  );
  expect(screen.getByRole("button", { name: "Spanish A2 2 sessions planned" })).toBeOnTheScreen();
  expect(screen.getByText("This week: 75 of 125 minutes done")).toBeOnTheScreen();
  expect(screen.getByText("This week")).toBeOnTheScreen(); // the second tab's label
});
```

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npx jest App failure navigation PlanScreen
PASS __tests__/navigation.test.tsx
PASS __tests__/App.test.tsx
PASS __tests__/PlanScreen.test.tsx
PASS __tests__/failure.test.tsx (8.185 s)
A worker process has failed to exit gracefully and has been force exited. This is likely caused by tests leaking due to improper teardown. Try running with --detectOpenHandles to find leaks. Active timers can also cause this, ensure that .unref() was called on them.

Test Suites: 4 passed, 4 total
Tests:       5 passed, 5 total
Snapshots:   0 total
Time:        9.006 s
Ran all test suites matching App|failure|navigation|PlanScreen.
```

*The plan could not be loaded: GET /plan answered 503* is what a person would read, word for word, the day
the server is down. Jest's warning about a worker that *failed to exit gracefully* comes from that test
too: the app's query client lives for as long as the module, and its timers outlive the test. It does not
change a result; a test suite that grows would give each test its own client, as `withPlan` does.
