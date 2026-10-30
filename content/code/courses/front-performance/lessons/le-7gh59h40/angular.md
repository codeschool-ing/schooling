---
title: Angular SSR
version: 1
---

**Angular declares its routes in a list, and recent versions declare a second list beside it that
says how the server renders each one.** `app.routes.ts` maps an address to a component, as it
does in an app with no server at all. `app.routes.server.ts` maps an address to a *render mode*:
rendered on each request, prerendered at build time, or left to the browser. The CLI wrote both,
with the server, when `--ssr` was given.

The data is fetched with Angular's `HttpClient`, from the same `courses.json` the planner serves in
`public/`. Save this as `src/app/plan.ts`. **On the server the request goes to the server itself,
over HTTP**, and the answer travels to the browser inside the page, so the browser does not ask
again:

```typescript
// src/app/plan.ts: the planner's data, fetched once per page, on the server and in the browser.
import { HttpClient } from "@angular/common/http";
import { inject, Injectable } from "@angular/core";
import { toSignal } from "@angular/core/rxjs-interop";

export interface Plan {
  courses: { slug: string; title: string }[];
  sessions: { id: number; course: string; date: string; minutes: number; done: boolean }[];
}

@Injectable({ providedIn: "root" })
export class PlanService {
  readonly plan = toSignal(inject(HttpClient).get<Plan>("/courses.json"));
}
```

The home page, `src/app/home.ts`:

```typescript
// src/app/home.ts: the address /.
import { Component, inject } from "@angular/core";
import { RouterLink } from "@angular/router";
import { PlanService } from "./plan";

@Component({
  selector: "app-home",
  imports: [RouterLink],
  template: `
    <h1>Study planner</h1>
    @if (plan(); as p) {
      <ul>
        @for (c of p.courses; track c.slug) {
          <li><a [routerLink]="['/courses', c.slug]">{{ c.title }}</a> · {{ count(c.slug) }} sessions</li>
        }
      </ul>
    }
  `,
})
export class Home {
  protected readonly plan = inject(PlanService).plan;
  protected count(slug: string) {
    return this.plan()!.sessions.filter((s) => s.course === slug).length;
  }
}
```

A course, `src/app/course.ts`. `slug` is an **input** the router fills from the address, which
`withComponentInputBinding()` below switches on:

```typescript
// src/app/course.ts: the address /courses/<slug>.
import { Component, computed, inject, input } from "@angular/core";
import { RouterLink } from "@angular/router";
import { PlanService } from "./plan";

@Component({
  selector: "app-course",
  imports: [RouterLink],
  template: `
    <p><a routerLink="/">All courses</a></p>
    @if (course(); as c) {
      <h1>{{ c.title }}</h1>
      <ul>
        @for (s of sessions(); track s.id) {
          <li>{{ s.date }} · {{ s.minutes }} min{{ s.done ? " · done" : "" }}</li>
        }
      </ul>
    }
  `,
})
export class Course {
  readonly slug = input.required<string>();
  private readonly plan = inject(PlanService).plan;
  protected readonly course = computed(() => this.plan()?.courses.find((c) => c.slug === this.slug()));
  protected readonly sessions = computed(() => this.plan()?.sessions.filter((s) => s.course === this.slug()) ?? []);
}
```

The component around every route replaces `src/app/app.ts`; delete the CLI's `app.html` and
`app.css`, which belonged to its welcome page:

```typescript
// src/app/app.ts: the page around every route.
import { Component } from "@angular/core";
import { RouterOutlet } from "@angular/router";

@Component({
  selector: "app-root",
  imports: [RouterOutlet],
  template: `<main><router-outlet /></main>`,
})
export class App {}
```

The two lists. First the routes, `src/app/app.routes.ts`:

```typescript
// src/app/app.routes.ts: which component answers which address.
import { Routes } from "@angular/router";
import { Course } from "./course";
import { Home } from "./home";

export const routes: Routes = [
  { path: "", component: Home, title: "Study planner" },
  { path: "courses/:slug", component: Course, title: "Study planner" },
];
```

Then how the server renders them, `src/app/app.routes.server.ts`. The CLI's version prerendered
every route; this one renders every route on each request, as the other three projects do:

```typescript
// src/app/app.routes.server.ts: how the server renders each address.
import { RenderMode, ServerRoute } from "@angular/ssr";

export const serverRoutes: ServerRoute[] = [
  { path: "**", renderMode: RenderMode.Server },
];
```

And the configuration, `src/app/app.config.ts`, which adds `HttpClient` and the input binding to
what the CLI wrote. `provideClientHydration(withEventReplay())` was already there: it is the line
that makes the browser hydrate the server's HTML instead of drawing it again, and it records clicks
that happen before hydration finishes so that they are replayed afterwards. Lesson 4 is about
exactly that window.

```typescript
// src/app/app.config.ts
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from "@angular/core";
import { provideHttpClient, withFetch } from "@angular/common/http";
import { provideClientHydration, withEventReplay } from "@angular/platform-browser";
import { provideRouter, withComponentInputBinding } from "@angular/router";
import { routes } from "./app.routes";

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes, withComponentInputBinding()),
    provideHttpClient(withFetch()),
    provideClientHydration(withEventReplay()),
  ],
};
```

## The host it refuses

Build it:

```
ana@dev:~/meta/angular$ npm run build 2>&1 | grep -E 'Initial total|Prerendered'
                     | Initial total    | 270.04 kB |                74.41 kB
Prerendered 0 static routes.
```

`Prerendered 0 static routes`, because every route is `RenderMode.Server` now. Start the server the
CLI wrote in the second terminal, and in the first ask it for a course and look at what came back
inside `<app-root>`:

```
ana@dev:~/meta/angular$ curl -s http://localhost:3004/courses/git | grep app-root
  <app-root></app-root>
```

The second terminal, after that request:

```
ana@dev:~/meta/angular$ PORT=3004 node dist/angular/server/server.mjs
Node Express server listening on http://localhost:3004
ERROR: Bad Request ("http://localhost:3004/courses/git").
Header "host" with value "localhost:3004" is not allowed.
Falling back to client side rendering. This will become a 400 Bad Request in a future major version.

For more information, see https://angular.dev/best-practices/security#preventing-server-side-request-forgery-ssrf
```

**The page came back with an empty `<app-root>`: the server refused to render it, and sent the
client-rendered page instead.** Its log says why. Because the server fetches `courses.json` from
itself, a request whose `Host` header named some other machine would make it fetch from that
machine instead, with the server's own network access. That is called *server-side request
forgery*, and Angular now refuses to render for any host it was not told about. Today it falls back
to the browser and prints this; the message says a future version will answer with a 400.

The fix is to name the host. Stop the server with `Ctrl-C`; `ng config` writes the name into
`angular.json`, and the build has to run again for it to count:

```
ana@dev:~/meta/angular$ npx ng config projects.angular.architect.build.options.security.allowedHosts '["localhost"]'
ana@dev:~/meta/angular$ grep -A3 '"security"' angular.json
            "security": {
              "allowedHosts": [
                "localhost"
              ]
ana@dev:~/meta/angular$ npm run build 2>&1 | grep -E 'Initial total|Prerendered'
                     | Initial total    | 270.04 kB |                74.41 kB
Prerendered 0 static routes.
```

On a real deployment that list holds the site's own domain names. Start it in the second terminal:

```sh
PORT=3004 node dist/angular/server/server.mjs
```
