// src/CourseScreen.tsx: one course, reached with its id, looked up in the shared plan.
import type { NativeStackScreenProps } from "@react-navigation/native-stack";
import { useLayoutEffect } from "react";
import { StyleSheet, Text, View } from "react-native";
import type { RootParams } from "./navigation";
import { usePlan } from "./planState";
import { SessionList } from "./SessionList";
import { useTheme } from "./theme";

export function CourseScreen({ route, navigation }: NativeStackScreenProps<RootParams, "Course">) {
  const { plan, dispatch } = usePlan();
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
      <SessionList
        sessions={plan.sessions.filter((s) => s.course === course.id)}
        onDone={(id) => dispatch({ type: "done", id })}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, paddingHorizontal: 24 },
  missing: { marginTop: 24, fontSize: 17 },
});
