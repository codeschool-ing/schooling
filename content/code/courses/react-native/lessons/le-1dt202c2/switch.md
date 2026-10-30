---
title: The switch, and the journal entry
version: 1
---

`src/planState.tsx` records the place with the session, and the journal's query returns the places
beside the totals:

```tsx
// src/planState.tsx: the plan comes from the server through TanStack Query; every change is an action,
// and every session the server agrees is done goes into the journal on this phone.
import { onlineManager, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import NetInfo from "@react-native-community/netinfo";
import { useSQLiteContext } from "expo-sqlite";
import { createSession, fetchPlan, sendDone, type NewSession } from "./api";
import { places, record, totals } from "./journal";
import { currentPlace } from "./place";
import { addSession, markDone, type Plan } from "./planner";

export type Action =
  | { type: "done"; id: string }
  | { type: "add"; course: string; date: string; minutes: number };

export function planReducer(plan: Plan, action: Action): Plan {
  switch (action.type) {
    case "done":
      return markDone(plan, action.id);
    case "add":
      return addSession(plan, action.course, action.date, action.minutes);
  }
}

// TanStack Query pauses requests while offline; on a phone, NetInfo is what knows.
onlineManager.setEventListener((setOnline) => NetInfo.addEventListener((s) => setOnline(!!s.isConnected)));

export function usePlanQuery() {
  return useQuery({ queryKey: ["plan"], queryFn: fetchPlan, staleTime: 30_000 });
}

function useMarkDone() {
  const client = useQueryClient();
  const db = useSQLiteContext();
  return useMutation({
    mutationFn: sendDone,
    onMutate: async (id: string) => {
      await client.cancelQueries({ queryKey: ["plan"] });
      const before = client.getQueryData<Plan>(["plan"]);
      client.setQueryData<Plan>(["plan"], (p) => p && planReducer(p, { type: "done", id }));
      return { before };
    },
    onError: (_error, _id, context) => client.setQueryData(["plan"], context?.before),
    // only once the server has agreed, so the journal never logs a session that was rolled back
    onSuccess: async (session) => {
      // A phone that cannot say where it is (location off, permission taken back in Settings) still
      // logs the session, without a place: the record matters more than the coordinates.
      const where = await currentPlace().catch(() => null);
      await record(db, session, new Date().toISOString(), where);
      await client.invalidateQueries({ queryKey: ["journal"] });
    },
    onSettled: () => client.invalidateQueries({ queryKey: ["plan"] }),
  });
}

// What the journal adds up to, through the same cache as the plan, so a screen re-renders when it grows.
export function useJournal() {
  const db = useSQLiteContext();
  return useQuery({
    queryKey: ["journal"],
    queryFn: async () => ({ totals: await totals(db), places: await places(db) }),
    networkMode: "always",
  });
}

// Adding waits for the server, which gives the session its id; then the plan is fetched again.
export function useAddSession() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (s: NewSession) => createSession(s),
    onSuccess: () => client.invalidateQueries({ queryKey: ["plan"] }),
  });
}

// The screens' view of all this is the same as in lesson 9.
export function usePlan() {
  const { data } = usePlanQuery();
  const markDone = useMarkDone();
  if (!data) throw new Error("usePlan must be used once the plan has loaded");
  const dispatch = (action: Action) => {
    if (action.type === "done") markDone.mutate(action.id);
  };
  return { plan: data, dispatch, error: markDone.error };
}
```

**`.catch(() => null)` is a decision, and the comment above it says which.** Location can fail after it
was allowed: the person turned location off for the whole phone, or took the permission back in
Settings, or the phone could not get a position in time. None of that should cost them the session, so
the session is logged without a place. The journal's `NULL` says exactly that.

`src/WeekScreen.tsx` gets the switch and a second line under the totals:

```tsx
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
```

**`Switch` is React Native's own toggle**, drawn by each platform in its own style, and announced by a
screen reader as a switch with its state. `aria-label` gives it the same name the text beside it shows.
The state starts off and is read from storage after the first render; a value read synchronously, from
MMKV, would avoid that flicker, which is the case lesson 14 described.
