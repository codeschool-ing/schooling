---
title: Pressable, and a touch that knows it is held
version: 1
---

**Anything a person can press is a `Pressable`.** It wraps other components and reports touches on
them: `onPress` when a tap finishes, `onLongPress` for a held one, and `onPressIn` and `onPressOut` at
the edges. What it does not do is look like anything. A button's appearance, and what it does while a
finger is on it, are yours to give it.

## The planner's course row

Each course in the list is a row you press to open it. Save this as `src/CourseRow.tsx`:

```tsx
// src/CourseRow.tsx: one course in the list, as a button that says what it holds.
import { Pressable, StyleSheet, Text, View } from "react-native";
import type { Course } from "./planner";

type Props = { course: Course; sessions: number; onOpen: (id: string) => void };

export function CourseRow({ course, sessions, onOpen }: Props) {
  return (
    <Pressable
      role="button"
      accessibilityHint={`Opens ${course.name}`}
      onPress={() => onOpen(course.id)}
      hitSlop={8}
      style={({ pressed }) => [styles.row, pressed && styles.pressed]}
    >
      <View>
        <Text style={styles.name}>{course.name}</Text>
        <Text style={styles.count}>
          {sessions} {sessions === 1 ? "session" : "sessions"} planned
        </Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  row: { paddingVertical: 12, paddingHorizontal: 16, borderBottomWidth: 1, borderColor: "#d0d7de" },
  pressed: { backgroundColor: "#eef2f6" },
  name: { fontSize: 17, fontWeight: "600" },
  count: { fontSize: 14, color: "#57606a" },
});
```

`style` takes a **function** here, called with `{ pressed }`, so the row can change while the finger is
down: it returns the base style and, when pressed, the pressed one on top. An array of styles is
applied left to right and `false` in it is ignored, which is why `pressed && styles.pressed` works.
`hitSlop={8}` makes the touchable area eight points larger than the row on every side, which costs
nothing visually and saves a lot of missed taps on a small target.

## Saying what it is

A `Pressable` with no role is, to a screen reader, a group of text. **`role="button"` is what makes
TalkBack and VoiceOver announce it as a button**, and it is what `getByRole("button")` in a test
finds. Its accessible name is its text, joined: *Spanish A2 2 sessions planned*. `accessibilityHint`
adds what pressing it will do, read after a pause.

React Native's older props for the same things, `accessibilityRole` and `accessibilityLabel`, still
work and fill most of the documentation you will read. `role` and the `aria-` props are the newer
spelling, the same as the web's, and this course uses them.

## Remembering what was pressed

`CourseRow` reports a press to its parent through `onOpen` and keeps nothing itself. The parent has to
remember which course is open between one render and the next, and a plain variable cannot do that,
because the component function runs from the top on every render. React's answer is **state**:

```tsx
const [open, setOpen] = useState<string | null>(null);
```

`useState` returns the current value and a function that replaces it. Calling `setOpen("guitar")`
stores the new value and **asks React to render the component again**, and this time `open` is
`"guitar"`. Passing `setOpen` itself as `onOpen` is all the wiring the row needs. Lesson 9 is about
state in full; this is the one line of it the first screen uses.
