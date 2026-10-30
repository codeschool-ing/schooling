---
title: The study planner, as a program with no screen
version: 1
---

**Every lesson in this course works on the same small app: a study planner.** A student lists the
courses they are taking, opens one, adds study sessions with a date and a length in minutes, marks
them done, and sees how much of the week's plan they have finished. It is the same app the
`frontend` track builds in a browser, and the courses after the fork build it again for Android, for
iOS and in React Native, with the same screens and the same data.

Here it has **no screen at all**, and that is the point. The planner's data, and the sums every
screen will show, are plain TypeScript that runs anywhere. The later lessons wrap this core in
whatever a phone does to an app: a lifecycle that kills it (lesson 4), a back stack (lesson 10), a
network that drops (lesson 14), a database on the device (lesson 16). The screens are what changes
between platforms, so they stay with the courses after the fork.

## The project

Make a folder for it, and a `package.json` that says its files are modern JavaScript modules:

```
ana@dev:~$ mkdir planner
ana@dev:~$ cd planner
```

Save this as `package.json` in `~/planner`. `"type": "module"` is what lets one file `import` from
another; without it, Node.js would read them as the older CommonJS kind, which lesson 9 of
`javascript` compares. Save it as `package.json`:

```json
{
  "name": "planner",
  "private": true,
  "type": "module"
}
```

## The core

The planner's data is two lists, courses and sessions, and four functions work on it. Save it as
`planner.ts`:

```schooling-example
{"language": "typescript", "file": "planner.ts", "parts": [{"code": "// planner.ts: the study planner's data, and the sums every screen needs\nexport type Course = { id: string; title: string };\nexport type Session = {\n  id: string;\n  courseId: string;\n  date: string; // YYYY-MM-DD, the day it is planned for\n  minutes: number;\n  done: boolean;\n};\nexport type Plan = { courses: Course[]; sessions: Session[] };\n", "note": "The data. A session points at its course by the course's `id`, never by its title, so renaming a course loses nothing. The types are what `node` strips before running the file."}, {"code": "// The Monday of the week a date falls in, as YYYY-MM-DD.\nexport function mondayOf(date: string): string {\n  const d = new Date(date + \"T12:00:00Z\");\n  const back = (d.getUTCDay() + 6) % 7; // Monday 0 ... Sunday 6\n  d.setUTCDate(d.getUTCDate() - back);\n  return d.toISOString().slice(0, 10);\n}\n", "note": "A week starts on Monday here. The date is read at noon UTC, so no time zone can move it to the day before; `getUTCDay` counts from Sunday, and the `+ 6` makes Monday zero."}, {"code": "export function addSession(plan: Plan, s: Session): Plan {\n  if (!plan.courses.some((c) => c.id === s.courseId)) {\n    throw new Error(`no course ${s.courseId}`);\n  }\n  return { ...plan, sessions: [...plan.sessions, s] };\n}\n", "note": "A session for a course that does not exist is refused, loudly, rather than added and lost later. The plan that comes back is a new object; the old one is untouched."}, {"code": "export function markDone(plan: Plan, id: string): Plan {\n  return {\n    ...plan,\n    sessions: plan.sessions.map((s) => (s.id === id ? { ...s, done: true } : s)),\n  };\n}\n", "note": "Done is set and never unset, the same way a finished step stays finished."}, {"code": "// Minutes planned and minutes done in the week that contains `today`.\nexport function weekTotal(plan: Plan, today: string) {\n  const monday = mondayOf(today);\n  const week = plan.sessions.filter((s) => mondayOf(s.date) === monday);\n  const planned = week.reduce((sum, s) => sum + s.minutes, 0);\n  const done = week.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0);\n  return { monday, planned, done };\n}", "note": "The one sum every screen shows. `today` is an argument, not the clock, so the same plan always gives the same answer and a test can pin it."}]}
```

**Nothing in it changes a plan in place**: `addSession` and `markDone` return a new one. That costs
a copy of a short list and buys something every later lesson leans on. A plan is a value you can
save, compare and restore whole, and lesson 5 does exactly that when the system takes the app away.

## Running it

A second file builds a plan for the week of Monday 19 October 2026, changes it three times and prints
the week's total. **It is given "today" rather than reading the clock**, so it prints the same
thing whenever you run it, which is what lets your output match the one below. Save it as
`week.ts`:

```typescript
// week.ts: a plan, three changes to it, and the week's total
import { addSession, markDone, weekTotal, type Plan } from "./planner.ts";

let plan: Plan = {
  courses: [
    { id: "sql", title: "SQL Databases" },
    { id: "mobile", title: "Mobile Fundamentals" },
  ],
  sessions: [
    { id: "s1", courseId: "sql", date: "2026-10-19", minutes: 50, done: true },
    { id: "s2", courseId: "mobile", date: "2026-10-20", minutes: 40, done: true },
    { id: "s3", courseId: "sql", date: "2026-10-23", minutes: 60, done: false },
    { id: "s4", courseId: "mobile", date: "2026-10-27", minutes: 45, done: false },
  ],
};

plan = addSession(plan, { id: "s5", courseId: "mobile", date: "2026-10-22", minutes: 30, done: false });
plan = markDone(plan, "s5");
console.log(weekTotal(plan, "2026-10-21"));
```

Run it with `node`, which strips the types and runs the rest:

```
ana@dev:~/planner$ ls
package.json
planner.ts
week.ts
ana@dev:~/planner$ node week.ts
{ monday: '2026-10-19', planned: 180, done: 120 }
```

Read the numbers back against the data. Five sessions exist, and `s4` is on 27 October, the Monday
after, so it is left out. The other four add up to 50 + 40 + 60 + 30 = **180 minutes planned**, and
`s1`, `s2` and `s5` are done, 50 + 40 + 30 = **120 minutes done**. Every screen of the planner, on
every platform the track reaches, shows those two numbers for that week.

Last, make the folder a repository and keep this state, so that each lesson's additions are a commit
you can look back at:

```
ana@dev:~/planner$ git init -q
ana@dev:~/planner$ git add .
ana@dev:~/planner$ git commit -q -m "The planner core, as lesson 1 gives it"
ana@dev:~/planner$ git log --oneline
87ae50d The planner core, as lesson 1 gives it
```
