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
