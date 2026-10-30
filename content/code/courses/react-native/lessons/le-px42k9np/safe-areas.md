---
title: Safe areas, around the notch and the home indicator
version: 1
---

**A safe area is the part of the screen nothing of the system's draws over.** Its edges, the **insets**,
are different on every model: zero on an old phone with a plain rectangular screen, around 47 points at
the top and 34 at the bottom on a recent iPhone, other values on Android. The planner has so far put a
fixed 64 points of padding at the top, which is too much on one phone and too little on another, and
nothing at the bottom.

## The library

React Native's own `SafeAreaView` covers iOS only. The library everybody uses, and that Expo's SDK
includes, is `react-native-safe-area-context`. Install the version SDK 58 names:

```
ana@dev:~/planner$ npm install -E react-native-safe-area-context@5.10.1

added 3 packages, and audited 1069 packages in 6s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

It has two parts. A **provider** at the root of the app measures the insets from the native side and
keeps them current, on rotation for instance. A **hook**, `useSafeAreaInsets`, returns them anywhere
below it, as `{ top, right, bottom, left }` in points.

## The planner's root and its screen

`App.tsx` wraps everything in the provider. Replace it with:

```tsx
// App.tsx: the planner's root, inside the provider that measures the safe areas.
import { StatusBar } from "expo-status-bar";
import { initialWindowMetrics, SafeAreaProvider } from "react-native-safe-area-context";
import data from "./src/courses.json";
import { PlanScreen } from "./src/PlanScreen";
import type { Plan } from "./src/planner";
import { today } from "./src/today";

const plan: Plan = data;

export default function App() {
  return (
    <SafeAreaProvider initialMetrics={initialWindowMetrics}>
      <PlanScreen plan={plan} today={today()} />
      <StatusBar style="auto" />
    </SafeAreaProvider>
  );
}
```

`initialMetrics={initialWindowMetrics}` gives the provider the insets the native side already knew when
the app started, so it can draw the first frame at once. Without it, the provider renders nothing until
its first measurement arrives, which is a blank frame on a phone and, as the next section finds, an empty
screen in a test.

The screen asks for the insets and adds them to its padding, and gains the sentence from the file
extensions section at its foot. Replace `src/PlanScreen.tsx` with:

```tsx
// src/PlanScreen.tsx: the first screen, clear of the notch and the home indicator.
import { useState } from "react";
import { Image, ScrollView, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { CourseRow } from "./CourseRow";
import { mondayOf, weekTotal, type Plan } from "./planner";
import { savedWhere } from "./savedWhere";
import { useTheme } from "./theme";
import { WeekBar } from "./WeekBar";

type Props = { plan: Plan; today: string };

export function PlanScreen({ plan, today }: Props) {
  const t = useTheme();
  const insets = useSafeAreaInsets();
  const [open, setOpen] = useState<string | null>(null);
  const total = weekTotal(plan, mondayOf(today));
  const course = plan.courses.find((c) => c.id === open);
  return (
    <ScrollView
      style={{ backgroundColor: t.background }}
      contentContainerStyle={[styles.content, { paddingTop: insets.top + 24, paddingBottom: insets.bottom + 24 }]}
    >
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
      <Text style={[styles.footer, { color: t.muted }]}>{savedWhere}</Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: 24 },
  header: { flexDirection: "row", alignItems: "center", gap: 12 },
  icon: { width: 40, height: 40 },
  title: { fontSize: 24, fontWeight: "700" },
  total: { marginVertical: 12, fontSize: 15 },
  list: { marginTop: 16 },
  footer: { marginTop: 24, fontSize: 13 },
});
```

The content now begins 24 points below whatever the top inset is, and ends 24 above the bottom one. On a
phone with no notch both insets are zero, and the padding is the 24 of the sides.

## In tests: the library's stand-in

**Jest has no native side to measure anything**, so the library ships a stand-in for tests, which reports
the metrics a test gives it, or zero insets on a 320 by 640 screen. Every test file needs it, so it goes
in a setup file that Jest runs before each one. Save this as `jest.setup.ts`:

```typescript
// jest.setup.ts: runs before every test file.
// The library's own stand-in: there is no native side in Jest to measure the safe areas.
jest.mock("react-native-safe-area-context", () => require("react-native-safe-area-context/jest/mock").default);
```

And tell Jest about it in `package.json`:

```sh
npm pkg set "jest.setupFiles[0]=./jest.setup.ts"
```

The screen's test can then pretend to be a phone with a notch, by giving its own provider the metrics of
one. Replace `__tests__/PlanScreen.test.tsx` with:

```tsx
// __tests__/PlanScreen.test.tsx: the screen, read the way a screen reader reads it,
// inside a safe-area provider that pretends to be a phone with a notch.
import { fireEvent, render, screen } from "@testing-library/react-native";
import type { ReactElement } from "react";
import { SafeAreaProvider } from "react-native-safe-area-context";
import data from "../src/courses.json";
import { PlanScreen } from "../src/PlanScreen";
import type { Plan } from "../src/planner";

const plan: Plan = data;
const phone = { frame: { x: 0, y: 0, width: 390, height: 844 }, insets: { top: 47, left: 0, right: 0, bottom: 34 } };
const inPhone = (ui: ReactElement) => <SafeAreaProvider initialMetrics={phone}>{ui}</SafeAreaProvider>;

test("every course is a button named for what it holds", async () => {
  await render(inPhone(<PlanScreen plan={plan} today="2026-10-21" />));
  expect(screen.getAllByRole("button")).toHaveLength(3);
  expect(screen.getByRole("button", { name: "Spanish A2 2 sessions planned" })).toBeOnTheScreen();
});

test("pressing a course opens it", async () => {
  await render(inPhone(<PlanScreen plan={plan} today="2026-10-21" />));
  await fireEvent.press(screen.getByRole("button", { name: /Guitar/ }));
  expect(screen.getByRole("status")).toHaveTextContent("Open: Guitar");
});
```
