---
title: Providers on a route, and how long they live
version: 1
---

**A route can have `providers`, and they go into an injector of the route's own, which every
component under that route asks before the root.** Lesson 11 left this row of its table for here,
saying that it changes how many instances a lazily loaded part of an application really has. The
honest way to find out is to count them. A probe that numbers each instance made, and says when one
is destroyed:

```typescript
// src/app/area-probe.ts
import { DestroyRef, Injectable, inject } from '@angular/core';

let made = 0;

@Injectable()
export class AreaProbe {
  readonly number = ++made;

  constructor() {
    console.log(`probe ${this.number} made`);
    inject(DestroyRef).onDestroy(() => console.log(`probe ${this.number} destroyed`));
  }
}
```

Provided on the course area's route:

```typescript
// src/app/courses.routes.ts
import { Routes } from '@angular/router';
import { AddSession } from './add-session/add-session';
import { AreaProbe } from './area-probe';
import { CoursePage } from './course-page/course-page';
import { CourseSessions } from './course-sessions/course-sessions';
import { unsavedWork } from './unsaved-work';

export const courseRoutes: Routes = [
  {
    path: '',
    component: CoursePage,
    providers: [AreaProbe],
    children: [
      { path: '', component: CourseSessions },
      { path: 'add', component: AddSession, canDeactivate: [unsavedWork] },
    ],
  },
];
```

And asked for by the course page, which says which probe it was given:

```typescript
// src/app/course-page/course-page.ts
import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { AreaProbe } from '../area-probe';
import { PlannerStore } from '../planner-store';

@Component({
  selector: 'app-course-page',
  imports: [RouterLink, RouterLinkActive, RouterOutlet],
  templateUrl: './course-page.html',
  styleUrl: './course-page.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CoursePage {
  readonly courseId = input.required<string>();
  protected readonly store = inject(PlannerStore);
  private readonly probe = inject(AreaProbe);
  protected readonly course = computed(() => this.store.courses().find((c) => c.id === this.courseId()));

  constructor() {
    console.log(`a course page, given probe ${this.probe.number}`);
  }
}
```

From the week to Git, back to the week, and to JavaScript:

```
ana@dev:~/planner$ look http://localhost:4200/ --text h2 --do 'click Git' --do 'click This week' --do 'click JavaScript'
[vite] connecting...
Angular is running in development mode.
[vite] connected.
-- click Git
probe 1 made
a course page, given probe 1
-- click This week
-- click JavaScript
a course page, given probe 1
JavaScript
```

**One probe, made the first time the area was entered, and never destroyed.** Leaving for the week
did not end it, and the JavaScript page was given the same one as Git's. A route's injector is made
when the route is first used and kept for as long as the application runs, so a service provided on a
route is a singleton for that area, shared by every course, not one per course and not one per visit.

| provided | one instance per | made | ends |
|---|---|---|---|
| `providedIn: 'root'` | application | first time asked | never |
| a route's `providers` | that route, for every visit and every parameter | first time the route is used | never |
| a component's `providers` | component instance | with the component | with the component |

So a route's providers suit what belongs to an area but outlives a visit, a cache of something only
that area uses, say, kept out of the root so the main bundle does not carry it. State that should
start fresh on every visit belongs in the component's `providers` instead.

The probe has answered the question, and goes:

```
ana@dev:~/planner$ rm src/app/area-probe.ts && git checkout -- src/app/course-page/course-page.ts
```

```typescript
// src/app/courses.routes.ts
import { Routes } from '@angular/router';
import { AddSession } from './add-session/add-session';
import { CoursePage } from './course-page/course-page';
import { CourseSessions } from './course-sessions/course-sessions';
import { unsavedWork } from './unsaved-work';

export const courseRoutes: Routes = [
  {
    path: '',
    component: CoursePage,
    children: [
      { path: '', component: CourseSessions },
      { path: 'add', component: AddSession, canDeactivate: [unsavedWork] },
    ],
  },
];
```
