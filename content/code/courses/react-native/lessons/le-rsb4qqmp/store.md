---
title: A store, for when context is not enough
version: 1
---

**A context re-renders every reader when its value changes.** That is fine for three screens and a plan
of six sessions. It stops being fine when many components read a large value and each uses a small part
of it: a list of a thousand rows that each read one item, and a header that reads the theme, all
redrawing because one row was marked done.

A **store** keeps state outside React and lets each component subscribe to **the part it uses**, through
a selector. Zustand is a small, popular one. Install it, at the version this course used:

```
ana@dev:~/planner$ npm install -E zustand@5.0.16

added 1 package, and audited 1091 packages in 6s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

## Counting

This test builds the same two readers twice, one that shows `done` and one that shows the theme, once
through a context and once through a store, then changes `done` three times and counts the renders.
Save it as `__tests__/renders.test.tsx`:

```tsx
// __tests__/renders.test.tsx: who re-renders when one value changes, with a context and with a store.
import { act, render } from "@testing-library/react-native";
import { createContext, useContext, useState } from "react";
import { Text } from "react-native";
import { create } from "zustand";

type State = { done: number; theme: string };
const renders = { done: 0, theme: 0 };

// The same two readers, once through a context and once through a store.
const Ctx = createContext<State>({ done: 0, theme: "light" });
function DoneFromContext() {
  renders.done++;
  return <Text>{useContext(Ctx).done}</Text>;
}
function ThemeFromContext() {
  renders.theme++;
  return <Text>{useContext(Ctx).theme}</Text>;
}

const useStore = create<State>(() => ({ done: 0, theme: "light" }));
function DoneFromStore() {
  renders.done++;
  return <Text>{useStore((s) => s.done)}</Text>;
}
function ThemeFromStore() {
  renders.theme++;
  return <Text>{useStore((s) => s.theme)}</Text>;
}

test("a context re-renders every reader", async () => {
  let set: (s: State) => void = () => {};
  function Root() {
    const [state, setState] = useState<State>({ done: 0, theme: "light" });
    set = setState;
    return (
      <Ctx.Provider value={state}>
        <DoneFromContext />
        <ThemeFromContext />
      </Ctx.Provider>
    );
  }
  await render(<Root />);
  renders.done = renders.theme = 0;
  for (const done of [15, 30, 45]) await act(async () => set({ done, theme: "light" }));
  console.log("context: done rendered", renders.done, "times, theme rendered", renders.theme, "times");
});

test("a store re-renders only the readers whose slice changed", async () => {
  await render(
    <>
      <DoneFromStore />
      <ThemeFromStore />
    </>,
  );
  renders.done = renders.theme = 0;
  for (const done of [15, 30, 45]) await act(async () => useStore.setState({ done }));
  console.log("store: done rendered", renders.done, "times, theme rendered", renders.theme, "times");
});
```

```
ana@dev:~/planner$ npx jest renders
  console.log
    context: done rendered 3 times, theme rendered 3 times

      at Object.log (__tests__/renders.test.tsx:46:11)

  console.log
    store: done rendered 3 times, theme rendered 0 times

      at Object.log (__tests__/renders.test.tsx:58:11)

PASS __tests__/renders.test.tsx
  ✓ a context re-renders every reader (114 ms)
  ✓ a store re-renders only the readers whose slice changed (8 ms)

Test Suites: 1 passed, 1 total
Tests:       2 passed, 2 total
Snapshots:   0 total
Time:        0.605 s, estimated 2 s
Ran all test suites matching renders.
```

**Through the context, the theme reader rendered three times for three changes it does not show.**
Through the store, it rendered none: `useStore((s) => s.theme)` re-renders its component only when the
theme itself changes. `act` wraps each change so React finishes rendering before the count is read.

## The planner keeps its context

Three screens and a press now and then do not need a store, and a context is part of React, with no
dependency and nothing to learn. **Reach for a store when a measurement says the re-renders cost
something**, which is lesson 19's method: a list of hundreds of rows that each read shared state is the
usual first case. The test above is the kind of measurement that settles it.

Other stores exist, Redux Toolkit, Jotai, MobX, and they differ in style more than in this property.
Every one of them offers a way to subscribe to part of the state, which is the reason to have one.
