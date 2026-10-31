// src/WeekScreen.tsx: every session of this week, whatever its course; any can be marked done, and what
// this phone has logged sits above them.
import { StyleSheet, Text, View } from "react-native";
import { useJournal, usePlan } from "./planState";
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
      <Logged />
      <SessionList sessions={week} onDone={(id) => dispatch({ type: "done", id })} />
    </View>
  );
}

// What this phone has logged, from the journal: it survives a restart, and it is this phone's alone.
function Logged() {
  const { plan } = usePlan();
  const t = useTheme();
  const { data } = useJournal();
  if (!data) return null;
  const name = (id: string) => plan.courses.find((c) => c.id === id)?.name ?? id;
  const text = data.length
    ? "Logged on this phone: " + data.map((r) => `${name(r.course)} ${r.minutes} min`).join(", ")
    : "Nothing logged on this phone yet";
  return <Text style={[styles.logged, { color: t.muted }]}>{text}</Text>;
}

const styles = StyleSheet.create({
  screen: { flex: 1, paddingHorizontal: 24 },
  logged: { marginTop: 16, fontSize: 15 },
});
