---
title: Three ways to render a route
version: 1
---

**`app.routes.server.ts` says, route by route, where the HTML of each page is made.** The set-up
wrote one rule for every route:

```
ana@dev:~/planner$ cat src/app/app.routes.server.ts
import { RenderMode, ServerRoute } from '@angular/ssr';

export const serverRoutes: ServerRoute[] = [
  {
    path: '**',
    renderMode: RenderMode.Prerender,
  },
];
```

`RenderMode` has three values:

| mode | the HTML is made | it suits |
| --- | --- | --- |
| `Prerender` | once, during `ng build`, and saved as a file | a page that is the same for everyone until the next deploy |
| `Server` | on every request, by the running server | a page whose content changes, or differs per person |
| `Client` | in the browser, as before this lesson | a page with nothing worth sending before the scripts run |

Prerendering is the fastest of the three, since the server only hands over a file. But the build
has to know every address it will produce, and the planner's addresses have a course id in them:

```
ana@dev:~/planner$ npx ng build 2>&1 | grep -E 'ERROR|Prerendered'
Prerendered 2 static routes.
✘ [ERROR] The 'courses/:courseId' route uses prerendering and includes parameters, but 'getPrerenderParams' is missing. Please define 'getPrerenderParams' function for this route in your server routing configuration or specify a different 'renderMode'.
✘ [ERROR] The 'courses/:courseId/' route uses prerendering and includes parameters, but 'getPrerenderParams' is missing. Please define 'getPrerenderParams' function for this route in your server routing configuration or specify a different 'renderMode'.
✘ [ERROR] The 'courses/:courseId/add' route uses prerendering and includes parameters, but 'getPrerenderParams' is missing. Please define 'getPrerenderParams' function for this route in your server routing configuration or specify a different 'renderMode'.
✘ [ERROR] The 'course/:courseId' route uses prerendering and includes parameters, but 'getPrerenderParams' is missing. Please define 'getPrerenderParams' function for this route in your server routing configuration or specify a different 'renderMode'.
```

`getPrerenderParams` would answer that: a function that lists the course ids, so the build can make
`/courses/html-css`, `/courses/javascript` and `/courses/git`. It would also be wrong, for a reason
the error does not mention. **A prerendered page holds the data as it was at build time.** The week
would say "1 hour 30 minutes done" until the next deploy, whatever was ticked in between. Prerendering is for pages such as an "about" page or a course's description. The planner
has none of those, so every route is rendered per request:

```typescript
// src/app/app.routes.server.ts
import { RenderMode, ServerRoute } from '@angular/ssr';

export const serverRoutes: ServerRoute[] = [
  {
    path: '**',
    renderMode: RenderMode.Server,
  },
];
```

```
ana@dev:~/planner$ npx ng build 2>&1 | grep -E 'ERROR|Prerendered'
Prerendered 0 static routes.
```

The rules are matched against the paths in `app.routes.ts`, and for any address the most specific
rule applies, wherever it sits in the list. So a list can be mixed: a rule for
`courses/:courseId/add` with `RenderMode.Client`, beside `**`, would send the form's page empty and
leave every other page as it is. The planner keeps that page on the server too, because the form's
labels and the course's name are text worth having before the scripts arrive.
