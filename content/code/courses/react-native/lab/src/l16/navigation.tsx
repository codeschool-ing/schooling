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
