---
title: Both screens ask for the store
version: 1
---

**Each component replaces its own `resource` with `inject(PlannerStore)`, and reads the store's
signals where it read its own.** `Week` keeps its week and its two computed values; only where the
sessions and courses come from changes:

```typescript
// src/app/week/week.ts
import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { isoDay, totals, weekOf } from '../planner';
import { CourseCard } from '../course-card/course-card';
import { Panel } from '../panel/panel';
import { PlannerStore } from '../planner-store';
import { TODAY } from '../today';
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
  protected readonly week = weekOf(isoDay(inject(TODAY)));
  protected readonly totals = computed(() => totals(this.store.sessions(), this.week));
  protected readonly rows = computed(() =>
    this.store.courses().map((course) => ({
      course,
      minutes: totals(this.store.sessions().filter((s) => s.courseId === course.id), this.week).planned,
    })),
  );
}
```

The template asks the store whether it is still loading, or failed:

```html
<!-- src/app/week/week.html -->
<app-panel>
  <h2>This week</h2>
  <p>{{ week.start }} to {{ week.end }}</p>
  @if (store.isLoading()) {
    <p>Loading the week…</p>
  } @else if (store.error(); as error) {
    <p>The week could not be loaded: {{ error.message }}</p>
  } @else {
    <app-week-summary [planned]="totals().planned" [done]="totals().done" />
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

`CoursePage` loses its `toggle` method as well as its resource, and its template calls the store's:

```typescript
// src/app/course-page/course-page.ts
import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { PlannerStore } from '../planner-store';
import { SessionList } from '../session-list/session-list';

@Component({
  selector: 'app-course-page',
  imports: [SessionList],
  templateUrl: './course-page.html',
  styleUrl: './course-page.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CoursePage {
  readonly courseId = input.required<string>();
  protected readonly store = inject(PlannerStore);
  protected readonly course = computed(() => this.store.courses().find((c) => c.id === this.courseId()));
  protected readonly sessions = computed(() =>
    this.store
      .sessions()
      .filter((s) => s.courseId === this.courseId())
      .sort((a, b) => a.date.localeCompare(b.date)),
  );
}
```

```html
<!-- src/app/course-page/course-page.html -->
@if (store.isLoading()) {
  <p>Loading the course…</p>
} @else if (store.error(); as error) {
  <p>The course could not be loaded: {{ error.message }}</p>
} @else if (course(); as course) {
  <h2>{{ course.name }}</h2>
  <app-session-list [sessions]="sessions()" (toggled)="store.toggle($event.id, $event.done)" />
} @else {
  <p>There is no course called {{ courseId() }}.</p>
}
```

The same tick as before:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-week-summary --network --do 'check 2026-10-24, 50 minutes'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /courses.json  200
net  GET /courses.json  200
-- check 2026-10-24, 50 minutes
165 minutes planned, 90 done.

75 minutes to go.

Done this week
```

**One request, and 140 minutes done.** The tick went to the store; the store's `sessions` changed;
`Week`'s `totals` reads `sessions`, so it was marked stale, and the summary was drawn again. Neither
component knows the other exists. They agree because they read the same signal, which is the only
kind of agreement that cannot drift.

`store` is `protected` rather than `private` because the templates read it. That puts the whole
store in reach of the template, `toggle` included, which is the convenient choice and a common one.
The stricter one is to keep the store `private` and give the template only computed values and
methods of the component's own; the next section is about the store's side of the same question.
