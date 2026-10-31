// src/WeekScreen.tsx: every session of this week, whatever its course; any can be marked done. Above
// them, what this phone has logged, where, and the switch that decides whether it notes where.
import { useEffect, useState } from "react";
import { StyleSheet, Switch, Text, View } from "react-native";
import { notingPlace, setNotingPlace } from "./place";
import { useJournal, usePlan } from "./planState";
import { mondayOf } from "./planner";
import { SessionList } from "./SessionList";
import { useTheme } from "./theme";
import { today } from "./today";

export function WeekScreen() {
  const { plan, dispatch } = usePlan();
  const t = useTheme();
  const monday = mondayOf(today());
  const week = plan.sessions.filter((s) => mondayOf(s.date) === monday);
  return (
    <View style={[styles.screen, { backgroundColor: t.background }]}>
      <NotePlace />
      <Logged />
      <SessionList sessions={week} onDone={(id) => dispatch({ type: "done", id })} />
    </View>
  );
}

// What this phone has logged, from the journal: it survives a restart, and it is this phone's alone.
function Logged() {
  const { plan } = usePlan();
  const t = useTheme();
  const { data } = useJournal();
  if (!data) return null;
  const name = (id: string) => plan.courses.find((c) => c.id === id)?.name ?? id;
  const text = data.totals.length
    ? "Logged on this phone: " + data.totals.map((r) => `${name(r.course)} ${r.minutes} min`).join(", ")
    : "Nothing logged on this phone yet";
  const where = data.places.map((p) => `${p.lat}, ${p.lng} (${p.sessions})`).join("; ");
  return (
    <View>
      <Text style={[styles.logged, { color: t.muted }]}>{text}</Text>
      {where !== "" && <Text style={[styles.logged, { color: t.muted }]}>Studied at {where}</Text>}
    </View>
  );
}

// The switch asks for location the moment it is turned on, and stays off if the answer is no.
function NotePlace() {
  const t = useTheme();
  const [on, setOn] = useState(false);
  const [refused, setRefused] = useState(false);
  useEffect(() => {
    notingPlace().then(setOn);
  }, []);
  async function change(want: boolean) {
    const result = await setNotingPlace(want);
    setOn(result === "on");
    setRefused(result === "refused");
  }
  return (
    <View style={styles.note}>
      <View style={styles.row}>
        <Text style={[styles.label, { color: t.text }]}>Note where I study</Text>
        <Switch value={on} onValueChange={change} aria-label="Note where I study" />
      </View>
      {refused && (
        <Text role="alert" style={{ color: t.text }}>
          Without your location, sessions are logged without a place. You can allow it in Settings.
        </Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, paddingHorizontal: 24 },
  logged: { marginTop: 8, fontSize: 15 },
  note: { marginTop: 16, gap: 4 },
  row: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  label: { fontSize: 16 },
});
