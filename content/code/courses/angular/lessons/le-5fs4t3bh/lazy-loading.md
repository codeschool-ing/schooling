---
title: Lazy loading, a part of the application fetched when it is needed
version: 1
---

**Everything the routes import directly goes into the first file the browser downloads.** The
course page, its sessions, the form with its validators: a person who opens the planner to look at
the week downloads all of it, and may never open a course. A production build says how big that is:

```
ana@dev:~/planner$ npx ng build 2>&1 | sed -n '/Initial chunk/,/Output location/p'
Initial chunk files | Names         |  Raw size | Estimated transfer size
main-LXR6UEY3.js    | main          | 318.31 kB |                83.90 kB
styles-5INURTSO.css | styles        |   0 bytes |                 0 bytes

                    | Initial total | 318.31 kB |                83.90 kB

Application bundle generation complete. [4.100 seconds] - 2026-10-24T01:49:19.836Z

Output location: /home/ana/planner/dist/planner
```

One file, `main`, with everything in it. `loadChildren` takes a function that imports a list of
routes, and the build puts what only those routes use into a file of its own, fetched the first
time somebody navigates there. The course's routes move to a file of their own:

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

And the course route keeps what decides whether it is opened, its title and its guard, and loads the
rest:

```typescript
// src/app/app.routes.ts
import { Routes } from '@angular/router';
import { courseExists } from './course-exists';
import { courseTitle } from './course-title';
import { NotFound } from './not-found/not-found';
import { Week } from './week/week';

export const routes: Routes = [
  { path: '', component: Week, title: 'This week · Study planner' },
  {
    path: 'courses/:courseId',
    title: courseTitle,
    canActivate: [courseExists],
    loadChildren: () => import('./courses.routes').then((m) => m.courseRoutes),
  },
  { path: 'week', redirectTo: '' },
  { path: 'course/:courseId', redirectTo: 'courses/:courseId' },
  { path: '**', component: NotFound, title: 'Not found · Study planner' },
];
```

The import is a function call, `import('./courses.routes')`, not an `import` at the top of the file.
That is the whole trick: nothing in `app.routes.ts` names `CoursePage` any more, so the build is free
to leave it out of `main`.

```
ana@dev:~/planner$ npx ng build 2>&1 | sed -n '/Initial chunk/,/Output location/p'
Initial chunk files | Names          |  Raw size | Estimated transfer size
chunk-ZAJKZMGB.js   | -              | 270.05 kB |                73.92 kB
main-DZVPXVFB.js    | main           |   5.68 kB |                 2.04 kB
styles-5INURTSO.css | styles         |   0 bytes |                 0 bytes

                    | Initial total  | 275.74 kB |                75.96 kB

Lazy chunk files    | Names          |  Raw size | Estimated transfer size
chunk-AQS5JCV2.js   | courses-routes |  44.05 kB |                10.15 kB

Application bundle generation complete. [2.514 seconds] - 2026-10-24T01:49:25.896Z

Output location: /home/ana/planner/dist/planner
```

`main` is now a few kilobytes, a chunk holds the code both halves share, Angular itself among it,
and `courses-routes` is a lazy chunk: on the server, and not downloaded until a course is opened.
`--scripts` lists the application's script files a page loaded, in order:

```
ana@dev:~/planner$ look http://localhost:4200/ --scripts --text h2 --do 'click Git'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Git
scripts: /main.js /chunk-KGABQYFU.js /chunk-5ODBP7SE.js
Git
```

The week loaded two files. The click on Git fetched the third, then drew the course. The chunks of
the dev server are named differently from the build's, but split the same way.
