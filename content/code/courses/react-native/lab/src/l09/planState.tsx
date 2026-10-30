// src/planState.tsx: the plan as state, changed only by actions, shared by every screen.
import { createContext, useContext, useReducer, type Dispatch, type ReactNode } from "react";
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

const PlanContext = createContext<{ plan: Plan; dispatch: Dispatch<Action> } | null>(null);

export function PlanProvider({ initial, children }: { initial: Plan; children: ReactNode }) {
  const [plan, dispatch] = useReducer(planReducer, initial);
  return <PlanContext.Provider value={{ plan, dispatch }}>{children}</PlanContext.Provider>;
}

export function usePlan() {
  const value = useContext(PlanContext);
  if (!value) throw new Error("usePlan must be used inside a PlanProvider");
  return value;
}
