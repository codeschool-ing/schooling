// src/SessionRow.tsx: one session in a list, with its button to mark it done and its swipe.
import { Pressable, StyleSheet, Text, View } from "react-native";
import type { Session } from "./planner";
import { SwipeRow } from "./SwipeRow";
import { useTheme } from "./theme";

type Props = { session: Session; onDone?: (id: string) => void };

export function SessionRow({ session, onDone }: Props) {
  const t = useTheme();
  const row = (
    <View testID={`session-${session.id}`} style={styles.row}>
      <Text style={[styles.session, { color: t.text }]}>
        {session.minutes} min{session.done ? ", done" : ""}
      </Text>
      {onDone && !session.done && (
        <Pressable
          role="button"
          aria-label={`Mark ${session.minutes} min on ${session.date} done`}
          onPress={() => onDone(session.id)}
          hitSlop={8}
        >
          <Text style={[styles.action, { color: t.accent }]}>Mark done</Text>
        </Pressable>
      )}
    </View>
  );
  // only a session that can still be marked done can be swiped
  return onDone && !session.done ? <SwipeRow onDone={() => onDone(session.id)}>{row}</SwipeRow> : row;
}

const styles = StyleSheet.create({
  row: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  session: { paddingVertical: 8, fontSize: 16 },
  action: { fontSize: 16, fontWeight: "600" },
});
