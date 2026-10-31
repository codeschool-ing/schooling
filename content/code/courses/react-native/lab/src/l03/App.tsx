// App.tsx: the planner's first screen, before lesson 4 gives it components of its own.
import { StatusBar } from "expo-status-bar";
import { Text, View } from "react-native";
import data from "./src/courses.json";
import { mondayOf, weekTotal, type Plan } from "./src/planner";
import { today } from "./src/today";

const plan: Plan = data;

export default function App() {
  const total = weekTotal(plan, mondayOf(today()));
  return (
    <View style={{ flex: 1, padding: 24, paddingTop: 64 }}>
      <Text role="heading">Study planner</Text>
      <Text>
        This week: {total.done} of {total.planned} minutes done
      </Text>
      {plan.courses.map((c) => (
        <Text key={c.id}>{c.name}</Text>
      ))}
      <StatusBar style="auto" />
    </View>
  );
}
