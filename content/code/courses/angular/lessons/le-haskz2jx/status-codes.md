---
title: What the server answers, besides the page
version: 1
---

**A page rendered on the server is also an HTTP response, and its status code is read by
programs that never look at the page.** A search engine drops an address that answers `404`, a
link checker reports it, a cache keeps a `200`. In the browser alone none of this mattered: the dev
server answered every address with `index.html` and a `200`, and the router decided what to show.
Now each address is rendered, so each can answer for itself. `curl` can print the status and, for
a redirect, where it points:

```
ana@dev:~/planner$ for p in / /week /course/git /nowhere /courses/nope; do curl -s -o /dev/null -w "$p %{http_code} %{redirect_url}\n" http://localhost:4200$p; done
/ 200 
/week 302 http://localhost:4200/
/course/git 302 http://localhost:4200/course/courses/:courseId
/nowhere 200 
/courses/nope 200 
```

Three of the five are wrong.

- `/course/git` is the old address lesson 17 kept working with `redirectTo: 'courses/:courseId'`.
  In the browser the router fills in `:courseId`. On the server, the redirect is answered with a
  `302` before the application runs, and the address in it is the route's text, `:courseId` and
  all, so the old link now leads to a page that does not exist.
- `/nowhere` shows "Nothing here" with a `200`, which says to every program reading it that the
  page exists. That is called a soft 404.
- `/courses/nope` is the same: the `courseExists` guard of lesson 18 sends it to the same page.

The redirect is fixed by computing the address instead of writing it as a pattern. `redirectTo`
accepts a function, which receives the route's parameters:

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
  { path: 'course/:courseId', redirectTo: ({ params }) => `/courses/${params['courseId']}` },
  { path: '**', component: NotFound, title: 'Not found · Study planner' },
];
```

On the server, a function cannot be answered before the application runs, so the application runs,
the router follows the function, and the server answers with a `302` to where the router went.

The status of a rendered page is set from inside the application, through a token, `RESPONSE_INIT`.
On the server it is the response being prepared; in the browser there is no response to prepare,
and it is `null`. `NotFound` is the one component that knows the answer is "not found":

```schooling-example
{"language": "typescript", "file": "src/app/not-found/not-found.ts", "parts": [
 {"code": "// src/app/not-found/not-found.ts\nimport { ChangeDetectionStrategy, Component, RESPONSE_INIT, inject } from '@angular/core';\nimport { RouterLink } from '@angular/router';\n\n@Component({\n  selector: 'app-not-found',\n  imports: [RouterLink],\n  template: `\n    <h2>Nothing here</h2>\n    <p>The planner has no page at this address. <a routerLink=\"/\">Back to this week</a>.</p>\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})"},
 {"code": "export class NotFound {\n  constructor() {\n    const response = inject(RESPONSE_INIT);\n    if (response) response.status = 404;\n  }\n}", "note": "`null` in the browser, so the `if` is the whole of the browser's part. On the server, the status set here is the one sent."}
]}
```

```
ana@dev:~/planner$ for p in / /week /course/git /nowhere /courses/nope; do curl -s -o /dev/null -w "$p %{http_code} %{redirect_url}\n" http://localhost:4200$p; done
/ 200 
/week 302 http://localhost:4200/
/course/git 302 http://localhost:4200/courses/git
/nowhere 404 
/courses/nope 404 
```

`/courses/nope` answers `404` too, without a change of its own, because the guard sends it to the
same component. A person sees exactly what they saw before:

```
ana@dev:~/planner$ look http://localhost:4200/courses/nope --text main
[error] Failed to load resource: the server responded with a status of 404 (Not Found)
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Angular hydrated 2 component(s) and 17 node(s), 0 component(s) were skipped. Learn more at https://v21.angular.dev/guide/hydration.
Nothing here

The planner has no page at this address. Back to this week.
```

The first line is the browser reporting the `404` of the page itself. It is the only sign, and it
is the right one.
