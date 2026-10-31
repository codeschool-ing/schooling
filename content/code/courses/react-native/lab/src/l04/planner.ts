// src/planner.ts: the study planner's rules, with no screen in them.
export type Course = { id: string; name: string };
export type Session = { id: string; course: string; date: string; minutes: number; done: boolean };
export type Plan = { courses: Course[]; sessions: Session[] };

export function addSession(plan: Plan, course: string, date: string, minutes: number): Plan {
  if (!plan.courses.some((c) => c.id === course)) throw new Error(`no course ${course}`);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) throw new Error(`not a date: ${date}`);
  if (!Number.isInteger(minutes) || minutes <= 0) throw new Error(`not a duration: ${minutes}`);
  const id = `s${plan.sessions.length + 1}`;
  return { ...plan, sessions: [...plan.sessions, { id, course, date, minutes, done: false }] };
}

export function markDone(plan: Plan, id: string): Plan {
  return { ...plan, sessions: plan.sessions.map((s) => (s.id === id ? { ...s, done: true } : s)) };
}

// The Monday of the week a date falls in, as YYYY-MM-DD.
export function mondayOf(date: string): string {
  const d = new Date(`${date}T12:00:00Z`);
  d.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 6) % 7));
  return d.toISOString().slice(0, 10);
}

// Minutes planned in the week that starts on `monday`, and how many are done.
export function weekTotal(plan: Plan, monday: string): { planned: number; done: number } {
  const end = new Date(`${monday}T12:00:00Z`);
  end.setUTCDate(end.getUTCDate() + 7);
  const last = end.toISOString().slice(0, 10);
  const week = plan.sessions.filter((s) => s.date >= monday && s.date < last);
  return {
    planned: week.reduce((n, s) => n + s.minutes, 0),
    done: week.filter((s) => s.done).reduce((n, s) => n + s.minutes, 0),
  };
}
