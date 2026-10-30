---
title: What belongs in the store, and what stays in the component
version: 1
---

**A fact about the planner belongs in the store; a decision about one screen stays in its
component.** The week's totals are a fact: how many minutes are planned this week is the same
answer whichever screen asks, and lesson 17's course page will want the week's minutes for one
course too. The shape of the rows in the week's list, a course beside a number, is for that one
screen. So the week and its totals move, and the rows stay.

```schooling-example
{"language": "typescript", "file": "src/app/planner-store.ts", "parts": [
 {"code": "import { Injectable, computed, inject, resource } from '@angular/core';\nimport { isoDay, loadPlanner, totals, weekOf } from './planner';\nimport { TODAY } from './today';\n\n@Injectable({\n  providedIn: 'root',\n})\nexport class PlannerStore {\n  private readonly data = resource({ loader: loadPlanner });\n\n  readonly isLoading = this.data.isLoading;\n  readonly error = this.data.error;\n  readonly courses = computed(() => (this.data.hasValue() ? this.data.value().courses : []));\n  readonly sessions = computed(() => (this.data.hasValue() ? this.data.value().sessions : []));", "note": "A service can inject like anything else. The store asks for `TODAY`, which is lesson 10's token doing what it was made for."},
 {"code": "  readonly week = weekOf(isoDay(inject(TODAY)));\n  readonly weekTotals = computed(() => totals(this.sessions(), this.week));", "note": "The week, worked out once for the whole application, and its totals as a computed beside the lists."},
 {"code": "  minutesThisWeek(courseId: string): number {\n    return totals(this.sessions().filter((s) => s.courseId === courseId), this.week).planned;\n  }\n\n  toggle(id: number, done: boolean): void {\n    this.data.update((data) =>\n      data && { ...data, sessions: data.sessions.map((s) => (s.id === id ? { ...s, done } : s)) },\n    );\n  }\n}", "note": "A method that reads signals is as reactive as the signals: called inside a `computed` or a template, it is tracked like a read of `sessions()` would be."}
]}
```

`Week` is left with what is its own, the rows:

```typescript
// src/app/week/week.ts
import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { CourseCard } from '../course-card/course-card';
import { Panel } from '../panel/panel';
import { PlannerStore } from '../planner-store';
import { WeekSummary } from '../week-summary/week-summary';

@Component({
  selector: 'app-week',
  imports: [CourseCard, Panel, WeekSummary],
  templateUrl: './week.html',
  styleUrl: './week.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Week {
  protected readonly store = inject(PlannerStore);
  protected readonly rows = computed(() =>
    this.store.courses().map((course) => ({ course, minutes: this.store.minutesThisWeek(course.id) })),
  );
}
```

```html
<!-- src/app/week/week.html -->
<app-panel>
  <h2>This week</h2>
  <p>{{ store.week.start }} to {{ store.week.end }}</p>
  @if (store.isLoading()) {
    <p>Loading the week…</p>
  } @else if (store.error(); as error) {
    <p>The week could not be loaded: {{ error.message }}</p>
  } @else {
    <app-week-summary [planned]="store.weekTotals().planned" [done]="store.weekTotals().done" />
    <h3>Courses</h3>
    <ul>
      @for (row of rows(); track row.course.id) {
        <li><app-course-card [course]="row.course" [minutes]="row.minutes" /></li>
      } @empty {
        <li>No courses yet.</li>
      }
    </ul>
  }
</app-panel>
```

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-week
[vite] connecting...
[vite] connected.
Angular is running in development mode.
This week

2026-10-19 to 2026-10-25

165 minutes planned, 90 done.

75 minutes to go.

Done this week
Courses
HTML and CSS: 30 minutes
JavaScript: 110 minutes
Git: 25 minutes
```

The page is what it was. The test from lesson 10 is worth running, because `Week` no longer asks
for `TODAY` at all, and the test still provides it:

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E 'FAIL|Error|Tests '
      Tests  5 passed (5)
```

Five tests, the store's generated one among them, and the week test still passes. `TestBed` made
the store in its own root injector, the store asked that injector for `TODAY`, and the test's
`useValue` answered. The test did not have to know that the question had moved from the component
to the store, which is the same property that let the two components stop knowing about each other:
whoever asks, the injector answers.
