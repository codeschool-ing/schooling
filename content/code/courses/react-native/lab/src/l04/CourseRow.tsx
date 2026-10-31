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
