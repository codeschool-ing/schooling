// src/today.ts: the date the planner treats as today, as YYYY-MM-DD.
// In a browser, ?today= in the address overrides the clock, so a lesson can pin the week.
export function today(): string {
  const pinned = typeof location === "undefined" ? null : new URLSearchParams(location.search).get("today");
  return pinned ?? new Date().toISOString().slice(0, 10);
}
