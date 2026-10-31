---
title: The switch, and the order of two calls
version: 1
---

Reminders are off until the person turns them on, at the foot of the *Courses* tab. Save
`src/RemindersSwitch.tsx`:

```tsx
// src/RemindersSwitch.tsx: the switch for session reminders, and the effect that keeps them in step
// with the plan while it is on.
import { useEffect, useState } from "react";
import { Platform, StyleSheet, Switch, Text, View } from "react-native";
import { usePlan } from "./planState";
import { remindersOn, scheduleReminders, setReminders } from "./reminders";
import { useTheme } from "./theme";

export function RemindersSwitch() {
  const { plan } = usePlan();
  const t = useTheme();
  const [on, setOn] = useState(false);
  const [refused, setRefused] = useState(false);
  useEffect(() => {
    remindersOn().then(setOn);
  }, []);
  useEffect(() => {
    if (on) scheduleReminders(plan);
  }, [on, plan]);
  // A browser's notifications are another system, which expo-notifications does not schedule.
  if (Platform.OS === "web") return null;
  async function change(want: boolean) {
    const result = await setReminders(want);
    setOn(result === "on");
    setRefused(result === "refused");
  }
  return (
    <View style={styles.box}>
      <View style={styles.row}>
        <Text style={[styles.label, { color: t.text }]}>Remind me on the day</Text>
        <Switch value={on} onValueChange={change} aria-label="Remind me on the day" />
      </View>
      {refused && (
        <Text role="alert" style={{ color: t.text }}>
          Notifications are off for the planner, so it cannot remind you. You can turn them on in Settings.
        </Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  box: { marginTop: 16, gap: 4 },
  row: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  label: { fontSize: 16 },
});
```

**The second effect is what keeps reminders true.** Whenever the plan changes, a session done, added or
moved, and the switch is on, every reminder is replaced. Marking the guitar session done therefore cancels
its reminder within the same second, which is the difference between a reminder and a nag.

**On Android 13 and later, the order inside `setReminders` decides whether the person is asked at all.** The
system shows the notification dialog only to an app that has at least one **channel**, so
`setNotificationChannelAsync` comes before `requestPermissionsAsync`. Ask first and no dialog appears, and
nobody can tell why from the screen. A channel is also what the person sees in the app's
notification settings, one switch per channel, so its name, *Study reminders*, is written for them.

On the web the switch is not drawn at all: a browser has notifications of its own, which `expo-notifications`
does not schedule, and a switch that does nothing is worse than none. Then the switch goes into the footer
of `src/PlanScreen.tsx`:

```tsx
// src/PlanScreen.tsx: the Courses tab, drawn from the shared plan, with the reminders switch at its foot.
import type { BottomTabScreenProps } from "@react-navigation/bottom-tabs";
import type { CompositeScreenProps } from "@react-navigation/native";
import type { NativeStackScreenProps } from "@react-navigation/native-stack";
import { FlatList, Image, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
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
