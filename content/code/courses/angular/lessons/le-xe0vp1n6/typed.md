---
title: A type argument is a claim, not a check
version: 1
---

**`httpResource<PlannerData>` and `http.get<PlannerData>` tell the compiler what the answer will be,
and nothing at run time checks that it is.** The type argument is a promise you make on the server's
behalf. TypeScript believes it, every line after it is checked against it, and the JSON that arrives
is whatever the server sent. When the two disagree, nothing fails where they meet; something goes
wrong later, somewhere else.

A server that sends a number as a string is an easy mistake to make, and one edit to its working
copy makes it. `sed -i` changes the file in place, here session 5's minutes from `50` to `"50"`:

```
ana@dev:~/planner$ sed -i 's/"minutes": 50,/"minutes": "50",/' server/planner.json
```

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-week
[vite] connecting...
[vite] connected.
Angular is running in development mode.
This week

2026-10-19 to 2026-10-25

11550 minutes planned, 90 done.

11460 minutes to go.

Done this week
Courses
HTML and CSS: 30 minutes
JavaScript: 6050 minutes
Git: 25 minutes
```

**11550 minutes planned.** `totals` adds `s.minutes` to a running number: 30, 90, 115, and then
`115 + "50"`, which in JavaScript is the string `"11550"`. The compiler was told `minutes` is a
`number`, so it had no reason to object, and the page shows a wrong number with every sign of being
right. JavaScript's 6050 is `60 + "50"`, and "11460 minutes to go" is the same value used the
other way: `-` has no meaning for strings, so JavaScript turns `"11550"` back into a number to
subtract 90 from it.

## Checking at the edge

The place to find out is where the data comes in, once, so that everything inside can trust the
type. `httpResource` takes a `parse` option: a function given the raw answer, which returns the
typed value or throws. `planner.ts` loses `loadPlanner`, which nothing calls, and gains the check:

```schooling-example
{"language": "typescript", "file": "src/app/planner.ts", "parts": [
 {"code": "export interface Course {\n  id: string;\n  name: string;\n}\n\nexport interface Session {\n  id: number;\n  courseId: string;\n  date: string;\n  minutes: number;\n  done: boolean;\n}\n\nexport interface PlannerData {\n  courses: Course[];\n  sessions: Session[];\n}\nexport interface WeekRange {\n  start: string;\n  end: string;\n}\nexport function isoDay(date: Date): string {\n  const two = (n: number) => String(n).padStart(2, '0');\n  return `${date.getFullYear()}-${two(date.getMonth() + 1)}-${two(date.getDate())}`;\n}\nexport function weekOf(day: string): WeekRange {\n  const date = new Date(`${day}T12:00:00`);\n  const fromMonday = (date.getDay() + 6) % 7;\n  const monday = new Date(date);\n  monday.setDate(date.getDate() - fromMonday);\n  const sunday = new Date(monday);\n  sunday.setDate(monday.getDate() + 6);\n  return { start: isoDay(monday), end: isoDay(sunday) };\n}\nexport function inWeek(session: Session, week: WeekRange): boolean {\n  return session.date >= week.start && session.date <= week.end;\n}\nexport function totals(sessions: Session[], week: WeekRange): { planned: number; done: number } {\n  let planned = 0;\n  let done = 0;\n  for (const s of sessions) {\n    if (!inWeek(s, week)) continue;\n    planned += s.minutes;\n    if (s.done) done += s.minutes;\n  }\n  return { planned, done };\n}"},
 {"code": "export function parsePlanner(raw: unknown): PlannerData {\n  const data = raw as PlannerData;\n  if (!Array.isArray(data?.courses) || !Array.isArray(data?.sessions)) {\n    throw new Error('the answer has no courses or no sessions');\n  }", "note": "The raw answer is `unknown`: nothing is assumed about it until it has been looked at. The `as` lets the checks below be written; the checks are what make it true."},
 {"code": "  for (const s of data.sessions) {\n    if (typeof s.minutes !== 'number') throw new Error(`session ${s.id}: minutes is ${JSON.stringify(s.minutes)}`);\n    if (typeof s.done !== 'boolean') throw new Error(`session ${s.id}: done is ${JSON.stringify(s.done)}`);\n  }\n  return data;\n}", "note": "The two fields the arithmetic depends on. A thrown error puts the resource in its error state, with this message."}
]}
```

The resource is given the function, and takes its type from what the function returns, so the type
argument goes:

```typescript
// src/app/planner-store.ts
import { HttpClient, httpResource } from '@angular/common/http';
import { Injectable, computed, inject } from '@angular/core';
import { Session, isoDay, parsePlanner, totals, weekOf } from './planner';
import { TODAY } from './today';

@Injectable({
  providedIn: 'root',
})
export class PlannerStore {
  private readonly http = inject(HttpClient);
  private readonly data = httpResource(() => '/api/planner', { parse: parsePlanner });

  readonly isLoading = this.data.isLoading;
  readonly error = this.data.error;
  readonly courses = computed(() => (this.data.hasValue() ? this.data.value().courses : []));
  readonly sessions = computed(() => (this.data.hasValue() ? this.data.value().sessions : []));
  readonly week = weekOf(isoDay(inject(TODAY)));
  readonly weekTotals = computed(() => totals(this.sessions(), this.week));

  minutesThisWeek(courseId: string): number {
    return totals(this.sessions().filter((s) => s.courseId === courseId), this.week).planned;
  }

  toggle(id: number, done: boolean): void {
    this.data.update((data) =>
      data && { ...data, sessions: data.sessions.map((s) => (s.id === id ? { ...s, done } : s)) },
    );
  }
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-week
[vite] connecting...
[vite] connected.
Angular is running in development mode.
This week

2026-10-19 to 2026-10-25

The week could not be loaded: session 5: minutes is "50"
```

The page now says what is wrong, and where, instead of showing a number that is wrong. A check this size, by hand, is enough for one shape with five fields. For a real API with dozens, a library such as Zod writes the same check from a description of the shape, and gives the type from the same description so the two cannot drift apart.

The server's copy goes back to a number:

```
ana@dev:~/planner$ sed -i 's/"minutes": "50",/"minutes": 50,/' server/planner.json
```
