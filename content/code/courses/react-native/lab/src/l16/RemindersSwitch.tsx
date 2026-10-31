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
