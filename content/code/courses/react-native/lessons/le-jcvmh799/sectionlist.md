---
title: SectionList, for items that come in groups
version: 1
---

**A `SectionList` is a FlatList whose data comes in sections, each with a header.** A course's sessions
grouped by day are exactly that: a date, then the sessions on it, then the next date. Lesson 8 gives each
course a screen of its own, and this is the list on it.

## Grouping first

A SectionList takes `sections`, an array of `{ title, data }`, and the planner's sessions are a flat
array, so the first step is a function that groups them. It is exported, so a test can check it without
drawing anything. Save this as `src/SessionList.tsx`:

```tsx
// src/SessionList.tsx: one course's sessions, grouped under the day they fall on.
import { SectionList, StyleSheet, Text } from "react-native";
import type { Session } from "./planner";
import { useTheme } from "./theme";

type Props = { sessions: Session[] };

export function groupByDate(sessions: Session[]) {
  const days = new Map<string, Session[]>();
  for (const s of [...sessions].sort((a, b) => a.date.localeCompare(b.date))) {
    days.set(s.date, [...(days.get(s.date) ?? []), s]);
  }
  return [...days].map(([date, data]) => ({ title: date, data }));
}

export function SessionList({ sessions }: Props) {
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
        <Text style={[styles.session, { color: t.text }]}>
          {item.minutes} min{item.done ? ", done" : ""}
        </Text>
      )}
      ListEmptyComponent={<Text style={{ color: t.muted }}>No sessions yet.</Text>}
    />
  );
}

const styles = StyleSheet.create({
  day: { marginTop: 16, fontSize: 13, fontWeight: "600" },
  session: { paddingVertical: 8, fontSize: 16 },
});
```

`groupByDate` sorts a copy, never the array it was given, then gathers sessions under their date in a
`Map`, which keeps the order dates were first met. `renderSectionHeader` draws each date as a heading of
level 2, below the screen's own heading, so a screen-reader user can jump from day to day. The two
`keyExtractor`s, the FlatList's and this one's, use the same id the last section insisted on.

**`ListEmptyComponent` says something when there is nothing.** A list with no items draws nothing at all
otherwise, and a blank screen is indistinguishable from one that failed to load.

## Tested in three ways

Save this as `__tests__/SessionList.test.tsx`:

```tsx
// __tests__/SessionList.test.tsx: sessions under their days, and an empty course.
import { render, screen } from "@testing-library/react-native";
import data from "../src/courses.json";
import { groupByDate, SessionList } from "../src/SessionList";

const spanish = data.sessions.filter((s) => s.course === "spanish");

test("sessions are grouped by day, in date order", () => {
  expect(groupByDate(spanish).map((g) => [g.title, g.data.length])).toEqual([
    ["2026-10-19", 1],
    ["2026-10-22", 1],
  ]);
});

test("each day is a heading, and each session a line under it", async () => {
  await render(<SessionList sessions={spanish} />);
  expect(screen.getAllByRole("heading").map((h) => h.props.children)).toEqual(["2026-10-19", "2026-10-22"]);
  expect(screen.getByText("30 min, done")).toBeOnTheScreen();
});

test("a course with no sessions says so", async () => {
  await render(<SessionList sessions={[]} />);
  expect(screen.getByText("No sessions yet.")).toBeOnTheScreen();
});
```

```
ana@dev:~/planner$ npx jest SessionList
PASS __tests__/SessionList.test.tsx
  ✓ sessions are grouped by day, in date order (16 ms)
  ✓ each day is a heading, and each session a line under it (226 ms)
  ✓ a course with no sessions says so (4 ms)

Test Suites: 1 passed, 1 total
Tests:       3 passed, 3 total
Snapshots:   0 total
Time:        0.831 s, estimated 1 s
Ran all test suites matching SessionList.
```

The first test checks the grouping with no rendering; the second that each day is announced as a heading
and the session under it says it is done; the third that an empty course says so. *Spanish A2* has two
sessions on two days, from the data of lesson 3.
