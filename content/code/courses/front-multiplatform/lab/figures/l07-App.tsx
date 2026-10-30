// App.tsx: the planner's screen, drawn with React Native's own components.
import { useState } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { markDone, mondayOf, weekTotal, type Plan } from "./src/planner";
import data from "./src/courses.json";

// The transcripts open the web build with ?today=2026-10-21, as lesson 1 does.
const query = typeof location === "undefined" ? "" : location.search;
const today = new URLSearchParams(query).get("today") ?? new Date().toISOString().slice(0, 10);

export default function App() {
  const [plan, setPlan] = useState<Plan>(data);
  const [open, setOpen] = useState<string | null>(null);
  const total = weekTotal(plan, mondayOf(today));
  return (
    <View role="main" style={styles.screen}>
      <Text role="heading" style={styles.title}>Study planner</Text>
      <Text>This week: {total.done} of {total.planned} minutes done</Text>
      {plan.courses.map((course) => (
        <View key={course.id}>
          <Pressable role="button" onPress={() => setOpen(open === course.id ? null : course.id)}>
            <Text style={styles.course}>{course.name}</Text>
          </Pressable>
          {open === course.id &&
            plan.sessions.filter((s) => s.course === course.id).map((s) => (
              <View key={s.id} style={styles.row}>
                <Text>{s.date}, {s.minutes} min</Text>
                {s.done ? <Text>done</Text> : (
                  <Pressable role="button" onPress={() => setPlan(markDone(plan, s.id))}>
                    <Text style={styles.action}>Mark done</Text>
                  </Pressable>
                )}
              </View>
            ))}
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, padding: 24, gap: 8 },
  title: { fontSize: 28, fontWeight: "700" },
  course: { fontSize: 20, paddingVertical: 8 },
  row: { flexDirection: "row", gap: 12, paddingLeft: 16 },
  action: { color: "#0a58ca" },
});
