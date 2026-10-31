// src/api.ts: the requests the planner makes, and nothing about screens.
import type { Plan, Session } from "./planner";

const BASE = process.env.EXPO_PUBLIC_API_URL ?? "http://localhost:8008";

async function json<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(BASE + path, init);
  if (!res.ok) {
    const body = await res.json().catch(() => null); // a refusal may explain itself
    throw new Error(body?.error ?? `${init?.method ?? "GET"} ${path} answered ${res.status}`);
  }
  return (await res.json()) as T;
}

export type NewSession = { course: string; date: string; minutes: number };

// The server is another program, deployed on its own schedule: what it sends is checked, not trusted.
function isPlan(x: unknown): x is Plan {
  const p = x as Plan | null;
  return typeof p === "object" && p !== null && Array.isArray(p.courses) && Array.isArray(p.sessions);
}

export async function fetchPlan(): Promise<Plan> {
  const plan = await json<unknown>("/plan");
  if (!isPlan(plan)) throw new Error("the server sent a plan this version of the planner cannot read");
  return plan;
}

export const sendDone = (id: string) => json<Session>(`/sessions/${id}/done`, { method: "POST" });
export const createSession = (s: NewSession) =>
  json<Session>("/sessions", { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(s) });
