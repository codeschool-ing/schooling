---
title: The form screen
version: 1
---

**The new screen is pushed on the stack from a course, with the course's id as its only param**, like
the Course screen in lesson 8. Save it as `src/AddSessionScreen.tsx`:

```schooling-example
{"language": "tsx", "file": "src/AddSessionScreen.tsx", "parts": [{"code": "// src/AddSessionScreen.tsx: a form for one new session: two fields, their errors, and the keyboard.\nimport type { NativeStackScreenProps } from \"@react-navigation/native-stack\";\nimport React, { useEffect, useRef, useState } from \"react\";\nimport { Alert, KeyboardAvoidingView, Platform, Pressable, ScrollView, StyleSheet, Text, TextInput } from \"react-native\";\nimport type { RootParams } from \"./navigation\";\nimport { useAddSession } from \"./planState\";\nimport { useTheme } from \"./theme\";\nimport { validate, type Draft, type Errors } from \"./validate\";\n", "note": "The form uses React Native's own components, the add mutation of the section on the server, the theme, and the validator."}, {"code": "type Props = NativeStackScreenProps<RootParams, \"AddSession\">;\n", "note": "A stack screen whose params are the course's id, as `RootParams` declares."}, {"code": "export function AddSessionScreen({ route, navigation }: Props) {\n  const t = useTheme();\n  const add = useAddSession();\n  const [draft, setDraft] = useState<Draft>({ date: \"\", minutes: \"\" });\n  const [errors, setErrors] = useState<Errors>({});\n  const minutesRef = useRef<React.ComponentRef<typeof TextInput>>(null);\n  const saved = useRef(false);\n  const dirty = draft.date !== \"\" || draft.minutes !== \"\";\n", "note": "**The draft is two strings**, never numbers, so a half-typed value is kept as typed. `errors` holds the sentences of the last failed save. `minutesRef` lets the date field's return key move on; `saved` and `dirty` decide whether leaving must ask."}, {"code": "  // Leaving with something typed asks first, however the person tries to leave.\n  useEffect(() => {\n    return navigation.addListener(\"beforeRemove\", (e) => {\n      if (!dirty || saved.current) return;\n      e.preventDefault();\n      Alert.alert(\"Discard this session?\", \"What you typed will be lost.\", [\n        { text: \"Keep editing\", style: \"cancel\" },\n        { text: \"Discard\", style: \"destructive\", onPress: () => navigation.dispatch(e.data.action) },\n      ]);\n    });\n  }, [navigation, dirty]);\n", "note": "The leaving guard of the section on leaving: when something is typed and not saved, stop the navigation and ask."}, {"code": "  async function save() {\n    const found = validate(draft);\n    setErrors(found);\n    if (Object.keys(found).length > 0) return;\n    try {\n      await add.mutateAsync({ course: route.params.course, date: draft.date, minutes: Number(draft.minutes) });\n    } catch {\n      return; // add.error now holds the reason, and the form shows it below the fields\n    }\n    saved.current = true; // what was typed is on the server: leaving loses nothing\n    navigation.goBack();\n  }\n", "note": "**Save validates first** and stops at the first refusal, with the sentences on screen. A server refusal is caught and left in `add.error`, which the form shows; only a success goes back."}, {"code": "  const field = (key: keyof Draft) => [styles.input, { color: t.text, borderColor: errors[key] ? t.danger : t.line }];\n  const error = [styles.error, { color: t.danger }];\n  return (\n    <KeyboardAvoidingView style={{ flex: 1 }} behavior={Platform.OS === \"ios\" ? \"padding\" : undefined}>\n      <ScrollView style={{ backgroundColor: t.background }} contentContainerStyle={styles.form} keyboardShouldPersistTaps=\"handled\">\n        <Text style={[styles.label, { color: t.text }]}>\n          Date\n        </Text>\n        <TextInput\n          aria-label=\"Date\"\n          value={draft.date}\n          onChangeText={(date) => setDraft({ ...draft, date })}\n          placeholder=\"2026-10-23\"\n          keyboardType=\"numbers-and-punctuation\"\n          autoComplete=\"off\"\n          returnKeyType=\"next\"\n          onSubmitEditing={() => minutesRef.current?.focus()}\n          style={field(\"date\")}\n        />\n        {errors.date && <Text role=\"alert\" style={error}>{errors.date}</Text>}\n        <Text style={[styles.label, { color: t.text }]}>\n          Minutes\n        </Text>\n        <TextInput\n          ref={minutesRef}\n          aria-label=\"Minutes\"\n          value={draft.minutes}\n          onChangeText={(minutes) => setDraft({ ...draft, minutes })}\n          placeholder=\"30\"\n          keyboardType=\"number-pad\"\n          returnKeyType=\"done\"\n          onSubmitEditing={save}\n          style={field(\"minutes\")}\n        />\n        {errors.minutes && <Text role=\"alert\" style={error}>{errors.minutes}</Text>}\n        {add.error && <Text role=\"alert\" style={error}>The server refused it: {add.error.message}</Text>}\n        <Pressable role=\"button\" onPress={save} disabled={add.isPending} style={[styles.save, { backgroundColor: t.accent }]}>\n          <Text style={[styles.saveText, { color: t.background }]}>{add.isPending ? \"Saving\" : \"Save session\"}</Text>\n        </Pressable>\n      </ScrollView>\n    </KeyboardAvoidingView>\n  );\n}\n", "note": "The fields. Each has a visible label and an `aria-label`, the keyboard its content needs, and a return key that moves on or saves. Every error is a `role=\"alert\"`, announced when it appears. The view moves up for the keyboard on iOS; the scroll view lets a tap reach *Save* while it is open."}, {"code": "const styles = StyleSheet.create({\n  form: { padding: 24, gap: 8 },\n  label: { fontSize: 15, fontWeight: \"600\", marginTop: 8 },\n  input: { borderWidth: 1, borderRadius: 8, padding: 12, fontSize: 17 },\n  error: { fontSize: 14 },\n  save: { marginTop: 16, padding: 14, borderRadius: 8, alignItems: \"center\" },\n  saveText: { fontSize: 17, fontWeight: \"600\" },\n});", "note": "Sizes and spacing only; every colour comes from the theme."}]}
```

## The three files around it

The form needs a colour for errors, in both palettes, so the theme gains `danger`. On their own
backgrounds, the light palette's red reaches 5.4 to 1 and the dark palette's 7.5 to 1. The *Save*
button writes the background colour on the accent, 6.0 to 1 in light and 6.8 in dark. Replace
`src/theme.ts`:

```typescript
// src/theme.ts: the planner's colours, one set for each colour scheme.
import { useColorScheme } from "react-native";

const light = {
  background: "#ffffff",
  text: "#1f2328",
  muted: "#57606a",
  line: "#d0d7de",
  pressed: "#eef2f6",
  track: "#e6ebf0",
  accent: "#2f6f4e",
  danger: "#cf222e",
};
const dark: typeof light = {
  background: "#0d1117",
  text: "#e6edf3",
  muted: "#9198a1",
  line: "#3d444d",
  pressed: "#161b22",
  track: "#21262d",
  accent: "#57ab7a",
  danger: "#ff7b72",
};
export type Theme = typeof light;

export function useTheme(): Theme {
  return useColorScheme() === "dark" ? dark : light;
}
```

The navigators gain the screen and its address, `course/:course/add`. Replace `src/navigation.tsx`:

```tsx
// src/navigation.tsx: the planner's screens, how they nest, and the addresses that reach them.
import { createBottomTabNavigator } from "@react-navigation/bottom-tabs";
import type { LinkingOptions, NavigatorScreenParams } from "@react-navigation/native";
import { createNativeStackNavigator } from "@react-navigation/native-stack";
import { AddSessionScreen } from "./AddSessionScreen";
import { CourseScreen } from "./CourseScreen";
import { PlanScreen } from "./PlanScreen";
import { WeekScreen } from "./WeekScreen";

export type TabParams = { Courses: undefined; Week: undefined };
export type RootParams = {
  Tabs: NavigatorScreenParams<TabParams>;
  Course: { id: string };
  AddSession: { course: string };
};

const Tab = createBottomTabNavigator<TabParams>();
const Stack = createNativeStackNavigator<RootParams>();

function Tabs() {
  return (
    <Tab.Navigator screenOptions={{ tabBarIcon: () => null }}>
      <Tab.Screen name="Courses" component={PlanScreen} options={{ headerShown: false }} />
      <Tab.Screen name="Week" component={WeekScreen} options={{ title: "This week" }} />
    </Tab.Navigator>
  );
}

export function RootNavigator() {
  return (
    <Stack.Navigator>
      <Stack.Screen name="Tabs" component={Tabs} options={{ headerShown: false, title: "Courses" }} />
      <Stack.Screen name="Course" component={CourseScreen} options={{ title: "Course" }} />
      <Stack.Screen name="AddSession" component={AddSessionScreen} options={{ title: "New session" }} />
    </Stack.Navigator>
  );
}

export const linking: LinkingOptions<RootParams> = {
  prefixes: ["planner://"],
  config: {
    screens: {
      Tabs: { screens: { Courses: "", Week: "week" } },
      Course: "course/:id",
      AddSession: "course/:course/add",
    },
  },
};
```

And the course's screen gains a button that opens the form. Replace `src/CourseScreen.tsx`:

```tsx
// src/CourseScreen.tsx: one course, its sessions, and the way to add one.
import type { NativeStackScreenProps } from "@react-navigation/native-stack";
import { useLayoutEffect } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
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
      <Pressable role="button" onPress={() => navigation.navigate("AddSession", { course: course.id })} style={styles.add}>
        <Text style={[styles.addText, { color: t.accent }]}>Add a session</Text>
      </Pressable>
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
  add: { paddingVertical: 12 },
  addText: { fontSize: 16, fontWeight: "600" },
});
```

## Errors a screen reader hears

**An error that appears silently is invisible to somebody who cannot see it appear.** Each message has
`role="alert"`, which makes VoiceOver and TalkBack announce it the moment it is drawn, without the person
having to look for it. The field with the error also changes its border to `danger`, so the mistake is
marked twice, in colour and in words, and the words are what a person who does not distinguish red from
grey relies on.

The *Save* button says *Saving* while the request is in flight and is disabled meanwhile, so a second
press cannot send the session twice.
