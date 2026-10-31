---
title: Counting re-renders
version: 1
---

**When one session is marked done, which components render again?** The plan changes, so every screen
that reads it renders, and its lists render their rows. The rows are where the waste is: one row's session
changed, and every visible row renders to find that out.

To count them, the rows have to be components. Until now `SessionList` built each row inline, in
`renderItem`; move it into its own file, `src/SessionRow.tsx`:

```tsx
// src/SessionRow.tsx: one session in a list, with its button to mark it done and its swipe.
import { Pressable, StyleSheet, Text, View } from "react-native";
import type { Session } from "./planner";
import { SwipeRow } from "./SwipeRow";
import { useTheme } from "./theme";

type Props = { session: Session; onDone?: (id: string) => void };

export function SessionRow({ session, onDone }: Props) {
  const t = useTheme();
  const row = (
    <View testID={`session-${session.id}`} style={styles.row}>
      <Text style={[styles.session, { color: t.text }]}>
        {session.minutes} min{session.done ? ", done" : ""}
      </Text>
      {onDone && !session.done && (
        <Pressable
          role="button"
          aria-label={`Mark ${session.minutes} min on ${session.date} done`}
          onPress={() => onDone(session.id)}
          hitSlop={8}
        >
          <Text style={[styles.action, { color: t.accent }]}>Mark done</Text>
        </Pressable>
      )}
    </View>
  );
  // only a session that can still be marked done can be swiped
  return onDone && !session.done ? <SwipeRow onDone={() => onDone(session.id)}>{row}</SwipeRow> : row;
}

const styles = StyleSheet.create({
  row: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  session: { paddingVertical: 8, fontSize: 16 },
  action: { fontSize: 16, fontWeight: "600" },
});
```

and `src/SessionList.tsx` renders one per session:

```tsx
// src/SessionList.tsx: sessions grouped under their day, each a SessionRow.
import { SectionList, StyleSheet, Text } from "react-native";
import type { Session } from "./planner";
import { SessionRow } from "./SessionRow";
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
      renderItem={({ item }) => <SessionRow session={item} onDone={onDone} />}
      ListEmptyComponent={<Text style={{ color: t.muted }}>No sessions yet.</Text>}
    />
  );
}

const styles = StyleSheet.create({
  day: { marginTop: 16, fontSize: 13, fontWeight: "600" },
});
```

**Every row calls `useTheme` once each time it renders**, so counting the calls to `useTheme` counts the
renders. The test replaces `useTheme` with a `jest.fn` that calls the real one, renders fifty sessions,
clears the count, and renders again with one session marked done. It does that twice: once passing the same
callback both times, once passing a new one. Save `__tests__/rowRenders.test.tsx`:

```tsx
// __tests__/rowRenders.test.tsx: how many components render again when one session of fifty is marked
// done. Every row reads the theme once per render, so counting useTheme counts renders.
import { render } from "@testing-library/react-native";
import { markDone, type Session } from "../src/planner";
import { SessionList } from "../src/SessionList";
import { useTheme } from "../src/theme";

jest.mock("../src/theme", () => {
  const actual = jest.requireActual("../src/theme");
  return { ...actual, useTheme: jest.fn(actual.useTheme) };
});
const counted = jest.mocked(useTheme);

const sessions: Session[] = Array.from({ length: 50 }, (_, i) => ({
  id: `s${i}`,
  course: "guitar",
  date: `2026-11-${String(1 + (i % 28)).padStart(2, "0")}`,
  minutes: 20,
  done: false,
}));
const after = markDone({ courses: [], sessions }, "s1").sessions;

test("a callback made once", async () => {
  const onDone = () => {};
  const view = await render(<SessionList sessions={sessions} onDone={onDone} />);
  counted.mockClear();
  await view.rerender(<SessionList sessions={after} onDone={onDone} />);
  console.log("rendered again, with the same callback:", counted.mock.calls.length);
});

test("a callback made on every render", async () => {
  const view = await render(<SessionList sessions={sessions} onDone={() => {}} />);
  counted.mockClear();
  await view.rerender(<SessionList sessions={after} onDone={() => {}} />);
  console.log("rendered again, with a new callback:", counted.mock.calls.length);
});
```

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npx jest rowRenders --forceExit 2>&1 | grep -E "rendered again|Tests:"
    rendered again, with the same callback: 6
    rendered again, with a new callback: 6
Tests:       2 passed, 2 total
```

**Six: the list itself and five rows**, the ones a `SectionList` draws at first: ten slots, and each day
takes one for its header and one for its footer. All five rendered again although one session changed. Now `React.memo`: wrap the row, so React
compares its props with the last render's and skips the render when every one is the same object. In
`src/SessionRow.tsx`, import `memo` and wrap the function:

```tsx
// src/SessionRow.tsx: one session in a list, with its button to mark it done and its swipe. Memoised: it
// renders again only when its session or its callback is a different object.
import { memo } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import type { Session } from "./planner";
import { SwipeRow } from "./SwipeRow";
import { useTheme } from "./theme";

type Props = { session: Session; onDone?: (id: string) => void };

export const SessionRow = memo(function SessionRow({ session, onDone }: Props) {
  const t = useTheme();
  const row = (
    <View testID={`session-${session.id}`} style={styles.row}>
      <Text style={[styles.session, { color: t.text }]}>
        {session.minutes} min{session.done ? ", done" : ""}
      </Text>
      {onDone && !session.done && (
        <Pressable
          role="button"
          aria-label={`Mark ${session.minutes} min on ${session.date} done`}
          onPress={() => onDone(session.id)}
          hitSlop={8}
        >
          <Text style={[styles.action, { color: t.accent }]}>Mark done</Text>
        </Pressable>
      )}
    </View>
  );
  // only a session that can still be marked done can be swiped
  return onDone && !session.done ? <SwipeRow onDone={() => onDone(session.id)}>{row}</SwipeRow> : row;
});

const styles = StyleSheet.create({
  row: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  session: { paddingVertical: 8, fontSize: 16 },
  action: { fontSize: 16, fontWeight: "600" },
});
```

```
ana@dev:~/planner$ npx jest rowRenders --forceExit 2>&1 | grep -E "rendered again|Tests:"
    rendered again, with the same callback: 2
    rendered again, with a new callback: 6
Tests:       2 passed, 2 total
```

**With the same callback, two: the list and the one row whose session changed.** The other rows got the
same `session` object as before, because lesson 9's `markDone` copies only the session it changes, and the
same `onDone`, so React skipped them. **With a new callback on every render, six again**: a function made
inside a render is a new object each time, the comparison fails for every row, and `memo` does nothing
except the comparing.
