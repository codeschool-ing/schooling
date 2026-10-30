---
title: The scope an instance really has
version: 1
---

**"A service is a singleton" is true only of where it is provided.** `providedIn: 'root'` makes one
instance for the application, and that is the case almost every service is in. But the same class
listed in a component's `providers` makes one instance per component, as `Tally` did in lesson 10,
and nothing in the class itself says which. Whoever writes the provider decides the scope.

The way it goes wrong is a line somebody adds meaning well. Give `CoursePage` the store in its own
`providers`, perhaps to be sure it has one:

```typescript
// src/app/course-page/course-page.ts
import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { PlannerStore } from '../planner-store';
import { SessionList } from '../session-list/session-list';

@Component({
  selector: 'app-course-page',
  imports: [SessionList],
  providers: [PlannerStore],
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

The defect of this lesson's first section is back, exactly: two requests, and 90 minutes done after
the tick. `CoursePage`'s question stopped at its own injector, which made a second store, with a
second resource and a second copy. Nothing failed to compile and nothing printed an error. **A
singleton by convention is broken by one line in a list**, which is the reason to look for
`providers:` in a component before believing that a service is shared.

The line goes, and the store is one again:

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

## When per component is right

A component's `providers` is the right place for state that belongs to one instance of a component
and should die with it: the half-filled fields of a form that appears several times on a page, or
the open and closed panels of one tree. Each copy is meant to be separate, and when the component is
destroyed its service goes with it.

| the state is | provide it |
|---|---|
| the application's, shared by every screen | `providedIn: 'root'` |
| one component's, separate per instance | in that component's `providers` |
| one area's, loaded with a part of the application | in a route's `providers`, lesson 18 |

The third row is a different kind of injector, made for a group of routes that are loaded together.
Lesson 18 shows it, because it changes how many instances a lazily loaded part of an application
really has.

```
ana@dev:~/planner$ git add -A && git commit -q -m "Services: one store for the planner"
```
