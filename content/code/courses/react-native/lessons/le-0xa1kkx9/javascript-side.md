---
title: The JavaScript side
version: 1
---

The module's type on a phone says what the native side promises. Save
`modules/week-start/src/WeekStartModule.ts`:

```ts
// modules/week-start/src/WeekStartModule.ts: the native module, as JavaScript sees it on a phone.
import { NativeModule, requireNativeModule } from "expo";

declare class WeekStartModule extends NativeModule {
  /** The first day of the week in the phone's calendar: 0 is Sunday, 1 Monday, as Date.getDay() counts. */
  firstWeekday(): number;
}

export default requireNativeModule<WeekStartModule>("WeekStart");
```

**`requireNativeModule("WeekStart")` finds the native module by the name `Name` gave it**, and throws if
there is none: a development build made before the module existed, or Expo Go, which carries only the
modules it was built with.
The `declare class` is the module's type, written by hand. It is a promise the TypeScript compiler cannot
check against the Kotlin, so the comment says exactly what the number means.

On the web there is no Kotlin and no Swift; the same question goes to the browser's `Intl`. Save
`modules/week-start/src/WeekStartModule.web.ts`:

```ts
// modules/week-start/src/WeekStartModule.web.ts: the same answer in a browser, from Intl.
import { NativeModule, registerWebModule } from "expo";

type WeekInfo = { firstDay: number }; // 1 is Monday … 7 is Sunday
type WithWeekInfo = Intl.Locale & { getWeekInfo?: () => WeekInfo; weekInfo?: WeekInfo };

class WeekStartModule extends NativeModule {
  firstWeekday() {
    const locale = new Intl.Locale(navigator.language) as WithWeekInfo;
    const info = locale.getWeekInfo?.() ?? locale.weekInfo;
    return info ? info.firstDay % 7 : 1; // a browser that cannot say gets Monday, the planner's own week
  }
}

export default registerWebModule(WeekStartModule, "WeekStart");
```

`Intl.Locale` can describe a locale's week, as `getWeekInfo()` in newer browsers and `weekInfo` in older
ones, and counts Monday as 1 and Sunday as 7, so `% 7` turns 7 into 0. A browser with neither gets Monday,
which is the planner's own week. And the day names, shared by every platform, go in
`modules/week-start/src/WeekStart.types.ts`:

```ts
// modules/week-start/src/WeekStart.types.ts: the names of the days, in the order firstWeekday counts them.
export const DAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"] as const;
```

## On the screen

The planner does not change its weeks: totals, the week screen and the journal all count from Monday, and
moving all of them is a decision about the product. What it can do is say what the phone thinks, at the
foot of the *Courses* tab. In `src/PlanScreen.tsx`:

```tsx
// src/PlanScreen.tsx: the Courses tab, drawn from the shared plan, with the reminders switch and what the
// phone's calendar says about the week at its foot.
import type { BottomTabScreenProps } from "@react-navigation/bottom-tabs";
import type { CompositeScreenProps } from "@react-navigation/native";
import type { NativeStackScreenProps } from "@react-navigation/native-stack";
import { FlatList, Image, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import WeekStart, { DAYS } from "../modules/week-start";
import { CourseRow } from "./CourseRow";
import type { RootParams, TabParams } from "./navigation";
import { usePlan } from "./planState";
import { RemindersSwitch } from "./RemindersSwitch";
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
      <RemindersSwitch />
      <Text style={[styles.footer, { color: t.muted }]}>{savedWhere}</Text>
      <Text style={[styles.footer, { color: t.muted }]}>
        Your phone's calendar starts the week on {DAYS[WeekStart.firstWeekday()]}; the planner's weeks start on Monday.
      </Text>
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

The function is synchronous, so the text is right on the first render, with no effect and no loading
state. That is the reason `firstWeekday` is a `Function` and not an `AsyncFunction`.
