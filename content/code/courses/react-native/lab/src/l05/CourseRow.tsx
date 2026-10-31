// src/CourseRow.tsx: one course in the list, as a button that says what it holds.
import { Pressable, StyleSheet, Text, View } from "react-native";
import type { Course } from "./planner";
import { useTheme } from "./theme";

type Props = { course: Course; sessions: number; onOpen: (id: string) => void };

export function CourseRow({ course, sessions, onOpen }: Props) {
  const t = useTheme();
  return (
    <Pressable
      testID={`row-${course.id}`}
      role="button"
      accessibilityHint={`Opens ${course.name}`}
      onPress={() => onOpen(course.id)}
      hitSlop={8}
      style={({ pressed }) => [styles.row, { borderColor: t.line }, pressed && { backgroundColor: t.pressed }]}
    >
      <View>
        <Text style={[styles.name, { color: t.text }]}>{course.name}</Text>
        <Text style={[styles.count, { color: t.muted }]}>
          {sessions} {sessions === 1 ? "session" : "sessions"} planned
        </Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  row: { paddingVertical: 12, paddingHorizontal: 16, borderBottomWidth: 1 },
  name: { fontSize: 17, fontWeight: "600" },
  count: { fontSize: 14 },
});
