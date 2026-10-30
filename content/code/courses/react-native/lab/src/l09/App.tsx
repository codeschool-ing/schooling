// App.tsx: the planner's root: safe areas, the shared plan, then navigation.
import { NavigationContainer } from "@react-navigation/native";
import { StatusBar } from "expo-status-bar";
import { initialWindowMetrics, SafeAreaProvider } from "react-native-safe-area-context";
import data from "./src/courses.json";
import { linking, RootNavigator } from "./src/navigation";
import { PlanProvider } from "./src/planState";
import type { Plan } from "./src/planner";

const initial: Plan = data;

export default function App() {
  return (
    <SafeAreaProvider initialMetrics={initialWindowMetrics}>
      <PlanProvider initial={initial}>
        <NavigationContainer linking={linking}>
          <RootNavigator />
        </NavigationContainer>
      </PlanProvider>
      <StatusBar style="auto" />
    </SafeAreaProvider>
  );
}
