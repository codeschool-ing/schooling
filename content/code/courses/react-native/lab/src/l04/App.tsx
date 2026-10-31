// App.tsx: the planner's root, which only hands the data to the first screen.
import { StatusBar } from "expo-status-bar";
import data from "./src/courses.json";
import { PlanScreen } from "./src/PlanScreen";
import type { Plan } from "./src/planner";
import { today } from "./src/today";

const plan: Plan = data;

export default function App() {
  return (
    <>
      <PlanScreen plan={plan} today={today()} />
      <StatusBar style="auto" />
    </>
  );
}
