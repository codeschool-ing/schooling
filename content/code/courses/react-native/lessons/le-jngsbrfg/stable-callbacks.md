---
title: Callbacks that stay the same
version: 1
---

**The planner's screens pass exactly the kind of callback that defeats `memo`**: `onDone={(id) =>
dispatch({ type: "done", id })}`, a new function on every render. `useCallback` returns the same function
until one of its dependencies changes, and it is needed at two levels.

First `dispatch` itself, which `usePlan` made fresh each time. In `src/planState.tsx`:

```tsx
// src/planState.tsx: the plan comes from the server through TanStack Query; every change is an action,
// and every session the server agrees is done goes into the journal on this phone.
import { onlineManager, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useCallback } from "react";
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
  const { mutate } = markDone;
  // The same function on every render, so a memoised row given it does not render again (lesson 19).
  const dispatch = useCallback(
    (action: Action) => {
      if (action.type === "done") mutate(action.id);
    },
    [mutate],
  );
  if (!data) throw new Error("usePlan must be used once the plan has loaded");
  return { plan: data, dispatch, error: markDone.error };
}
```

TanStack Query's `mutate` is already the same function on every render, so a `dispatch` that depends only
on it is too. The hook calls come before the `throw`, because React requires every hook to run on every
render, in the same order.

Then the two screens, each with an `onDone` made once:

```tsx
// src/WeekScreen.tsx: every session of this week, whatever its course; any can be marked done. Above
// them, what this phone has logged, where, and the switch that decides whether it notes where.
import { useCallback, useEffect, useState } from "react";
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
  const onDone = useCallback((id: string) => dispatch({ type: "done", id }), [dispatch]);
  return (
    <View style={[styles.screen, { backgroundColor: t.background }]}>
      <NotePlace />
      <Logged />
      <SessionList sessions={week} onDone={onDone} />
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

```tsx
// src/CourseScreen.tsx: one course, its sessions, the way to add one, and a photo of its notes.
import type { NativeStackScreenProps } from "@react-navigation/native-stack";
import { useCallback, useLayoutEffect } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import type { RootParams } from "./navigation";
import { NotesPhoto } from "./NotesPhoto";
import { usePlan } from "./planState";
import { SessionList } from "./SessionList";
import { useTheme } from "./theme";

export function CourseScreen({ route, navigation }: NativeStackScreenProps<RootParams, "Course">) {
  const { plan, dispatch } = usePlan();
  const t = useTheme();
  const course = plan.courses.find((c) => c.id === route.params.id);
  useLayoutEffect(() => {
    navigation.setOptions({ title: course?.name ?? "Not found" });
  }, [navigation, course]);
  const onDone = useCallback((id: string) => dispatch({ type: "done", id }), [dispatch]);
  if (!course) {
    return (
      <View style={[styles.screen, { backgroundColor: t.background }]}>
        <Text style={[styles.missing, { color: t.text }]}>There is no course called {route.params.id}.</Text>
      </View>
    );
  }
  return (
    <View style={[styles.screen, { backgroundColor: t.background }]}>
      <Pressable role="button" onPress={() => navigation.navigate("AddSession", { course: course.id })} style={styles.add}>
        <Text style={[styles.addText, { color: t.accent }]}>Add a session</Text>
      </Pressable>
      <NotesPhoto course={course.id} />
      <SessionList
        sessions={plan.sessions.filter((s) => s.course === course.id)}
        onDone={onDone}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, paddingHorizontal: 24 },
  missing: { marginTop: 24, fontSize: 17 },
  add: { paddingVertical: 12 },
  addText: { fontSize: 16, fontWeight: "600" },
});
```

In `CourseScreen` the `useCallback` sits above the early return for a missing course, for the same reason.

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npx jest --forceExit 2>&1 | tail -5
Tests:       64 passed, 64 total
Snapshots:   0 total
Time:        9.58 s, estimated 10 s
Ran all test suites.
Force exiting Jest: Have you considered using `--detectOpenHandles` to detect async operations that kept running after all tests finished?
```

**Don't memoise everything.** `memo` costs a comparison on every render, `useCallback` costs a dependency
check and a little memory, and both make code harder to read. They pay for themselves where something is
rendered many times, a row in a list, and where the props really do stay the same. A count like the last
section's is how you know which case you are in.

## The React Compiler

React 19's compiler, a Babel plugin, inserts this memoisation automatically, component by component, from
what it can prove about the code. *Expo supports it with a setting in `app.json`; this course did not turn
it on, because what it does is easier to understand by doing it once by hand.* Code written this way stays
correct with the compiler on.
