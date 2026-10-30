---
title: While the app is open, and after a tap
version: 1
---

**A notification that arrives while its app is on screen is not shown, unless the app says so.** The
person is already looking at the app, so by default the system stays quiet. `setNotificationHandler`
decides, for each notification, whether to show a banner, keep it in the list, play a sound and set the
badge. The planner shows reminders quietly; it is set once, at the top of `App.tsx`:

```tsx
// App.tsx: the planner's root: gestures, safe areas, the query client and its stored copy, the journal's
// database, and the plan once it has arrived.
import { NavigationContainer } from "@react-navigation/native";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { createAsyncStoragePersister } from "@tanstack/query-async-storage-persister";
import { QueryClient } from "@tanstack/react-query";
import { PersistQueryClientProvider } from "@tanstack/react-query-persist-client";
import * as Notifications from "expo-notifications";
import { SQLiteProvider } from "expo-sqlite";
import { StatusBar } from "expo-status-bar";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { Pressable, Text, View } from "react-native";
import { initialWindowMetrics, SafeAreaProvider } from "react-native-safe-area-context";
import { migrate } from "./src/journal";
import { linking, RootNavigator } from "./src/navigation";
import { usePlanQuery } from "./src/planState";

// A reminder that arrives while the planner is open is still shown, as a banner, without a sound.
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowBanner: true,
    shouldShowList: true,
    shouldPlaySound: false,
    shouldSetBadge: false,
  }),
});

const DAY = 24 * 60 * 60 * 1000;
// A cached plan is kept for a day, in memory and in storage, so the app opens with it even offline.
const client = new QueryClient({ defaultOptions: { queries: { gcTime: DAY } } });
const persister = createAsyncStoragePersister({ storage: AsyncStorage, key: "planner-cache" });
const persistOptions = {
  persister,
  maxAge: DAY,
  buster: "1", // change it when the plan's shape changes, and every stored copy is thrown away
  dehydrateOptions: { shouldDehydrateQuery: (q: { queryKey: readonly unknown[] }) => q.queryKey[0] === "plan" },
};

function Loaded() {
  const { data, error, refetch, isFetching } = usePlanQuery();
  if (data) {
    return (
      <NavigationContainer linking={linking}>
        <RootNavigator />
      </NavigationContainer>
    );
  }
  return (
    <View style={{ flex: 1, justifyContent: "center", padding: 24, gap: 12 }}>
      <Text role="status">{error ? `The plan could not be loaded: ${error.message}` : "Loading the plan"}</Text>
      {error && !isFetching && (
        <Pressable role="button" onPress={() => refetch()}>
          <Text>Try again</Text>
        </Pressable>
      )}
    </View>
  );
}

export default function App() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider initialMetrics={initialWindowMetrics}>
        <PersistQueryClientProvider client={client} persistOptions={persistOptions}>
          <SQLiteProvider databaseName="planner.db" onInit={migrate}>
            <Loaded />
          </SQLiteProvider>
        </PersistQueryClientProvider>
        <StatusBar style="auto" />
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
```

## A tap opens the course

**Tapping a notification starts the app, or brings it forward, and hands it a *response*** carrying the
notification's `data`. The planner's reminders carry an address, and lesson 8 already taught React
Navigation to open addresses: the same `linking` object has two optional functions for addresses that come
from somewhere other than a link. In `src/navigation.tsx`:

```tsx
// src/navigation.tsx: the planner's screens, how they nest, and the addresses that reach them, from a link
// or from a tapped notification.
import { createBottomTabNavigator } from "@react-navigation/bottom-tabs";
import type { LinkingOptions, NavigatorScreenParams } from "@react-navigation/native";
import { createNativeStackNavigator } from "@react-navigation/native-stack";
import * as Notifications from "expo-notifications";
import { Linking } from "react-native";
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

const urlOf = (r: Notifications.NotificationResponse | null) => {
  const url = r?.notification.request.content.data?.url;
  return typeof url === "string" ? url : null;
};

// Addresses come from two places: a link opened from outside, and a notification the person tapped.
export const linking: LinkingOptions<RootParams> = {
  prefixes: ["planner://"],
  async getInitialURL() {
    return (await Linking.getInitialURL()) ?? urlOf(await Notifications.getLastNotificationResponseAsync());
  },
  subscribe(listener) {
    const links = Linking.addEventListener("url", ({ url }) => listener(url));
    const taps = Notifications.addNotificationResponseReceivedListener((r) => {
      const url = urlOf(r);
      if (url) listener(url);
    });
    return () => {
      links.remove();
      taps.remove();
    };
  },
  config: {
    screens: {
      Tabs: { screens: { Courses: "", Week: "week" } },
      Course: "course/:id",
      AddSession: "course/:course/add",
    },
  },
};
```

- **`getInitialURL` is asked once, at start.** A link that opened the app wins; otherwise, the
  notification that was tapped to open it, if there was one. That is the case of a closed app.
- **`subscribe` is for an app already running.** React Navigation passes a `listener`; every address handed
  to it is navigated to. Links and taps both go to the same listener, and the function returned removes
  both subscriptions when the container goes away.

**So a reminder and a link are one path**, and everything lesson 8 checked about `course/:id` holds for a
tap too. *What happens on a phone, with the app closed and a real tap, was not run for this course; the
next section checks the tap by calling the listener itself.*
