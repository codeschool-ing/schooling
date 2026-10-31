---
title: Reanimated: worklets on the UI thread
version: 1
---

**The native driver has a limit: it can only run animations it was told about in advance.** A timing, a
spring, a sequence, all fixed when they start. It cannot follow a finger, because where the finger goes
next is not known in advance, and it cannot compute a value from two others on every frame. For that the
code itself has to run on the UI thread, and that is what **Reanimated** does.

Reanimated rests on two ideas:

- **A shared value** is a number (or an object) that both threads can read and write. JavaScript sets it,
  and the UI thread sees the change without a render.
- **A worklet** is a small JavaScript function that Reanimated's Babel plugin copies to a second
  JavaScript runtime living on the UI thread. It runs there on every frame. It may read shared values,
  and it may call other worklets, but not ordinary functions from the rest of your app, which live on the
  other thread.

Since Reanimated 4 the worklet machinery is its own package, `react-native-worklets`, and it is installed
beside it. The gesture library of the next section uses both:

```
ana@dev:~/planner$ npx expo install react-native-reanimated react-native-worklets react-native-gesture-handler
Unable to fetch compatibility data from React Native Directory. Skipping check.
Dependency validation is unreliable in offline-mode
› Installing 3 SDK 58.0.0 compatible native modules using npm
> npm install

added 18 packages, and audited 1112 packages in 9s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

`npx expo install` picks the versions that SDK 58 was tested with, rather than the newest of each, and
writes them into `package.json`. Both libraries contain native code, so a development build has to be
rebuilt to carry them, as lesson 3 said of every library with native code; Expo Go already has them.

## The week bar, written for Reanimated

The `Animated` version of the bar works and stays. Here is the same bar in Reanimated, to compare
the two ways of saying it. It is not part of the planner:

```schooling-example
{"language": "tsx", "file": "src/WeekBarReanimated.tsx", "parts": [{"code": "// src/WeekBarReanimated.tsx: the week bar again, with the animation written for Reanimated.\nimport { useEffect, useState } from \"react\";\nimport { StyleSheet, View } from \"react-native\";\nimport Animated, {\n  Easing,\n  ReduceMotion,\n  useAnimatedStyle,\n  useSharedValue,\n  withTiming,\n} from \"react-native-reanimated\";\nimport { useTheme } from \"./theme\";\n\ntype Props = { done: number; planned: number };\n", "note": "The imports are the whole vocabulary: a value both threads can read, a style computed from it, and an animation that moves it."}, {"code": "export function WeekBar({ done, planned }: Props) {\n  const t = useTheme();\n  const share = planned > 0 ? done / planned : 0;\n  const scale = useSharedValue(share);\n  const [width, setWidth] = useState(0);", "note": "`useSharedValue` takes the place of `useRef(new Animated.Value(...))`. It is created once, like the ref, and it lives where the UI thread can read it."}, {"code": "  useEffect(() => {\n    scale.value = withTiming(share, {\n      duration: 300,\n      easing: Easing.out(Easing.cubic),\n      reduceMotion: ReduceMotion.System,\n    });\n  }, [share, scale]);", "note": "Assigning an animation to `.value` starts it. `ReduceMotion.System` follows the phone's setting by itself, so the question the `Animated` version asked by hand is gone."}, {"code": "  const grown = useAnimatedStyle(() => ({\n    transform: [{ translateX: -width / 2 }, { scaleX: scale.value }, { translateX: width / 2 }],\n  }));", "note": "This function is a **worklet**: Reanimated's Babel plugin copies it to the UI thread, which runs it on every frame and sets the transform without asking JavaScript. `width` is copied along with it each time the component renders."}, {"code": "  return (\n    <View\n      accessible\n      role=\"progressbar\"\n      aria-label=\"Minutes done this week\"\n      aria-valuemin={0}\n      aria-valuemax={planned}\n      aria-valuenow={done}\n      onLayout={(e) => setWidth(e.nativeEvent.layout.width)}\n      style={[styles.track, { backgroundColor: t.track }]}\n    >\n      <Animated.View style={[styles.done, { width, backgroundColor: t.accent }, grown]} />\n    </View>\n  );\n}\n\nconst styles = StyleSheet.create({\n  track: { height: 12, borderRadius: 6, overflow: \"hidden\" },\n  done: { height: 12 },\n});", "note": "The rest is the same component: the same track, the same accessible values. Only the animated style changed hands."}]}
```

*This version was checked by the TypeScript compiler against Reanimated 4.7.1 and was not run, in Jest,
in a browser or on a phone.* Next to the `Animated` one it says the same thing in fewer words, and that
is the trade: **for an animation known in advance, the native driver is enough**, and Reanimated earns
its place when the animation has to answer something that is happening, like a finger.

## Where worklets bite

A worklet is copied, not called, and that has consequences you meet the first time you write one:

- **A function it calls must be a worklet too.** A plain function from your module is not on the UI
  thread, and calling it there crashes the app. Mark it with the `"worklet"` directive as its first line.
- **Going back to JavaScript is explicit.** From a worklet, `scheduleOnRN(f)` asks the JavaScript thread
  to run `f` when it can; that is how a gesture ends in a state update or a request.
- **What it captures is a copy.** A variable from the component is copied in when the worklet is made, so
  changing it later on the JavaScript side does not reach the copy until the next render makes a new one.
