// src/SessionList.tsx: one course's sessions, grouped under the day they fall on.
import { SectionList, StyleSheet, Text } from "react-native";
import type { Session } from "./planner";
import { useTheme } from "./theme";

type Props = { sessions: Session[] };

export function groupByDate(sessions: Session[]) {
  const days = new Map<string, Session[]>();
  for (const s of [...sessions].sort((a, b) => a.date.localeCompare(b.date))) {
    days.set(s.date, [...(days.get(s.date) ?? []), s]);
  }
  return [...days].map(([date, data]) => ({ title: date, data }));
}

export function SessionList({ sessions }: Props) {
  const t = useTheme();
  return (
    <SectionList
      sections={groupByDate(sessions)}
      keyExtractor={(s) => s.id}
      renderSectionHeader={({ section }) => (
        <Text role="heading" aria-level={2} style={[styles.day, { color: t.muted }]}>
          {section.title}
        </Text>
      )}
      renderItem={({ item }) => (
        <Text style={[styles.session, { color: t.text }]}>
          {item.minutes} min{item.done ? ", done" : ""}
        </Text>
      )}
      ListEmptyComponent={<Text style={{ color: t.muted }}>No sessions yet.</Text>}
    />
  );
}

const styles = StyleSheet.create({
  day: { marginTop: 16, fontSize: 13, fontWeight: "600" },
  session: { paddingVertical: 8, fontSize: 16 },
});
