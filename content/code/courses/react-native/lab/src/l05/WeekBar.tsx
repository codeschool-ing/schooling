// src/WeekBar.tsx: the week's minutes as a bar, done against planned, laid out by flex alone.
import { StyleSheet, View } from "react-native";
import { useTheme } from "./theme";

type Props = { done: number; planned: number };

export function WeekBar({ done, planned }: Props) {
  const t = useTheme();
  return (
    <View
      testID="week-bar"
      accessible
      role="progressbar"
      aria-label="Minutes done this week"
      aria-valuemin={0}
      aria-valuemax={planned}
      aria-valuenow={done}
      style={[styles.track, { backgroundColor: t.track }]}
    >
      <View testID="week-done" style={{ flex: done, backgroundColor: t.accent }} />
      <View testID="week-left" style={{ flex: planned - done }} />
    </View>
  );
}

const styles = StyleSheet.create({
  track: { flexDirection: "row", height: 12, borderRadius: 6, overflow: "hidden" },
});
