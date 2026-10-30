---
title: Params: the id, and only the id
version: 1
---

**A screen receives what it needs to know as `route.params`**, passed by whoever navigated to it:
`navigation.navigate("Course", { id: "guitar" })`. The type of each route's params is declared once, in
`RootParams`, and TypeScript refuses a navigation that leaves one out or passes the wrong kind.

## Pass the id, never the object

It is tempting to pass the whole course, `{ course }`, because the screen will need its name. **Pass the
id.** Three reasons, each a bug somebody has shipped:

- **The params are a copy.** A course passed as an object is the course as it was when the button was
  pressed. Rename it, mark a session done, and the open screen still shows the old copy.
- **Params become addresses.** The next section turns `course/:id` into a link; a link can carry
  `guitar`, and it cannot carry an object.
- **Params are state.** They live in the navigation state, which an app can save and restore, and which
  on the web is the address. A large object there is memory carried around, and an object holding
  functions cannot be saved at all.

The screen then **looks the course up by id**, which is the same join the planner's data uses everywhere.
Save this as `src/CourseScreen.tsx`:

```tsx
// src/CourseScreen.tsx: one course, reached with its id and nothing else.
import type { NativeStackScreenProps } from "@react-navigation/native-stack";
import { useLayoutEffect } from "react";
import { StyleSheet, Text, View } from "react-native";
import data from "./courses.json";
import type { RootParams } from "./navigation";
import type { Plan } from "./planner";
import { SessionList } from "./SessionList";
import { useTheme } from "./theme";

const plan: Plan = data;

export function CourseScreen({ route, navigation }: NativeStackScreenProps<RootParams, "Course">) {
  const t = useTheme();
  const course = plan.courses.find((c) => c.id === route.params.id);
  useLayoutEffect(() => {
    navigation.setOptions({ title: course?.name ?? "Not found" });
  }, [navigation, course]);
  if (!course) {
    return (
      <View style={[styles.screen, { backgroundColor: t.background }]}>
        <Text style={[styles.missing, { color: t.text }]}>There is no course called {route.params.id}.</Text>
      </View>
    );
  }
  return (
    <View style={[styles.screen, { backgroundColor: t.background }]}>
      <SessionList sessions={plan.sessions.filter((s) => s.course === course.id)} />
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, paddingHorizontal: 24 },
  missing: { marginTop: 24, fontSize: 17 },
});
```

`useLayoutEffect` sets the header's title from the course once it is found, before the screen is drawn,
so the header never shows a placeholder. **An id that matches nothing is not an error to hide**: an old
link, a deleted course, a typo in an address. The screen says plainly that there is no such course, and
the next section opens one to prove it.

## Tested by pressing

Save this as `__tests__/navigation.test.tsx`:

```tsx
// __tests__/navigation.test.tsx: pressing a course opens its screen, and an address opens it too.
import { getStateFromPath, NavigationContainer } from "@react-navigation/native";
import { fireEvent, render, screen } from "@testing-library/react-native";
import { linking, RootNavigator } from "../src/navigation";

test("pressing a course pushes its screen", async () => {
  await render(
    <NavigationContainer>
      <RootNavigator />
    </NavigationContainer>,
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

The first test renders the real navigators, presses *Guitar*, and finds the course's two days and its two
sessions of 20 minutes. Jest does not draw the native header, so the test checks what the screen itself
shows. The second checks an address without rendering anything, which is the next section's subject.

`__tests__/PlanScreen.test.tsx` from lesson 6 rendered the screen with props it no longer takes, so it
changes too, to render the navigators with the notched phone's insets:

```tsx
// __tests__/PlanScreen.test.tsx: the Courses tab, read the way a screen reader reads it,
// inside a safe-area provider that pretends to be a phone with a notch.
import { NavigationContainer } from "@react-navigation/native";
import { render, screen } from "@testing-library/react-native";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { RootNavigator } from "../src/navigation";

const phone = { frame: { x: 0, y: 0, width: 390, height: 844 }, insets: { top: 47, left: 0, right: 0, bottom: 34 } };

test("every course is a button named for what it holds, beside the two tabs", async () => {
  jest.useFakeTimers({ now: new Date("2026-10-21T12:00:00Z") });
  await render(
    <SafeAreaProvider initialMetrics={phone}>
      <NavigationContainer>
        <RootNavigator />
      </NavigationContainer>
    </SafeAreaProvider>,
  );
  expect(screen.getByRole("button", { name: "Spanish A2 2 sessions planned" })).toBeOnTheScreen();
  expect(screen.getByText("This week: 75 of 125 minutes done")).toBeOnTheScreen();
  expect(screen.getByText("This week")).toBeOnTheScreen(); // the second tab's label
});
```

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npx jest navigation PlanScreen App
PASS __tests__/PlanScreen.test.tsx
PASS __tests__/App.test.tsx
PASS __tests__/navigation.test.tsx

Test Suites: 3 passed, 3 total
Tests:       4 passed, 4 total
Snapshots:   0 total
Time:        2.291 s
Ran all test suites matching navigation|PlanScreen|App.
```
