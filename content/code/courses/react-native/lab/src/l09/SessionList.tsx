// src/SessionList.tsx: sessions grouped under their day, each with a button to mark it done.
import { Pressable, SectionList, StyleSheet, Text, View } from "react-native";
import type { Session } from "./planner";
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
      renderItem={({ item }) => (
        <View style={styles.row}>
          <Text style={[styles.session, { color: t.text }]}>
            {item.minutes} min{item.done ? ", done" : ""}
          </Text>
          {onDone && !item.done && (
            <Pressable
              role="button"
              aria-label={`Mark ${item.minutes} min on ${item.date} done`}
              onPress={() => onDone(item.id)}
              hitSlop={8}
            >
              <Text style={[styles.action, { color: t.accent }]}>Mark done</Text>
            </Pressable>
          )}
        </View>
      )}
      ListEmptyComponent={<Text style={{ color: t.muted }}>No sessions yet.</Text>}
    />
  );
}

const styles = StyleSheet.create({
  day: { marginTop: 16, fontSize: 13, fontWeight: "600" },
  row: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  session: { paddingVertical: 8, fontSize: 16 },
  action: { fontSize: 16, fontWeight: "600" },
});
