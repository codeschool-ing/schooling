---
title: Redirects, for addresses that moved
version: 1
---

**A redirect is a route with no component: it sends the router to another address.** Two reasons to
have one. An address people already use, in bookmarks or in links from elsewhere, should keep
working after the page has moved. And two addresses for one page, such as `/` and `/week`, are
kinder than one of them being a 404.

```typescript
// src/app/app.routes.ts
import { Routes } from '@angular/router';
import { AddSession } from './add-session/add-session';
import { CoursePage } from './course-page/course-page';
import { CourseSessions } from './course-sessions/course-sessions';
import { NotFound } from './not-found/not-found';
import { Week } from './week/week';

export const routes: Routes = [
  { path: '', component: Week },
  {
    path: 'courses/:courseId',
    component: CoursePage,
    children: [
      { path: '', component: CourseSessions },
      { path: 'add', component: AddSession },
    ],
  },
  { path: 'week', redirectTo: '' },
  { path: 'course/:courseId', redirectTo: 'courses/:courseId' },
  { path: '**', component: NotFound },
];
```

`redirectTo` can use the parameters of the address it matched, so `course/:courseId` becomes
`courses/` with the same id. Both go before `**`, as everything does.

```
ana@dev:~/planner$ look http://localhost:4200/week --url --text h2
[vite] connecting...
[vite] connected.
Angular is running in development mode.
url: /
This week
```

```
ana@dev:~/planner$ look http://localhost:4200/course/git --url --text h2
[vite] connecting...
[vite] connected.
Angular is running in development mode.
url: /courses/git
Git
```

The address changed in the browser, not only the screen: `--url` printed where the page ended up.
That matters for the same reason the redirect exists. A person who copies the address now copies
the one that will keep working.

A redirect can also be a function, given the route and returning a path or a `UrlTree`, for a move
that needs a decision: an old numeric id that has to be looked up, say. The two here need none.
