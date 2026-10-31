---
title: The planner, styled
version: 1
---

**This section puts the lesson into the planner**: the theme everywhere, the week bar under the total,
and every style in a `StyleSheet`. Two files change completely. Save the row as `src/CourseRow.tsx`:

```tsx
// src/CourseRow.tsx: one course in the list, as a button that says what it holds.
import { Pressable, StyleSheet, Text, View } from "react-native";
import type { Course } from "./planner";
import { useTheme } from "./theme";

type Props = { course: Course; sessions: number; onOpen: (id: string) => void };

export function CourseRow({ course, sessions, onOpen }: Props) {
  const t = useTheme();
  return (
    <Pressable
      testID={`row-${course.id}`}
      role="button"
      accessibilityHint={`Opens ${course.name}`}
      onPress={() => onOpen(course.id)}
      hitSlop={8}
      style={({ pressed }) => [styles.row, { borderColor: t.line }, pressed && { backgroundColor: t.pressed }]}
    >
      <View>
        <Text style={[styles.name, { color: t.text }]}>{course.name}</Text>
        <Text style={[styles.count, { color: t.muted }]}>
          {sessions} {sessions === 1 ? "session" : "sessions"} planned
        </Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  row: { paddingVertical: 12, paddingHorizontal: 16, borderBottomWidth: 1 },
  name: { fontSize: 17, fontWeight: "600" },
  count: { fontSize: 14 },
});
```

`testID` is a name for tests and tools, and only for them: a screen reader never announces it. On the
web build it becomes a `data-testid` attribute, which is what `boxes.mjs` looks for. And the screen, as
`src/PlanScreen.tsx`:

```tsx
// src/PlanScreen.tsx: the planner's first screen, styled, with the week as a bar.
import { useState } from "react";
import { Image, ScrollView, StyleSheet, Text, View } from "react-native";
import { CourseRow } from "./CourseRow";
import { mondayOf, weekTotal, type Plan } from "./planner";
import { useTheme } from "./theme";
import { WeekBar } from "./WeekBar";

type Props = { plan: Plan; today: string };

export function PlanScreen({ plan, today }: Props) {
  const t = useTheme();
  const [open, setOpen] = useState<string | null>(null);
  const total = weekTotal(plan, mondayOf(today));
  const course = plan.courses.find((c) => c.id === open);
  return (
    <ScrollView style={{ backgroundColor: t.background }} contentContainerStyle={styles.content}>
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
      <View role="list" style={styles.list}>
        {plan.courses.map((c) => (
          <View role="listitem" key={c.id}>
            <CourseRow
              course={c}
              sessions={plan.sessions.filter((s) => s.course === c.id).length}
              onOpen={setOpen}
            />
          </View>
        ))}
      </View>
      {course && (
        <Text role="status" style={[styles.total, { color: t.text }]}>
          Open: {course.name}
        </Text>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: { padding: 24, paddingTop: 64 },
  header: { flexDirection: "row", alignItems: "center", gap: 12 },
  icon: { width: 40, height: 40 },
  title: { fontSize: 24, fontWeight: "700" },
  total: { marginVertical: 12, fontSize: 15 },
  list: { marginTop: 16 },
});
```

The status line is wrapped over several lines now, `{course && ( … )}`, which is the same expression as
before with room for its style.

## A test of the bar

Save this as `__tests__/WeekBar.test.tsx`. It checks the numbers the bar was given, which is the half a
test can see:

```tsx
// __tests__/WeekBar.test.tsx: the bar's two parts grow in the ratio of done to left.
import { render, screen } from "@testing-library/react-native";
import { WeekBar } from "../src/WeekBar";

test("done and left share the bar by flex", async () => {
  await render(<WeekBar done={75} planned={125} />);
  expect(screen.getByTestId("week-done")).toHaveStyle({ flex: 75 });
  expect(screen.getByTestId("week-left")).toHaveStyle({ flex: 50 });
  expect(screen.getByRole("progressbar")).toHaveAccessibilityValue({ min: 0, max: 125, now: 75 });
});
```

`toHaveStyle` checks a style that was set; `toHaveAccessibilityValue` checks what a screen reader would
say about the bar's value. Then the whole suite, and the types:

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npm test

> planner@1.0.0 test
> jest

PASS __tests__/WeekBar.test.tsx
PASS __tests__/PlanScreen.test.tsx
PASS __tests__/App.test.tsx
PASS __tests__/planner.test.ts

Test Suites: 4 passed, 4 total
Tests:       8 passed, 8 total
Snapshots:   0 total
Time:        1.217 s
Ran all test suites.
```

## Wider than a phone

The flexbox section measured the screen at a phone's 390 points. The same command at 768 by 1024 is a
tablet held upright:

```
ana@dev:~/planner$ node boxes.mjs 'http://localhost:8082/?today=2026-10-21' 768 1024
header       x=24 y=64 w=720 h=40  rgba(0, 0, 0, 0)
week-bar     x=24 y=147 w=720 h=12  rgb(230, 235, 240)
week-done    x=24 y=147 w=432 h=12  rgb(47, 111, 78)
week-left    x=456 y=147 w=288 h=12  rgba(0, 0, 0, 0)
row-spanish  x=24 y=175 w=720 h=62  rgba(0, 0, 0, 0)
row-statistics x=24 y=237 w=720 h=62  rgba(0, 0, 0, 0)
row-guitar   x=24 y=299 w=720 h=62  rgba(0, 0, 0, 0)
```

Every width grew, and no style mentions 768. The content is 720 wide, the window less the padding;
the bar is still 60 parts done to 40 left, now 432 to 288; the rows stretch. **That is a layout written
in proportions rather than sizes**, and it is what lets one screen serve both. A tablet would usually
deserve more than a stretched phone layout, two columns for instance, and that is a decision for
`useWindowDimensions`, made in the component that knows what the second column is for.
