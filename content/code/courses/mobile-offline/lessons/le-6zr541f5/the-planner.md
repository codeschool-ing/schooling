---
title: The study planner, the app this course stores
version: 1
---

**The course has one example, and it is small on purpose: a study planner.** A person lists the
courses they are studying, opens one, adds sessions with a date and a length in minutes, ticks
them off when they are done, and sees how many minutes the week holds. The `frontend` track builds
the same planner as a web app, and the platform courses before the fork build it on a phone. Here
it has no screen at all. It is the data under the screens, which is the part that has to work when
the network does not.

Three courses, six sessions, all in the second half of October 2026. Save this as `data.ts` in
`~/planner`; every lesson starts from it:

```typescript
// data.ts: the planner's starting data, which every lesson of the course begins from.
export type Course = { id: string; name: string };
export type Session = { id: string; course: string; date: string; minutes: number; done: boolean };

export const courses: Course[] = [
  { id: "spanish", name: "Spanish A2" },
  { id: "statistics", name: "Statistics" },
  { id: "guitar", name: "Guitar" },
];

export const sessions: Session[] = [
  { id: "s1", course: "spanish", date: "2026-10-19", minutes: 30, done: true },
  { id: "s2", course: "statistics", date: "2026-10-20", minutes: 45, done: true },
  { id: "s3", course: "guitar", date: "2026-10-21", minutes: 20, done: false },
  { id: "s4", course: "spanish", date: "2026-10-22", minutes: 30, done: false },
  { id: "s5", course: "statistics", date: "2026-10-26", minutes: 60, done: false },
  { id: "s6", course: "guitar", date: "2026-10-28", minutes: 20, done: false },
];
```

A date is a string such as `2026-10-21`, with no time and no zone. That is deliberate: a study
session belongs to a day on the person's calendar, and a timestamp would move it to the day before
for somebody three hours west. Lesson 11 comes back to clocks, and to why the server must not trust
the phone's.

The two screens the planner draws are a list of courses and the week. Here they are printed, from
the data above. Save this as `show.ts`:

```typescript
// show.ts: the planner's two screens, printed: the courses, and one week.
import { courses, sessions } from "./data.ts";

const monday = process.argv[2] ?? "2026-10-19";
const end = new Date(`${monday}T12:00:00Z`);
end.setUTCDate(end.getUTCDate() + 7);
const sunday = end.toISOString().slice(0, 10);

for (const c of courses) {
  const mine = sessions.filter((s) => s.course === c.id);
  console.log(`${c.name.padEnd(12)} ${mine.length} sessions`);
}
const week = sessions.filter((s) => s.date >= monday && s.date < sunday);
const planned = week.reduce((n, s) => n + s.minutes, 0);
const done = week.filter((s) => s.done).reduce((n, s) => n + s.minutes, 0);
console.log(`week of ${monday}: ${planned} min planned, ${done} done`);
```

The `./data.ts` in the import keeps its extension, because Node looks for the file by the name
written there. And the week is passed in rather than read from the clock, so the program says the
same thing whenever you run it:

```
ana@dev:~/planner$ node show.ts 2026-10-19
Spanish A2   2 sessions
Statistics   2 sessions
Guitar       2 sessions
week of 2026-10-19: 125 min planned, 75 done
ana@dev:~/planner$ node show.ts 2026-10-26
Spanish A2   2 sessions
Statistics   2 sessions
Guitar       2 sessions
week of 2026-10-26: 80 min planned, 0 done
```

**Everything here lives in memory and is gone when the program ends.** That is the state an app is
in before this course: its data comes from somewhere else and nothing stays behind. Lesson 3 puts
these rows in a database on the device, and from then on the planner remembers.
