// src/SessionList.tsx: sessions grouped under their day, each a SessionRow.
import { SectionList, StyleSheet, Text } from "react-native";
import type { Session } from "./planner";
import { SessionRow } from "./SessionRow";
import { useTheme } from "./theme";

type Props = { sessions: Session[]; onDone?: (id: string) => void };

export function groupByDate(sessions: Session[]) {
  const days = new Map<string, Session[]>();
  for (const s of [...sessions].sort((a, b) => a.date.localeCompare(b.date))) {
    days.set(s.date, [...(days.get(s.date) ?? []), s]);
  }
  return [...days].map(([date, data]) => ({ title: date, data }));
}

export function SessionList({ sessions, onDone }: Props) {
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
      renderItem={({ item }) => <SessionRow session={item} onDone={onDone} />}
      ListEmptyComponent={<Text style={{ color: t.muted }}>No sessions yet.</Text>}
    />
  );
}

const styles = StyleSheet.create({
  day: { marginTop: 16, fontSize: 13, fontWeight: "600" },
});
