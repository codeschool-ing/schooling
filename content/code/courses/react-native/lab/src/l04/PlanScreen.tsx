// src/PlanScreen.tsx: the planner's first screen, built from the core components.
import { useState } from "react";
import { Image, ScrollView, Text, View } from "react-native";
import { CourseRow } from "./CourseRow";
import { mondayOf, weekTotal, type Plan } from "./planner";

type Props = { plan: Plan; today: string };

export function PlanScreen({ plan, today }: Props) {
  const [open, setOpen] = useState<string | null>(null);
  const total = weekTotal(plan, mondayOf(today));
  const course = plan.courses.find((c) => c.id === open);
  return (
    <ScrollView contentContainerStyle={{ padding: 24, paddingTop: 64 }}>
      <View style={{ flexDirection: "row", alignItems: "center", gap: 12 }}>
        <Image source={require("../assets/icon.png")} style={{ width: 40, height: 40 }} aria-hidden />
        <Text role="heading" style={{ fontSize: 24, fontWeight: "700" }}>
          Study planner
        </Text>
      </View>
      <Text style={{ marginVertical: 12 }}>
        This week: {total.done} of {total.planned} minutes done
      </Text>
      <View role="list">
        {plan.courses.map((c) => (
          <View role="listitem" key={c.id}>
            <CourseRow
              course={c}
              sessions={plan.sessions.filter((s) => s.course === c.id).length}
              onOpen={setOpen}
            />
          </View>
        ))}
      </View>
      {course && <Text role="status" style={{ marginTop: 12 }}>Open: {course.name}</Text>}
    </ScrollView>
  );
}
