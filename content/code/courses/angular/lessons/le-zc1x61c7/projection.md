---
title: Content projection, passing markup in
version: 1
---

**`<ng-content />` in a component's template marks where whatever the parent wrote between the
component's tags will appear.** Inputs pass values; projection passes markup, elements and other
components, that the parent writes and the child places. It is how a component offers a frame, a
card, a dialog, a panel, around content it does not know.

Both of the planner's screens are a heading followed by content. A panel can give them the same
frame:

```
ana@dev:~/planner$ npx ng generate component panel --inline-template --inline-style --skip-tests
CREATE src/app/panel/panel.ts (269 bytes)
```

```typescript
// src/app/panel/panel.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
  selector: 'app-panel',
  imports: [],
  template: `
    <section class="panel">
      <ng-content select="h2" />
      <ng-content />
    </section>
  `,
  styles: `
    .panel {
      border: 1px solid currentColor;
      border-radius: 0.5rem;
      padding: 0 1rem 1rem;
      margin-bottom: 1rem;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Panel {}
```

Two slots. **`select="h2"`** takes the parent's `<h2>`, wherever the parent wrote it, and puts it
first; the plain `<ng-content />` takes everything else. `select` accepts a CSS selector, so a slot
can take an element, a class or an attribute.

The week wraps its template in it:

```html
<!-- src/app/week/week.html -->
<app-panel>
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
</app-panel>
```

and imports it, the line `Panel` added to its `imports` and its file:

```typescript
// src/app/week/week.ts
import { ChangeDetectionStrategy, Component, computed, resource } from '@angular/core';
import { isoDay, loadPlanner, totals, weekOf } from '../planner';
import { CourseCard } from '../course-card/course-card';
import { Panel } from '../panel/panel';
import { WeekSummary } from '../week-summary/week-summary';

@Component({
  selector: 'app-week',
  imports: [CourseCard, Panel, WeekSummary],
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

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --html 'app-week section > *:first-child'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
<h2>This week</h2>
```

The heading is the panel's first child, inside the `<section>`, exactly where the slot put it.
**The projected content belongs to the parent.** It is the week's template, checked with the week,
reading the week's signals, and styled by the week's stylesheet; the panel only decides where it goes.
The `.panel` rule reaches the `<section>` because the section is in the panel's own template.

A slot can also hold **fallback content**, written inside the `<ng-content>` tags, shown when the
parent gives nothing for that slot. The course page could use the same panel, with the same two lines
around its template.
