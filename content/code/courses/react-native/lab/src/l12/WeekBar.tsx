// src/WeekBar.tsx: the week's minutes as a bar that grows when a session is done.
// The animation is a transform, so the native driver runs it on the UI thread.
import { useEffect, useRef, useState } from "react";
import { AccessibilityInfo, Animated, Easing, StyleSheet, View } from "react-native";
import { useTheme } from "./theme";

type Props = { done: number; planned: number };

export function WeekBar({ done, planned }: Props) {
  const t = useTheme();
  const share = planned > 0 ? done / planned : 0;
  const scale = useRef(new Animated.Value(share)).current;
  const [width, setWidth] = useState(0);
  useEffect(() => {
    let stopped = false;
    AccessibilityInfo.isReduceMotionEnabled().then((reduce) => {
      if (stopped) return;
      Animated.timing(scale, {
        toValue: share,
        duration: reduce ? 0 : 300,
        easing: Easing.out(Easing.cubic),
        useNativeDriver: true,
      }).start();
    });
    return () => {
      stopped = true;
    };
  }, [share, scale]);
  return (
    <View
      testID="week-bar"
      accessible
      role="progressbar"
      aria-label="Minutes done this week"
      aria-valuemin={0}
      aria-valuemax={planned}
      aria-valuenow={done}
      onLayout={(e) => setWidth(e.nativeEvent.layout.width)}
      style={[styles.track, { backgroundColor: t.track }]}
    >
      <Animated.View
        testID="week-done"
        style={[
          styles.done,
          { width, backgroundColor: t.accent },
          // grow from the left edge: move left by half the width, scale, move back
          { transform: [{ translateX: -width / 2 }, { scaleX: scale }, { translateX: width / 2 }] },
        ]}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  track: { height: 12, borderRadius: 6, overflow: "hidden" },
  done: { height: 12 },
});
