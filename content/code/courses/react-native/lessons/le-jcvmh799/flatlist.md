---
title: FlatList, and the planner's first screen as one
version: 1
---

**A FlatList needs three things: the `data`, a `renderItem` that draws one entry, and a `keyExtractor`
that says which entry is which.**

```tsx
<FlatList
  data={plan.courses}
  keyExtractor={(c) => c.id}
  renderItem={({ item }) => <CourseRow course={item} sessions={0} onOpen={setOpen} />}
/>
```

`renderItem` receives `{ item, index }`, and returns what to draw for that item. It is called only for
the items being rendered, so it must not depend on having been called for every one.

## The list owns the scrolling

**A FlatList is itself a scroll view**, and putting it inside a `ScrollView` that scrolls the same way
breaks it: the outer view gives the list all the height it asks for, the list concludes that every item
is visible, and renders them all. React Native warns about exactly this, *VirtualizedLists should never
be nested inside plain ScrollViews with the same orientation*. So the planner's screen turns inside out:
the FlatList becomes the screen, and what sat above and below the list goes into it.

| prop | what it holds |
|---|---|
| `ListHeaderComponent` | what scrolls in above the items: here the heading, the total and the bar |
| `ListFooterComponent` | what scrolls in below them: the status line and the sentence of lesson 6 |
| `ListEmptyComponent` | what to show when `data` is empty |
| `contentContainerStyle` | padding around everything, as on a ScrollView |

Replace `src/PlanScreen.tsx` with this:

```tsx
// src/PlanScreen.tsx: the first screen, with the courses in a FlatList.
import { useState } from "react";
import { FlatList, Image, StyleSheet, Text, View } from "react-native";
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
      {course && (
        <Text role="status" style={[styles.total, { color: t.text }]}>
          Open: {course.name}
        </Text>
      )}
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
          onOpen={setOpen}
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

`header` and `footer` are elements built in the component, so they see its state and its theme like
everything else.

## Checked as before

The tests of lesson 4 and lesson 6 find the same buttons and the same status line in the new screen,
which is the point of testing by what a person sees rather than by how it is built:

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npx jest PlanScreen App
PASS __tests__/App.test.tsx
PASS __tests__/PlanScreen.test.tsx

Test Suites: 2 passed, 2 total
Tests:       3 passed, 3 total
Snapshots:   0 total
Time:        1.46 s
Ran all test suites matching PlanScreen|App.
```

The web build reads the same as it did, a heading, the total, the bar, and three buttons:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:8082/?today=2026-10-21'
- heading "Study planner" [level=1]
- text: "This week: 75 of 125 minutes done"
- progressbar "Minutes done this week"
- button "Spanish A2 2 sessions planned"
- button "Statistics 2 sessions planned"
- button "Guitar 2 sessions planned"
- text: Saved in this browser
```

**One thing was lost, and it is worth saying.** Lesson 4 put the courses in a `View` with `role="list"`,
so a screen reader announced *list, three items*. A FlatList draws its own cells and gives them no role,
and a `role="list"` on the FlatList itself would cover the heading and the footer too, since they are
inside it now; the first recording of this section had exactly that, a `list` containing the heading. So
the three buttons now stand after the bar without a list around them. Each still says what it is and
what it holds, which is what a person needs to choose one.
