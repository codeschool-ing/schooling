---
title: Guards, and what they are not
version: 1
---

**A guard is a function the router asks before it goes ahead with a navigation: may this route be
used, entered, left?** It answers `true` to let the navigation through, `false` to stop it, or a
redirect to send it somewhere else, and it may take its time, returning a Promise or an Observable,
as lesson 17's resolver did.

| guard | asked | the usual question |
|---|---|---|
| `canMatch` | before the route is even considered, and before a lazy part is loaded | should this route exist for this person at all? |
| `canActivate` | before the route's component is drawn | may this page be opened? |
| `canActivateChild` | before any child of the route is drawn | may anything under here be opened? |
| `canDeactivate` | before the page is left | is it all right to leave? |

The course page has a question for `canActivate`. Since lesson 17, `/courses/rust` draws the course
page, which then says it has no such course. A guard can decide before the page is drawn, and show
the not-found page instead, with its title, under the address the person typed:

```typescript
// src/app/course-exists.ts
import { inject } from '@angular/core';
import { toObservable } from '@angular/core/rxjs-interop';
import { CanActivateFn, RedirectCommand, Router } from '@angular/router';
import { filter, map, take } from 'rxjs';
import { PlannerStore } from './planner-store';

export const courseExists: CanActivateFn = (route) => {
  const store = inject(PlannerStore);
  const router = inject(Router);
  return toObservable(store.isLoading).pipe(
    filter((loading) => !loading),
    take(1),
    map(() => {
      const id = route.paramMap.get('courseId');
      if (store.error() || store.courses().some((c) => c.id === id)) return true;
      return new RedirectCommand(router.parseUrl('/not-found'), { skipLocationChange: true });
    }),
  );
};
```

It waits for the store, as `courseTitle` did. If the data could not be loaded it lets the page
through, because the page says that better than "not found" would. Otherwise it answers `true`, or a
`RedirectCommand` to an address only the `**` route matches, with `skipLocationChange` so the address
bar keeps what was typed.

```typescript
// src/app/app.routes.ts
import { Routes } from '@angular/router';
import { AddSession } from './add-session/add-session';
import { CoursePage } from './course-page/course-page';
import { CourseSessions } from './course-sessions/course-sessions';
import { courseExists } from './course-exists';
import { courseTitle } from './course-title';
import { NotFound } from './not-found/not-found';
import { Week } from './week/week';

export const routes: Routes = [
  { path: '', component: Week, title: 'This week · Study planner' },
  {
    path: 'courses/:courseId',
    component: CoursePage,
    title: courseTitle,
    canActivate: [courseExists],
    children: [
      { path: '', component: CourseSessions },
      { path: 'add', component: AddSession },
    ],
  },
  { path: 'week', redirectTo: '' },
  { path: 'course/:courseId', redirectTo: 'courses/:courseId' },
  { path: '**', component: NotFound, title: 'Not found · Study planner' },
];
```

```
ana@dev:~/planner$ look http://localhost:4200/courses/rust --url --text main
[vite] connecting...
[vite] connected.
Angular is running in development mode.
url: /courses/rust
Nothing here

The planner has no page at this address. Back to this week.
```

```
ana@dev:~/planner$ look http://localhost:4200/courses/rust --html title
[vite] connecting...
[vite] connected.
Angular is running in development mode.
<title>Not found · Study planner</title>
```

## What a guard is not

**A guard decides what the interface shows; it protects nothing.** It runs in the browser, in code
the person has and can change, and the data a guarded page would show still comes from an API that
anybody can call with `curl`, as lesson 15 did. A guard that keeps people who are not signed in away
from a page is a courtesy that saves them a page of errors. What keeps the data from them is the
server refusing the request, every time, whatever the browser did first. A guard without that is a
locked door in a wall that is not there.
