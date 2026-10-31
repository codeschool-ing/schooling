// src/WeekScreen.tsx: every session of this week, whatever its course; any can be marked done.
import { StyleSheet, View } from "react-native";
import { usePlan } from "./planState";
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
      <SessionList sessions={week} onDone={(id) => dispatch({ type: "done", id })} />
    </View>
  );
}

const styles = StyleSheet.create({ screen: { flex: 1, paddingHorizontal: 24 } });
