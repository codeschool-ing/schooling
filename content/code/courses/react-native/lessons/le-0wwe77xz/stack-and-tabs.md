---
title: A stack, with tabs inside it
version: 1
---

**The navigators are declared in one file, with every screen, every parameter and every address.**
Save this as `src/navigation.tsx`:

```schooling-example
{"language": "tsx", "file": "src/navigation.tsx", "parts": [{"code": "// src/navigation.tsx: the planner's screens, how they nest, and the addresses that reach them.\nimport { createBottomTabNavigator } from \"@react-navigation/bottom-tabs\";\nimport type { LinkingOptions, NavigatorScreenParams } from \"@react-navigation/native\";\nimport { createNativeStackNavigator } from \"@react-navigation/native-stack\";\nimport { CourseScreen } from \"./CourseScreen\";\nimport { PlanScreen } from \"./PlanScreen\";\nimport { WeekScreen } from \"./WeekScreen\";\n", "note": "The two navigator factories and the three screens. `LinkingOptions` and `NavigatorScreenParams` are types only."}, {"code": "export type TabParams = { Courses: undefined; Week: undefined };\nexport type RootParams = { Tabs: NavigatorScreenParams<TabParams>; Course: { id: string } };\n", "note": "**Every route and its params, in one place.** The tabs take none; the Course screen takes the course's `id`; the stack's `Tabs` route carries the tabs' own state."}, {"code": "const Tab = createBottomTabNavigator<TabParams>();\nconst Stack = createNativeStackNavigator<RootParams>();\n", "note": "The navigators, typed with those params, so `navigate` is checked."}, {"code": "function Tabs() {\n  return (\n    <Tab.Navigator screenOptions={{ tabBarIcon: () => null }}>\n      <Tab.Screen name=\"Courses\" component={PlanScreen} options={{ headerShown: false }} />\n      <Tab.Screen name=\"Week\" component={WeekScreen} options={{ title: \"This week\" }} />\n    </Tab.Navigator>\n  );\n}\n", "note": "The tabs. The list draws its own heading, so its tab shows no header; the week's tab is titled. No icons yet, on purpose."}, {"code": "export function RootNavigator() {\n  return (\n    <Stack.Navigator>\n      <Stack.Screen name=\"Tabs\" component={Tabs} options={{ headerShown: false, title: \"Courses\" }} />\n      <Stack.Screen name=\"Course\" component={CourseScreen} options={{ title: \"Course\" }} />\n    </Stack.Navigator>\n  );\n}\n", "note": "The root stack: the tabs first, the course screen above them. `title` on `Tabs` is what a pushed screen's back button says."}, {"code": "export const linking: LinkingOptions<RootParams> = {\n  prefixes: [\"planner://\"],\n  config: {\n    screens: {\n      Tabs: { screens: { Courses: \"\", Week: \"week\" } },\n      Course: \"course/:id\",\n    },\n  },\n};", "note": "Every screen's address, read in the section on addresses."}]}
```

`NavigatorScreenParams` says that the `Tabs` route carries the tabs' own state, which is how TypeScript
follows a navigation from the stack into a tab. The `linking` object at the end is the subject of the
section on addresses.

## The screens

The course list becomes the *Courses* tab. It no longer takes the plan as a prop: a screen in a navigator
is rendered by the navigator, which passes it `navigation` and `route` and nothing else. **So for this
lesson the screens read the data file directly.** Lesson 9 moves the plan into state that every screen
shares, which is what lets marking a session done on one screen change the total on another. Replace
`src/PlanScreen.tsx` with:

```tsx
// src/PlanScreen.tsx: the Courses tab: the week, and every course, which opens its own screen.
import type { BottomTabScreenProps } from "@react-navigation/bottom-tabs";
import type { CompositeScreenProps } from "@react-navigation/native";
import type { NativeStackScreenProps } from "@react-navigation/native-stack";
import { FlatList, Image, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { CourseRow } from "./CourseRow";
import data from "./courses.json";
import type { RootParams, TabParams } from "./navigation";
import { mondayOf, weekTotal, type Plan } from "./planner";
import { savedWhere } from "./savedWhere";
import { useTheme } from "./theme";
import { today } from "./today";
import { WeekBar } from "./WeekBar";

const plan: Plan = data;
type Props = CompositeScreenProps<BottomTabScreenProps<TabParams, "Courses">, NativeStackScreenProps<RootParams>>;

export function PlanScreen({ navigation }: Props) {
  const t = useTheme();
  const insets = useSafeAreaInsets();
  const total = weekTotal(plan, mondayOf(today()));
  const header = (
    <View>
      <View testID="header" style={styles.header}>
        <Image source={require("../assets/icon.png")} style={styles.icon} aria-hidden />
        <Text role="heading" style={[styles.title, { color: t.text }]}>
          Study planner
        </Text>
      </View>
      <Text style={[styles.total, { color: t.muted }]}>
        This week: {total.done} of {total.planned} minutes done
      </Text>
      <WeekBar done={total.done} planned={total.planned} />
    </View>
  );
  const footer = (
    <View>
      <Text style={[styles.footer, { color: t.muted }]}>{savedWhere}</Text>
    </View>
  );
  return (
    <FlatList
      data={plan.courses}
      keyExtractor={(c) => c.id}
      renderItem={({ item }) => (
        <CourseRow
          course={item}
          sessions={plan.sessions.filter((s) => s.course === item.id).length}
          onOpen={(id) => navigation.navigate("Course", { id })}
        />
      )}
      ListHeaderComponent={header}
      ListHeaderComponentStyle={styles.listTop}
      ListFooterComponent={footer}
      style={{ backgroundColor: t.background }}
      contentContainerStyle={[styles.content, { paddingTop: insets.top + 24, paddingBottom: insets.bottom + 24 }]}
    />
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: 24 },
  header: { flexDirection: "row", alignItems: "center", gap: 12 },
  icon: { width: 40, height: 40 },
  title: { fontSize: 24, fontWeight: "700" },
  total: { marginVertical: 12, fontSize: 15 },
  listTop: { marginBottom: 16 },
  footer: { marginTop: 24, fontSize: 13 },
});
```

The status line of lesson 4 is gone: pressing a course now **navigates** to it. The type `Props` combines
the tab's screen props with the stack's, so that `navigation.navigate("Course", …)`, a stack route called
from inside a tab, is checked by TypeScript too.

The *This week* tab is the week's sessions, in the `SessionList` of lesson 7. Save it as
`src/WeekScreen.tsx`:

```tsx
// src/WeekScreen.tsx: every session of this week, whatever its course.
import { StyleSheet, View } from "react-native";
import data from "./courses.json";
import { mondayOf, type Plan } from "./planner";
import { SessionList } from "./SessionList";
import { useTheme } from "./theme";
import { today } from "./today";

const plan: Plan = data;

export function WeekScreen() {
  const t = useTheme();
  const monday = mondayOf(today());
  const week = plan.sessions.filter((s) => mondayOf(s.date) === monday);
  return (
    <View style={[styles.screen, { backgroundColor: t.background }]}>
      <SessionList sessions={week} />
    </View>
  );
}

const styles = StyleSheet.create({ screen: { flex: 1, paddingHorizontal: 24 } });
```

## The root

`App.tsx` puts a `NavigationContainer` around the navigators. It holds the navigation state for the whole
app, connects it to the platform's back action and, on the web, to the address bar. Replace it with:

```tsx
// App.tsx: the planner's root: safe areas, then navigation with its addresses.
import { NavigationContainer } from "@react-navigation/native";
import { StatusBar } from "expo-status-bar";
import { initialWindowMetrics, SafeAreaProvider } from "react-native-safe-area-context";
import { linking, RootNavigator } from "./src/navigation";

export default function App() {
  return (
    <SafeAreaProvider initialMetrics={initialWindowMetrics}>
      <NavigationContainer linking={linking}>
        <RootNavigator />
      </NavigationContainer>
      <StatusBar style="auto" />
    </SafeAreaProvider>
  );
}
```

The tabs have no icons. `tabBarIcon: () => null` in `navigation.tsx` says so on purpose; the first
recording of this lesson drew a placeholder character the browser could not render, because no icon font
was installed. An app would add `@expo/vector-icons` and give each tab a picture with its label beside
it, never instead of it.
