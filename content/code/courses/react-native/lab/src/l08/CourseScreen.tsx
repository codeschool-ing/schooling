// src/CourseScreen.tsx: one course, reached with its id and nothing else.
import type { NativeStackScreenProps } from "@react-navigation/native-stack";
import { useLayoutEffect } from "react";
import { StyleSheet, Text, View } from "react-native";
import data from "./courses.json";
import type { RootParams } from "./navigation";
import type { Plan } from "./planner";
import { SessionList } from "./SessionList";
import { useTheme } from "./theme";

const plan: Plan = data;

export function CourseScreen({ route, navigation }: NativeStackScreenProps<RootParams, "Course">) {
  const t = useTheme();
  const course = plan.courses.find((c) => c.id === route.params.id);
  useLayoutEffect(() => {
    navigation.setOptions({ title: course?.name ?? "Not found" });
  }, [navigation, course]);
  if (!course) {
    return (
      <View style={[styles.screen, { backgroundColor: t.background }]}>
        <Text style={[styles.missing, { color: t.text }]}>There is no course called {route.params.id}.</Text>
      </View>
    );
  }
  return (
    <View style={[styles.screen, { backgroundColor: t.background }]}>
      <SessionList sessions={plan.sessions.filter((s) => s.course === course.id)} />
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, paddingHorizontal: 24 },
  missing: { marginTop: 24, fontSize: 17 },
});
