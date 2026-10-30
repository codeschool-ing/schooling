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

export const fetchPlan = () => json<Plan>("/plan");
export const sendDone = (id: string) => json<Session>(`/sessions/${id}/done`, { method: "POST" });
export const createSession = (s: NewSession) =>
  json<Session>("/sessions", { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(s) });
