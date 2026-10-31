---
title: A row that follows a finger
version: 1
---

**A gesture is an animation whose next frame depends on a finger**, which is why the native driver
cannot do it and Reanimated can. The planner gets one: on *This week*, a session not yet done can be
dragged to the left, and dragged far enough, it is marked done.

**The *Mark done* button stays.** A swipe is invisible until somebody tells you it is there, a screen
reader cannot perform it, and some people cannot drag at all. Every action a gesture offers needs a
control that does the same thing; the gesture is a shortcut for people who know it.

## The root of the app

React Native Gesture Handler recognises touches on the native side, so it has to sit at the root of the
app, where every touch passes. Wrap the planner in `GestureHandlerRootView`:

```tsx
// App.tsx: the planner's root: gestures, safe areas, the query client, and the plan once it has arrived.
import { NavigationContainer } from "@react-navigation/native";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { StatusBar } from "expo-status-bar";
import { GestureHandlerRootView } from "react-native-gesture-handler";
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
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider initialMetrics={initialWindowMetrics}>
        <QueryClientProvider client={client}>
          <Loaded />
        </QueryClientProvider>
        <StatusBar style="auto" />
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
```

## The rule, kept apart

How far is far enough is a decision, and a decision deserves a test. It lives in its own file, with the
`"worklet"` directive so that the gesture can call it on the UI thread:

```tsx
// src/swipe.ts: how far a row must be dragged to count as done.
// A worklet, so the gesture can call it on the UI thread; in Jest it is an ordinary function.
export const SWIPE_DONE = 96;

export function swipeCompletes(dx: number) {
  "worklet";
  return dx < -SWIPE_DONE;
}
```

Outside a worklet the directive is only a string, so Jest and the rest of the app call the function like
any other.

## The row

```schooling-example
{"language": "tsx", "file": "src/SwipeRow.tsx", "parts": [{"code": "// src/SwipeRow.tsx: a row that follows a finger to the left and, dragged far enough, marks itself done.\n// The row's own button does the same thing; the swipe is a shortcut, never the only way.\nimport type { ReactNode } from \"react\";\nimport { GestureDetector, usePanGesture } from \"react-native-gesture-handler\";\nimport Animated, { useAnimatedStyle, useSharedValue, withSpring } from \"react-native-reanimated\";\nimport { scheduleOnRN } from \"react-native-worklets\";\nimport { swipeCompletes } from \"./swipe\";\n\ntype Props = { onDone: () => void; children: ReactNode };\n", "note": "Three libraries meet here: the gesture comes from Gesture Handler, the movement from Reanimated, and the way back to JavaScript from Worklets."}, {"code": "export function SwipeRow({ onDone, children }: Props) {\n  const x = useSharedValue(0);", "note": "`x` is how far the row has moved. It starts at 0 and only the UI thread changes it while the finger is down."}, {"code": "  const pan = usePanGesture({\n    activeOffsetX: [-12, 12],", "note": "A **pan** is a finger that moves. `activeOffsetX` makes it wait until the finger has gone 12 points sideways before it claims the touch, so a vertical scroll through the list still scrolls."}, {"code": "    onUpdate: (e) => {\n      x.value = Math.min(0, e.translationX);\n    },", "note": "Called on every movement, on the UI thread. `translationX` is the distance from where the finger landed; `Math.min` lets the row go left and never right."}, {"code": "    onDeactivate: (e) => {\n      if (swipeCompletes(e.translationX)) scheduleOnRN(onDone);\n      x.value = withSpring(0);\n    },\n  });", "note": "Called once when the finger lifts. The decision is a worklet, so it can run here; `onDone` is the planner's ordinary function, so `scheduleOnRN` hands it to the JavaScript thread. Either way the row springs back: the list redraws it as done if the server agrees."}, {"code": "  const moved = useAnimatedStyle(() => ({ transform: [{ translateX: x.value }] }));\n  return (\n    <GestureDetector gesture={pan}>\n      <Animated.View style={moved}>{children}</Animated.View>\n    </GestureDetector>\n  );\n}", "note": "`GestureDetector` attaches the gesture to the view inside it. The style follows `x` on every frame with no render, which is the point of all this."}]}
```

And `src/SessionList.tsx` wraps each session that can still be done in one. The row itself has not
changed, apart from a `testID` so a program can find it:

```tsx
// src/SessionList.tsx: sessions grouped under their day, each with a button to mark it done.
import { Pressable, SectionList, StyleSheet, Text, View } from "react-native";
import type { Session } from "./planner";
import { SwipeRow } from "./SwipeRow";
import { useTheme } from "./theme";

type Props = { sessions: Session[]; onDone?: (id: string) => void };

export function groupByDate(sessions: Session[]) {
  const days = new Map<string, Session[]>();
  for (const s of [...sessions].sort((a, b) => a.date.localeCompare(b.date))) {
    days.set(s.date, [...(days.get(s.date) ?? []), s]);
  }
  return [...days].map(([date, data]) => ({ title: date, data }));
}

export function SessionList({ sessions, onDone }: Props) {
  const t = useTheme();
  return (
    <SectionList
      sections={groupByDate(sessions)}
      keyExtractor={(s) => s.id}
      renderSectionHeader={({ section }) => (
        <Text role="heading" aria-level={2} style={[styles.day, { color: t.muted }]}>
          {section.title}
        </Text>
      )}
      renderItem={({ item }) => {
        const row = (
          <View testID={`session-${item.id}`} style={styles.row}>
            <Text style={[styles.session, { color: t.text }]}>
              {item.minutes} min{item.done ? ", done" : ""}
            </Text>
            {onDone && !item.done && (
              <Pressable
                role="button"
                aria-label={`Mark ${item.minutes} min on ${item.date} done`}
                onPress={() => onDone(item.id)}
                hitSlop={8}
              >
                <Text style={[styles.action, { color: t.accent }]}>Mark done</Text>
              </Pressable>
            )}
          </View>
        );
        // only a session that can still be marked done can be swiped
        return onDone && !item.done ? <SwipeRow onDone={() => onDone(item.id)}>{row}</SwipeRow> : row;
      }}
      ListEmptyComponent={<Text style={{ color: t.muted }}>No sessions yet.</Text>}
    />
  );
}

const styles = StyleSheet.create({
  day: { marginTop: 16, fontSize: 13, fontWeight: "600" },
  row: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  session: { paddingVertical: 8, fontSize: 16 },
  action: { fontSize: 16, fontWeight: "600" },
});
```

## Jest and Reanimated, in this recording

Run the list's tests:

```
ana@dev:~/planner$ npx jest SessionList --forceExit 2>&1 | head -8
FAIL __tests__/SessionList.test.tsx
  ● Test suite failed to run

    TypeError: Cannot read properties of undefined (reading 'loadUnpackersWithCode')

      3 | import type { ReactNode } from "react";
      4 | import { GestureDetector, usePanGesture } from "react-native-gesture-handler";
    > 5 | import Animated, { useAnimatedStyle, useSharedValue, withSpring } from "react-native-reanimated";
```

**This is not your mistake.** Reanimated 4.7.1 starts its worklet runtime as soon as it is imported, and
inside `jest-expo` 58 there is no native module for it to start. Reanimated ships a stand-in for tests,
`react-native-reanimated/mock`, and *at the time of this recording it failed in the same place, with
"`setCSSEventHandler` is not available"*. That may well be fixed by the time you read this; check the
library's notes on testing before you copy the workaround.

The workaround is to stop Jest from reaching Reanimated at all. `SwipeRow` is the only file that imports
it, so the tests replace `SwipeRow` with its children. The last three lines of `jest.setup.ts` are new:

```ts
// jest.setup.ts: runs before every test file.
// The libraries' own stand-ins: there is no native side in Jest to measure or to ask.
jest.mock("react-native-safe-area-context", () => require("react-native-safe-area-context/jest/mock").default);
jest.mock("@react-native-community/netinfo", () => require("@react-native-community/netinfo/jest/netinfo-mock.js"));
// Reanimated 4.7 cannot start inside jest-expo 58, not even as its own stand-in, so the one
// component that uses it is replaced by its children. The rule it applies is tested on its own.
jest.mock("./src/SwipeRow", () => ({ SwipeRow: ({ children }: { children: unknown }) => children }));
```

That costs nothing the tests were checking: they press buttons and read text, and a `SwipeRow` that only
renders its children leaves both where they were. What it does cost is any test of the gesture itself,
and that is why the rule was kept apart. Save `__tests__/swipe.test.ts`:

```ts
import { SWIPE_DONE, swipeCompletes } from "../src/swipe";

test("a short drag is not a decision", () => {
  expect(swipeCompletes(-60)).toBe(false);
});

test("past the threshold to the left, the row is done", () => {
  expect(swipeCompletes(-(SWIPE_DONE + 1))).toBe(true);
});

test("to the right, never", () => {
  expect(swipeCompletes(400)).toBe(false);
});
```

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npx jest --forceExit
PASS __tests__/SessionList.test.tsx
PASS __tests__/done.test.tsx
PASS __tests__/swipe.test.ts
PASS __tests__/AddSession.test.tsx
PASS __tests__/WeekBar.test.tsx
PASS __tests__/virtual.test.tsx
  ● Console

    console.log
      ScrollView rows created: 1000

      at Object.log (__tests__/virtual.test.tsx:15:11)

    console.log
      FlatList rows created: 10

      at Object.log (__tests__/virtual.test.tsx:20:11)

PASS __tests__/App.test.tsx
PASS __tests__/PlanScreen.test.tsx
PASS __tests__/keys.test.tsx
  ● Console

    console.log
      by index: statistics, guitar (open)

      at Object.log (__tests__/keys.test.tsx:29:13)

    console.log
      by id: statistics (open), guitar

      at Object.log (__tests__/keys.test.tsx:29:13)

PASS __tests__/navigation.test.tsx
PASS __tests__/renders.test.tsx
  ● Console

    console.log
      context: done rendered 3 times, theme rendered 3 times

      at Object.log (__tests__/renders.test.tsx:46:11)

    console.log
      store: done rendered 3 times, theme rendered 0 times

      at Object.log (__tests__/renders.test.tsx:58:11)

PASS __tests__/validate.test.ts
PASS __tests__/reducer.test.ts
PASS __tests__/planner.test.ts
PASS __tests__/platform.test.ts
  ● Console

    console.log
      ios | Saved on this iPhone | shadowColor shadowOpacity shadowRadius shadowOffset

      at Object.log (__tests__/platform.test.ts:8:11)

PASS __tests__/failure.test.tsx (8.518 s)
A worker process has failed to exit gracefully and has been force exited. This is likely caused by tests leaking due to improper teardown. Try running with --detectOpenHandles to find leaks. Active timers can also cause this, ensure that .unref() was called on them.

Test Suites: 16 passed, 16 total
Tests:       38 passed, 38 total
Snapshots:   0 total
Time:        9.405 s
Ran all test suites.
Force exiting Jest: Have you considered using `--detectOpenHandles` to detect async operations that kept running after all tests finished?
```

## The gesture, in a browser

What Jest cannot run, a browser can: Gesture Handler and Reanimated both work on the web, and a mouse
drag is a pan with one finger. This program opens a screen by its deep link, finds a session's row, drags it left by a given distance in
ten steps, as a finger would, and prints the row before and after. Save it as `swipe.mjs`:

```javascript
// swipe.mjs: drag one session's row to the left with the mouse, as a finger would, and print the
// row's text before and after.
//
//   node swipe.mjs URL SESSION DISTANCE
//
// URL is the screen the row is on, as a deep link.
import { chromium } from "playwright";

const [url, session, distance] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto(url);
await page.waitForLoadState("networkidle");
const row = page.getByTestId(`session-${session}`);
const text = row.getByText(/min/);
console.log("before:", await text.innerText());
const box = await row.boundingBox();
const [x, y] = [box.x + box.width / 2, box.y + box.height / 2];
await page.mouse.move(x, y);
await page.mouse.down();
for (let step = 1; step <= 10; step++) await page.mouse.move(x - (distance * step) / 10, y);
await page.mouse.up();
await page.waitForTimeout(1000); // the spring back, and the server's answer if one was asked for
console.log("after: ", await text.innerText());
await browser.close();
```

Export the web build again, since it now carries both libraries, start the server afresh and serve
`dist/` as before. Then drag the session on the 22nd twice, 60 points and then 150. The address is lesson 8's deep link
to *This week*, with the week pinned by `?today=` as `frames.mjs` pins it:

```
ana@dev:~/planner$ node swipe.mjs 'http://localhost:8082/week?today=2026-10-21' s4 60
before: 30 min
after:  30 min
ana@dev:~/planner$ node swipe.mjs 'http://localhost:8082/week?today=2026-10-21' s4 150
before: 30 min
after:  30 min, done
```

**60 points springs back; 150 marks it done.** The threshold is 96, so the first drag ends with the row
where it was and nothing sent. The second crosses it, and the server's log shows what that cost:

```
listening on 8008
GET / 
GET /plan 
GET /plan 
POST /sessions/s4/done 
GET /plan 
```

Read it from the top: the server saying it has started, then `GET /`, the recording machine checking
that it answers; one `GET /plan` per visit; and between the last two a single `POST /sessions/s4/done`,
the one the second drag sent. *On a phone the same code runs the movement on the UI thread, which this course did not measure;
the browser has one thread and runs it there.*
