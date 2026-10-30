---
title: Inputs, data passed down
version: 1
---

**An input is a property a component lets its parent set from the template, written
`[name]="expression"` where the component is used.** It is the property binding of lesson 4, aimed at
one of your own components instead of an element, and it is how data travels down the tree. Lesson 6
left the week's data loaded twice, once by `Week` and once by `WeekSummary`. With inputs, `Week` loads
it, works out the numbers, and hands them down.

## The summary takes two numbers

```typescript
// src/app/week-summary/week-summary.ts
import { ChangeDetectionStrategy, Component, input } from '@angular/core';

@Component({
  selector: 'app-week-summary',
  imports: [],
  templateUrl: './week-summary.html',
  styleUrl: './week-summary.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WeekSummary {
  readonly planned = input.required<number>();
  readonly done = input.required<number>();
}
```

`input()` returns a signal, read-only to the component, that the parent's binding sets.
**`input.required<number>()`** means a parent must provide it: write `<app-week-summary />` without
`[planned]` and the build fails, rather than drawing a summary of `undefined`. `input(0)`, with a
default, makes it optional. The inputs are `readonly` and not `protected`: the parent's template sets
them, so they are part of the component's public face.

The template reads them as signals:

```html
<!-- src/app/week-summary/week-summary.html -->
@let left = planned() - done();
<p>{{ planned() }} minutes planned, {{ done() }} done.</p>
@if (planned() === 0) {
  <p>Nothing planned this week.</p>
} @else if (left <= 0) {
  <p>Everything planned is done.</p>
} @else {
  <p>{{ left }} minutes to go.</p>
}
<label for="week-progress">Done this week</label>
<progress id="week-progress" [value]="done()" [max]="planned()"></progress>
```

The summary no longer knows where the numbers come from, or that there is a file, or what a week is.
That makes it simpler, reusable for any period, and testable with two numbers.

## A card per course

The course list gets a component of its own, the `CourseCard` of lesson 1's tree. It is the first
component generated since lesson 7 set OnPush as the default, and, like every component this lesson
generates, it comes without the generated test, which only checks that the component can be created:
lesson 24 writes real ones.

```
ana@dev:~/planner$ npx ng generate component course-card --inline-template --inline-style --skip-tests
CREATE src/app/course-card/course-card.ts (286 bytes)
```

```typescript
// src/app/course-card/course-card.ts
import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { Course } from '../planner';

@Component({
  selector: 'app-course-card',
  imports: [],
  template: `<span class="name">{{ course().name }}</span>: {{ minutes() }} minutes`,
  styles: `
    .name {
      font-weight: 600;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CourseCard {
  readonly course = input.required<Course>();
  readonly minutes = input(0);
}
```

`changeDetection: ChangeDetectionStrategy.OnPush` came from the generator, as `ng config` asked.

## The week hands both down

```typescript
// src/app/week/week.ts
import { ChangeDetectionStrategy, Component, computed, resource } from '@angular/core';
import { isoDay, loadPlanner, totals, weekOf } from '../planner';
import { CourseCard } from '../course-card/course-card';
import { WeekSummary } from '../week-summary/week-summary';

@Component({
  selector: 'app-week',
  imports: [CourseCard, WeekSummary],
  templateUrl: './week.html',
  styleUrl: './week.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Week {
  protected readonly data = resource({ loader: loadPlanner });
  private readonly week = weekOf(isoDay(new Date()));
  protected readonly totals = computed(() => totals(this.data.value()?.sessions ?? [], this.week));
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
@if (data.isLoading()) {
  <p>Loading the week…</p>
} @else if (data.error(); as error) {
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
```

The loading and error branches moved up with the data: the component that loads is the one that says
it is loading.

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --network
[vite] connecting...
[vite] connected.
Angular is running in development mode.
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

One request this time, and the same page. **Data flows down through inputs, and a child never reaches
up for it.** The week owns the data and decides what each child sees; each child draws what it is
given.

## The inputs you will still meet

Before Angular 17.1 an input was a decorated field, and most code at work still looks like this:

```typescript
@Input({ required: true }) planned!: number;
```

The value is a plain field, not a signal, so a computed cannot depend on it, and reacting to a change
needs the `ngOnChanges` hook of lesson 9. `input()` replaced it, and the CLI ships a migration,
`ng generate @angular/core:signal-input-migration`, that rewrites the old form into the new one.
