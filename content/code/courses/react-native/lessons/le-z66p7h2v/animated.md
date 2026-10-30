---
title: Animated, and the native driver
version: 1
---

**`Animated` is React Native's built-in animation library.** An `Animated.Value` holds a number;
`Animated.timing` moves it to a new number over a duration with an easing curve; an `Animated.View` reads
it in its style. With `useNativeDriver: true`, the whole animation is described to the native side once,
and the UI thread runs every frame.

The planner's week bar grows when a session is done. Replace `src/WeekBar.tsx` with this version:

```tsx
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
```

**The bar is drawn full width and scaled.** `scaleX` from 0.6 to 0.76 makes it look 60 then 76 percent
wide, without a layout. A scale shrinks towards the centre, so the transform moves the view left by half
its width, scales it, and moves it back, which pins its left edge. The width comes from `onLayout`, the
track's size once Yoga has computed it.

`useRef(new Animated.Value(share)).current` creates the value once, on the first render, and keeps it:
a value created on every render would restart from the beginning each time. The effect starts an
animation whenever the share changes, and lesson 9's rule about effects holds here too: the clean-up marks
the effect as stopped, so an answer about reduced motion that arrives late does not start an animation on
a bar that has moved on.

## Tested where a test can see

Jest's stand-in for the native animation module does not run the frames, so the test checks what is
true whatever the animation does: the value a screen reader hears. Replace `__tests__/WeekBar.test.tsx`:

```tsx
// __tests__/WeekBar.test.tsx: the bar's value, which is what a screen reader hears.
// How it moves is measured in the browser, where the animation really runs.
import { render, screen } from "@testing-library/react-native";
import { WeekBar } from "../src/WeekBar";

test("the bar says its value, before and after a session is done", async () => {
  const view = await render(<WeekBar done={75} planned={125} />);
  expect(screen.getByRole("progressbar")).toHaveAccessibilityValue({ min: 0, max: 125, now: 75 });
  await view.rerender(<WeekBar done={95} planned={125} />);
  expect(screen.getByRole("progressbar")).toHaveAccessibilityValue({ now: 95 });
});
```

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npx jest WeekBar --forceExit
PASS __tests__/WeekBar.test.tsx
  ✓ the bar says its value, before and after a session is done (194 ms)

Test Suites: 1 passed, 1 total
Tests:       1 passed, 1 total
Snapshots:   0 total
Time:        0.787 s, estimated 1 s
Ran all test suites matching WeekBar.
Force exiting Jest: Have you considered using `--detectOpenHandles` to detect async operations that kept running after all tests finished?
```

How the bar moves is the next section's job, in a browser where the animation really runs.
