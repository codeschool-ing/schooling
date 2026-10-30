---
title: Routes, and the outlet they fill
version: 1
---

**The router maps an address to a component, and draws that component where the application has a
`<router-outlet>`.** Until now `App` put both screens on one page, one above the other, with the
course fixed as `javascript`. A real planner shows one screen at a time and lets the address say
which: `/` for the week, `/courses/git` for a course. The router reads the address when the page
loads, draws the matching component, and changes the address, and the component, when somebody
follows a link.

The router has been in the project since lesson 2: `app.routes.ts` with an empty list, and
`provideRouter(routes)` in `app.config.ts`. A component for an address nobody planned for comes
first:

```
ana@dev:~/planner$ npx ng generate component not-found --inline-template --inline-style --skip-tests
CREATE src/app/not-found/not-found.ts (280 bytes)
```

```typescript
// src/app/not-found/not-found.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-not-found',
  imports: [RouterLink],
  template: `
    <h2>Nothing here</h2>
    <p>The planner has no page at this address. <a routerLink="/">Back to this week</a>.</p>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotFound {}
```

The routes, in the order the router tries them:

```typescript
// src/app/app.routes.ts
import { Routes } from '@angular/router';
import { CoursePage } from './course-page/course-page';
import { NotFound } from './not-found/not-found';
import { Week } from './week/week';

export const routes: Routes = [
  { path: '', component: Week },
  { path: 'courses/:courseId', component: CoursePage },
  { path: '**', component: NotFound },
];
```

**The router takes the first route that matches**, so the order is part of the meaning. `''` matches
only the empty path, here `/`. `courses/:courseId` matches `courses/` followed by one segment, and
`:courseId` names that segment a parameter. `**` matches anything, which is why it goes last: put
first, it would answer every address with "not found".

`withComponentInputBinding()` is the one line that joins the router to lesson 8's inputs: a route
parameter called `courseId` is set on the component's input of the same name. `CoursePage` already
has that input, `input.required<string>()`, so it needs no change at all.

```typescript
// src/app/app.config.ts
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter, withComponentInputBinding } from '@angular/router';

import { routes } from './app.routes';
import { requestedBy } from './requested-by';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes, withComponentInputBinding()),
    provideHttpClient(withInterceptors([requestedBy])),
  ]
};
```

`App` keeps its heading and gives the rest of the page to the outlet:

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<main>
  <router-outlet />
</main>
```

```typescript
// src/app/app.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet],
  templateUrl: './app.html',
  styleUrl: './app.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text main
[vite] connecting...
Angular is running in development mode.
[vite] connected.
This week

2026-10-19 to 2026-10-25

165 minutes planned, 90 done.

75 minutes to go.

Done this week
Courses
HTML and CSS: 30 minutes
JavaScript: 110 minutes
Git: 25 minutes
```

```
ana@dev:~/planner$ look http://localhost:4200/courses/git --text main
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Git
 2026-10-22, 25 minutes
Add sessions
Date 1
Another date
Minutes
Add
```

```
ana@dev:~/planner$ look http://localhost:4200/nowhere --text main
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Nothing here

The planner has no page at this address. Back to this week.
```

Three addresses, three screens, one application. The last one works because of something lesson 2
showed: the dev server answers an address with no file behind it with `index.html`, so the
application starts, and then the router decides. `curl` sees the same answer for a course:

```
ana@dev:~/planner$ curl -si http://localhost:4200/courses/git | head -1
HTTP/1.1 200 OK
```

A 200 and the application's page, for an address that is not a file. Whatever serves the built
application in production has to do the same, or every address but `/` is a 404 on reload.
