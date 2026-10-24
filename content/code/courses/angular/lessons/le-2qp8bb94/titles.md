---
title: A title for every page, and a resolver for one of them
version: 1
---

**Every route can set the document's title, and it should, because the title is what a screen
reader announces after a navigation and what a tab and a bookmark are called.** A single-page
application that never changes its title says "Planner" on every page, and a person who cannot see
the screen hears that nothing changed.

A fixed title is a string on the route. The course page's title depends on the course, so it is a
**resolver**: a function the router calls before it activates the route, which may return a value
or an Observable, and the route waits for its answer. `courseTitle` waits until the store has
loaded, so the name is known, and then finds it:

```typescript
// src/app/course-title.ts
import { inject } from '@angular/core';
import { toObservable } from '@angular/core/rxjs-interop';
import { ResolveFn } from '@angular/router';
import { filter, map, take } from 'rxjs';
import { PlannerStore } from './planner-store';

export const courseTitle: ResolveFn<string> = (route) => {
  const store = inject(PlannerStore);
  return toObservable(store.isLoading).pipe(
    filter((loading) => !loading),
    take(1),
    map(() => {
      const course = store.courses().find((c) => c.id === route.paramMap.get('courseId'));
      return `${course?.name ?? 'No such course'} · Study planner`;
    }),
  );
};
```

```typescript
// src/app/app.routes.ts
import { Routes } from '@angular/router';
import { AddSession } from './add-session/add-session';
import { CoursePage } from './course-page/course-page';
import { CourseSessions } from './course-sessions/course-sessions';
import { courseTitle } from './course-title';
import { NotFound } from './not-found/not-found';
import { Week } from './week/week';

export const routes: Routes = [
  { path: '', component: Week, title: 'This week · Study planner' },
  {
    path: 'courses/:courseId',
    component: CoursePage,
    title: courseTitle,
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
ana@dev:~/planner$ look http://localhost:4200/ --html title
[vite] connecting...
[vite] connected.
Angular is running in development mode.
<title>This week · Study planner</title>
```

```
ana@dev:~/planner$ look http://localhost:4200/courses/git --html title
[vite] connecting...
[vite] connected.
Angular is running in development mode.
<title>Git · Study planner</title>
```

```
ana@dev:~/planner$ look http://localhost:4200/nowhere --html title
[vite] connecting...
[vite] connected.
Angular is running in development mode.
<title>Not found · Study planner</title>
```

**A resolver makes the navigation wait**, which is its point and its cost. Here it waits for data
the store loads once, so the delay is the first load and nothing after it. A resolver that fetched
the course on every navigation would hold the old page on the screen, unresponsive, for as long as
the request took. That is why the course page itself does not use one: it shows its own loading
state, which is better than a page that seems not to have heard the click. A resolver is for what
the route cannot be activated without, and a title is one such thing.

```
ana@dev:~/planner$ git add -A && git commit -q -m "Router: a page per address, links, child routes, redirects and titles"
```
