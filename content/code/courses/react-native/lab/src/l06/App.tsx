// App.tsx: the planner's root, inside the provider that measures the safe areas.
import { StatusBar } from "expo-status-bar";
import { initialWindowMetrics, SafeAreaProvider } from "react-native-safe-area-context";
import data from "./src/courses.json";
import { PlanScreen } from "./src/PlanScreen";
import type { Plan } from "./src/planner";
import { today } from "./src/today";

const plan: Plan = data;

export default function App() {
  return (
    <SafeAreaProvider initialMetrics={initialWindowMetrics}>
      <PlanScreen plan={plan} today={today()} />
      <StatusBar style="auto" />
    </SafeAreaProvider>
  );
}
