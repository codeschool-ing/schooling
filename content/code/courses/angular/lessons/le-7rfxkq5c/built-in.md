---
title: Pipes, and the ones Angular ships
version: 1
---

**A pipe turns a value into what a template shows, written after a `|`.** `{{ value | date }}` passes
`value` to the `date` pipe and shows what comes back; arguments follow a colon, `{{ value | date:
'longDate' }}`, and pipes chain, the output of one feeding the next. A pipe changes nothing: the value
in the class is the same before and after, and only the text on the screen is formatted.

Lesson 10 left the week's range as two `YYYY-MM-DD` strings and said this lesson would write them the
way a person would. `DatePipe` is the pipe for it, imported like a component:

```typescript
// src/app/week/week.ts
import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { CourseCard } from '../course-card/course-card';
import { Panel } from '../panel/panel';
import { PlannerStore } from '../planner-store';
import { WeekSummary } from '../week-summary/week-summary';

@Component({
  selector: 'app-week',
  imports: [CourseCard, DatePipe, Panel, WeekSummary],
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
  <p>{{ store.week.start | date: 'd MMMM' }} to {{ store.week.end | date: 'longDate' }}</p>
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

`'d MMMM'` is a pattern, day then month in full; `'longDate'` is a named format, which the locale
decides. `DatePipe` takes a `Date`, a number of milliseconds, or a string, and reads a string with
only a date in it, like `2026-10-19`, as that day where the browser is, not as midnight UTC, which
is what `new Date('2026-10-19')` would make of it and which is the day before anywhere west of
London:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text 'app-week p'
[vite] connecting...
[vite] connected.
[vite] connecting...
[vite] connected.
Angular is running in development mode.
19 October to October 25, 2026
```

Both days are right, and the second is American: `longDate` asked the locale how a date is written in
full, and the locale said month, day, comma, year. The next section is about that.

## The rest of the box

| pipe | turns | into |
|---|---|---|
| `date` | a date | `19 October 2026`, `Fri 23 Oct`, `09:00` |
| `number` | a number | `1,234.5`, with the digits you ask for |
| `currency` | an amount | `£12.50`, `R$ 12,50` |
| `percent` | a fraction | `0.55` as `55%` |
| `uppercase`, `lowercase`, `titlecase` | text | the same text in another case |
| `slice` | a string or an array | a part of it |
| `json` | anything | its JSON, for a quick look while debugging |
| `keyvalue` | an object or a `Map` | a list of `{ key, value }` for `@for` |
| `async` | an Observable or a Promise | its latest value, as lesson 13 showed |

Each is a class in `@angular/common`, `DatePipe`, `CurrencyPipe` and so on, imported where it is
used.
