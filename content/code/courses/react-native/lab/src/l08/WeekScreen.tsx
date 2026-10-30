// src/WeekScreen.tsx: every session of this week, whatever its course.
import { StyleSheet, View } from "react-native";
import data from "./courses.json";
import { mondayOf, type Plan } from "./planner";
import { SessionList } from "./SessionList";
import { useTheme } from "./theme";
import { today } from "./today";

const plan: Plan = data;

export function WeekScreen() {
  const t = useTheme();
  const monday = mondayOf(today());
  const week = plan.sessions.filter((s) => mondayOf(s.date) === monday);
  return (
    <View style={[styles.screen, { backgroundColor: t.background }]}>
      <SessionList sessions={week} />
    </View>
  );
}

const styles = StyleSheet.create({ screen: { flex: 1, paddingHorizontal: 24 } });
