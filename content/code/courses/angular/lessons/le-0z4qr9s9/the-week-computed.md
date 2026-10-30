---
title: The week, computed from the data
version: 1
---

**The planner's numbers stop being typed in: they are computed from the six sessions and today's
date, by plain functions, read through `computed`.** The rule for what goes where is the one this
lesson has been building: the data arrives in a `resource`, everything worked out from it is a
`computed`, and the arithmetic itself is ordinary TypeScript that knows nothing about Angular.

## The arithmetic, on its own

The week runs Monday to Sunday and contains today. Four functions, added to `planner.ts` under the
interfaces, and the loader, which moves there from the component:

```schooling-example
{"language": "typescript", "file": "src/app/planner.ts", "parts": [
 {"code": "export interface Course {\n  id: string;\n  name: string;\n}\n\nexport interface Session {\n  id: number;\n  courseId: string;\n  date: string;\n  minutes: number;\n  done: boolean;\n}\n\nexport interface PlannerData {\n  courses: Course[];\n  sessions: Session[];\n}", "note": "The shapes from before, unchanged."},
 {"code": "export async function loadPlanner(): Promise<PlannerData> {\n  const response = await fetch('/courses.json');\n  if (!response.ok) throw new Error(`${response.url} answered ${response.status}`);\n  return response.json();\n}", "note": "The loader from the previous section, moved here so the two components that need the data share it."},
 {"code": "export interface WeekRange {\n  start: string;\n  end: string;\n}", "note": "A week, as its first and last day. Not called `Week`: that is the component's name."},
 {"code": "export function isoDay(date: Date): string {\n  const two = (n: number) => String(n).padStart(2, '0');\n  return `${date.getFullYear()}-${two(date.getMonth() + 1)}-${two(date.getDate())}`;\n}", "note": "A `Date` as `YYYY-MM-DD`, in the computer's own time zone. `toISOString()` would answer in UTC, and in São Paulo at 22:00 that is already tomorrow."},
 {"code": "export function weekOf(day: string): WeekRange {\n  const date = new Date(`${day}T12:00:00`);\n  const fromMonday = (date.getDay() + 6) % 7;\n  const monday = new Date(date);\n  monday.setDate(date.getDate() - fromMonday);\n  const sunday = new Date(monday);\n  sunday.setDate(monday.getDate() + 6);\n  return { start: isoDay(monday), end: isoDay(sunday) };\n}", "note": "`getDay()` counts from Sunday as 0. Shifting by six and taking the remainder makes Monday 0, so `fromMonday` is how many days to step back. Noon keeps a change of daylight saving time from moving the date."},
 {"code": "export function inWeek(session: Session, week: WeekRange): boolean {\n  return session.date >= week.start && session.date <= week.end;\n}", "note": "Dates written `YYYY-MM-DD` compare correctly as text, which lesson 2 chose them for."},
 {"code": "export function totals(sessions: Session[], week: WeekRange): { planned: number; done: number } {\n  let planned = 0;\n  let done = 0;\n  for (const s of sessions) {\n    if (!inWeek(s, week)) continue;\n    planned += s.minutes;\n    if (s.done) done += s.minutes;\n  }\n  return { planned, done };\n}", "note": "Minutes planned and done in a week. Every session in the week counts as planned; the done ones count twice, once in each total."}
]}
```

Nothing in it imports Angular, so lesson 24 can test it in a few lines, and the other three framework
courses could use it as it is. `resource({ loader: loadPlanner })` is now all a component needs to
write.

## The summary, from the data

```typescript
// src/app/week-summary/week-summary.ts
import { Component, computed, resource } from '@angular/core';
import { isoDay, loadPlanner, totals, weekOf } from '../planner';

@Component({
  selector: 'app-week-summary',
  imports: [],
  templateUrl: './week-summary.html',
  styleUrl: './week-summary.css',
})
export class WeekSummary {
  protected readonly data = resource({ loader: loadPlanner });
  private readonly week = weekOf(isoDay(new Date()));
  protected readonly totals = computed(() => totals(this.data.value()?.sessions ?? [], this.week));
}
```

```html
<!-- src/app/week-summary/week-summary.html -->
@if (data.isLoading()) {
  <p>Loading the week…</p>
} @else if (data.error(); as error) {
  <p>The week could not be loaded: {{ error.message }}</p>
} @else {
  @let t = totals();
  @let left = t.planned - t.done;
  <p>{{ t.planned }} minutes planned, {{ t.done }} done.</p>
  @if (t.planned === 0) {
    <p>Nothing planned this week.</p>
  } @else if (left <= 0) {
    <p>Everything planned is done.</p>
  } @else {
    <p>{{ left }} minutes to go.</p>
  }
  <label for="week-progress">Done this week</label>
  <progress id="week-progress" [value]="t.done" [max]="t.planned"></progress>
}
```

`week` is a plain field: today does not change while the page is open, at least not in a way this
planner cares about, so it needs no signal. Lesson 10 replaces `new Date()` with something a test can
set.

## The courses, with their minutes

The week screen lists each course with its own minutes this week. It reads the same file:

```typescript
// src/app/week/week.ts
import { Component, computed, resource } from '@angular/core';
import { isoDay, loadPlanner, totals, weekOf } from '../planner';
import { WeekSummary } from '../week-summary/week-summary';

@Component({
  selector: 'app-week',
  imports: [WeekSummary],
  templateUrl: './week.html',
  styleUrl: './week.css',
})
export class Week {
  protected readonly data = resource({ loader: loadPlanner });
  private readonly week = weekOf(isoDay(new Date()));
  protected readonly rows = computed(() => {
    const data = this.data.value();
    if (!data) return [];
    return data.courses.map((course) => ({
      course,
      minutes: totals(data.sessions.filter((s) => s.courseId === course.id), this.week).planned,
    }));
  });
}
```

```html
<!-- src/app/week/week.html -->
<h2>This week</h2>
<app-week-summary />
<h3>Courses</h3>
@if (data.hasValue()) {
  <ul>
    @for (row of rows(); track row.course.id) {
      <li>{{ row.course.name }}: {{ row.minutes }} minutes</li>
    } @empty {
      <li>No courses yet.</li>
    }
  </ul>
}
```

Ask for the page with today set to Friday 23 October, the date lesson 1 worked the numbers out for:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Study planner
This week

165 minutes planned, 90 done.

75 minutes to go.

Done this week
Courses
HTML and CSS: 30 minutes
JavaScript: 110 minutes
Git: 25 minutes
```

165 and 90, as worked out by hand in lesson 1, now worked out by the program, and 75 to go. JavaScript
has 110 minutes this week, the 60 on Tuesday and the 50 on Saturday. Move today to the next week, and
every number follows:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-28
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Study planner
This week

40 minutes planned, 0 done.

40 minutes to go.

Done this week
Courses
HTML and CSS: 40 minutes
JavaScript: 0 minutes
Git: 0 minutes
```

## The price of two resources

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --network
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /courses.json  200
net  GET /courses.json  200
Study planner
This week

165 minutes planned, 90 done.

75 minutes to go.

Done this week
Courses
HTML and CSS: 30 minutes
JavaScript: 110 minutes
Git: 25 minutes
```

Two requests for `/courses.json`: `Week` and `WeekSummary` each loaded it. They also each computed
the week. That is two copies of the same data in one page, which is wasteful now and wrong the day one
of them changes and the other does not. **Lesson 8 removes the second copy**: the week will hand its
numbers down to the summary, through an input. Lesson 11 then moves the data out of both components
into one service.

Delete the `try/` folder, run the tests, and commit:

```
ana@dev:~/planner$ rm -r try
```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep Tests
      Tests  4 passed (4)
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "Signals: the week computed from the data"
```
