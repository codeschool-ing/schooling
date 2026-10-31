---
title: Three screens, one plan
version: 1
---

**Each screen now asks the context for the plan instead of importing the file**, and two of them can
change it. The changes are small, and each screen is shown whole.

The session list gains a button per session that is not done yet. Its accessible name says which session
it marks, because three buttons called *Mark done* in a row tell a screen-reader user nothing about which
is which. Replace `src/SessionList.tsx`:

```tsx
// src/SessionList.tsx: sessions grouped under their day, each with a button to mark it done.
import { Pressable, SectionList, StyleSheet, Text, View } from "react-native";
import type { Session } from "./planner";
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
      renderItem={({ item }) => (
        <View style={styles.row}>
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
      )}
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

`onDone` is optional: a list given none draws no buttons. Replace `src/PlanScreen.tsx`, which now reads
`plan` from `usePlan()` and nothing else changes:

```tsx
// src/PlanScreen.tsx: the Courses tab, drawn from the shared plan.
import type { BottomTabScreenProps } from "@react-navigation/bottom-tabs";
import type { CompositeScreenProps } from "@react-navigation/native";
import type { NativeStackScreenProps } from "@react-navigation/native-stack";
import { FlatList, Image, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { CourseRow } from "./CourseRow";
import type { RootParams, TabParams } from "./navigation";
import { usePlan } from "./planState";
import { mondayOf, weekTotal } from "./planner";
import { savedWhere } from "./savedWhere";
import { useTheme } from "./theme";
import { today } from "./today";
import { WeekBar } from "./WeekBar";

type Props = CompositeScreenProps<BottomTabScreenProps<TabParams, "Courses">, NativeStackScreenProps<RootParams>>;

export function PlanScreen({ navigation }: Props) {
  const { plan } = usePlan();
  const t = useTheme();
  const insets = useSafeAreaInsets();
  const total = weekTotal(plan, mondayOf(today()));
  const header = (
    <View>
      <View testID="header" style={styles.header}>
        <Image source={require("../assets/icon.png")} style={styles.icon} aria-hidden />
        <Text role="heading" style={[styles.title, { color: t.text }]}>
          Study planner
        </Text>
      </View>
      <Text style={[styles.total, { color: t.muted }]}>
        This week: {total.done} of {total.planned} minutes done
      </Text>
      <WeekBar done={total.done} planned={total.planned} />
    </View>
  );
  const footer = (
    <View>
      <Text style={[styles.footer, { color: t.muted }]}>{savedWhere}</Text>
    </View>
  );
  return (
    <FlatList
      data={plan.courses}
      keyExtractor={(c) => c.id}
      renderItem={({ item }) => (
        <CourseRow
          course={item}
          sessions={plan.sessions.filter((s) => s.course === item.id).length}
          onOpen={(id) => navigation.navigate("Course", { id })}
        />
      )}
      ListHeaderComponent={header}
      ListHeaderComponentStyle={styles.listTop}
      ListFooterComponent={footer}
      style={{ backgroundColor: t.background }}
      contentContainerStyle={[styles.content, { paddingTop: insets.top + 24, paddingBottom: insets.bottom + 24 }]}
    />
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: 24 },
  header: { flexDirection: "row", alignItems: "center", gap: 12 },
  icon: { width: 40, height: 40 },
  title: { fontSize: 24, fontWeight: "700" },
  total: { marginVertical: 12, fontSize: 15 },
  listTop: { marginBottom: 16 },
  footer: { marginTop: 24, fontSize: 13 },
});
```

The week's screen and the course's screen read the plan and pass `dispatch` on as `onDone`. Replace
`src/WeekScreen.tsx`:

```tsx
// src/WeekScreen.tsx: every session of this week, whatever its course; any can be marked done.
import { StyleSheet, View } from "react-native";
import { usePlan } from "./planState";
import { mondayOf } from "./planner";
import { SessionList } from "./SessionList";
import { useTheme } from "./theme";
import { today } from "./today";

export function WeekScreen() {
  const { plan, dispatch } = usePlan();
  const t = useTheme();
  const monday = mondayOf(today());
  const week = plan.sessions.filter((s) => mondayOf(s.date) === monday);
  return (
    <View style={[styles.screen, { backgroundColor: t.background }]}>
      <SessionList sessions={week} onDone={(id) => dispatch({ type: "done", id })} />
    </View>
  );
}

const styles = StyleSheet.create({ screen: { flex: 1, paddingHorizontal: 24 } });
```

and `src/CourseScreen.tsx`:

```tsx
// src/CourseScreen.tsx: one course, reached with its id, looked up in the shared plan.
import type { NativeStackScreenProps } from "@react-navigation/native-stack";
import { useLayoutEffect } from "react";
import { StyleSheet, Text, View } from "react-native";
import type { RootParams } from "./navigation";
import { usePlan } from "./planState";
import { SessionList } from "./SessionList";
import { useTheme } from "./theme";

export function CourseScreen({ route, navigation }: NativeStackScreenProps<RootParams, "Course">) {
  const { plan, dispatch } = usePlan();
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
      <SessionList
        sessions={plan.sessions.filter((s) => s.course === course.id)}
        onDone={(id) => dispatch({ type: "done", id })}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, paddingHorizontal: 24 },
  missing: { marginTop: 24, fontSize: 17 },
});
```

## The test that was impossible before

Save this as `__tests__/done.test.tsx`. It renders the whole app, goes to *This week*, marks guitar's
session of the 21st done, goes back to *Courses* and reads the total:

```tsx
// __tests__/done.test.tsx: marking a session done on one screen changes the total on another.
import { fireEvent, render, screen } from "@testing-library/react-native";
import App from "../App";

test("done in the This week tab, counted in the Courses tab", async () => {
  jest.useFakeTimers({ now: new Date("2026-10-21T12:00:00Z") });
  await render(<App />);
  expect(screen.getByText("This week: 75 of 125 minutes done")).toBeOnTheScreen();
  await fireEvent.press(screen.getByText("This week"));
  await fireEvent.press(screen.getByRole("button", { name: "Mark 20 min on 2026-10-21 done" }));
  expect(screen.getByText("20 min, done")).toBeOnTheScreen();
  await fireEvent.press(screen.getByText("Courses"));
  expect(screen.getByText("This week: 95 of 125 minutes done")).toBeOnTheScreen();
});
```

The tests of lesson 8 rendered the navigators on their own; their screens now need a provider above them,
so both wrap it. In `__tests__/navigation.test.tsx` and `__tests__/PlanScreen.test.tsx`, the navigators go
inside `<PlanProvider initial={data}>`, with `data` imported from `../src/courses.json`. Both files whole:

```tsx
// __tests__/navigation.test.tsx: pressing a course opens its screen, and an address opens it too.
import { getStateFromPath, NavigationContainer } from "@react-navigation/native";
import { fireEvent, render, screen } from "@testing-library/react-native";
import data from "../src/courses.json";
import { linking, RootNavigator } from "../src/navigation";
import { PlanProvider } from "../src/planState";

test("pressing a course pushes its screen", async () => {
  await render(
    <PlanProvider initial={data}>
      <NavigationContainer>
        <RootNavigator />
      </NavigationContainer>
    </PlanProvider>,
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
import data from "../src/courses.json";
import { RootNavigator } from "../src/navigation";
import { PlanProvider } from "../src/planState";

const phone = { frame: { x: 0, y: 0, width: 390, height: 844 }, insets: { top: 47, left: 0, right: 0, bottom: 34 } };

test("every course is a button named for what it holds, beside the two tabs", async () => {
  jest.useFakeTimers({ now: new Date("2026-10-21T12:00:00Z") });
  await render(
    <SafeAreaProvider initialMetrics={phone}>
      <PlanProvider initial={data}>
        <NavigationContainer>
          <RootNavigator />
        </NavigationContainer>
      </PlanProvider>
    </SafeAreaProvider>,
  );
  expect(screen.getByRole("button", { name: "Spanish A2 2 sessions planned" })).toBeOnTheScreen();
  expect(screen.getByText("This week: 75 of 125 minutes done")).toBeOnTheScreen();
  expect(screen.getByText("This week")).toBeOnTheScreen(); // the second tab's label
});
```

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npx jest done navigation PlanScreen App
PASS __tests__/navigation.test.tsx
PASS __tests__/App.test.tsx
PASS __tests__/done.test.tsx
PASS __tests__/PlanScreen.test.tsx

Test Suites: 4 passed, 4 total
Tests:       5 passed, 5 total
Snapshots:   0 total
Time:        1.668 s, estimated 3 s
Ran all test suites matching done|navigation|PlanScreen|App.
```

**95 of 125, read on a screen that never received the press.** The press dispatched an action in one tab;
the provider's plan changed; every screen reading it rendered again, the other tab included.
