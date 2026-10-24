---
title: HttpClient, and a resource that uses it
version: 1
---

**`HttpClient` is Angular's service for talking to a server.** `fetch` works in an Angular
application, and lesson 6 used it, but `HttpClient` does three things `fetch` leaves to you: it
reads the JSON for you, it treats a 404 or a 500 as an error rather than an answer, and every
request it makes passes through interceptors, which this lesson's sixth section uses. It is a service
like any other, so a class gets one with `inject(HttpClient)`.

In Angular 21 nothing has to be provided first: `HttpClient` has `providedIn: 'root'`, and sends
its requests with `XMLHttpRequest`. Code written for earlier versions always lists
`provideHttpClient()` in `app.config.ts`, because without it there was no `HttpClient` to inject;
the line is still how its features are switched on, and the planner adds it when it needs one.

## The store reads from the API

For reading, `@angular/common/http` has a resource of its own, `httpResource`: a `resource` whose
loader is an `HttpClient` GET. It takes a function returning the URL, so a URL built from signals is
fetched again when they change, as lesson 6's `params` were. Like `resource`, it is marked
experimental in Angular 21. The store changes in three lines:

```schooling-example
{"language": "typescript", "file": "src/app/planner-store.ts", "parts": [
 {"code": "// src/app/planner-store.ts\nimport { HttpClient, httpResource } from '@angular/common/http';\nimport { Injectable, computed, inject } from '@angular/core';\nimport { PlannerData, Session, isoDay, totals, weekOf } from './planner';\nimport { TODAY } from './today';\n\n@Injectable({\n  providedIn: 'root',\n})\nexport class PlannerStore {", "note": "`HttpClient` and `httpResource` come from Angular's HTTP package. `loadPlanner` is no longer imported."},
 {"code": "  private readonly http = inject(HttpClient);\n  private readonly data = httpResource<PlannerData>(() => '/api/planner');", "note": "The `HttpClient` is for writing, two sections on. The resource reads: the type argument says what the answer is expected to be."},
 {"code": "  readonly isLoading = this.data.isLoading;\n  readonly error = this.data.error;\n  readonly courses = computed(() => (this.data.hasValue() ? this.data.value().courses : []));\n  readonly sessions = computed(() => (this.data.hasValue() ? this.data.value().sessions : []));\n  readonly week = weekOf(isoDay(inject(TODAY)));\n  readonly weekTotals = computed(() => totals(this.sessions(), this.week));\n\n  minutesThisWeek(courseId: string): number {\n    return totals(this.sessions().filter((s) => s.courseId === courseId), this.week).planned;\n  }\n\n  toggle(id: number, done: boolean): void {\n    this.data.update((data) =>\n      data && { ...data, sessions: data.sessions.map((s) => (s.id === id ? { ...s, done } : s)) },\n    );\n  }\n}"}
]}
```

Nothing else changes. The components ask the store for the same signals, and the store fills them
from somewhere else:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-week-summary --network
[vite] connecting...
[vite] connected.
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /api/planner  200
165 minutes planned, 90 done.

75 minutes to go.

Done this week
```

The same week, from `/api/planner`, and the API's terminal has one more `GET` line. The page
connected to the dev server twice: it was the first page to import `@angular/common/http`, so the
dev server prepared that package for the browser and reloaded the page, and its own terminal says
`new dependencies optimized: @angular/common/http`. It happens once per package. `loadPlanner` in
`planner.ts` has no caller now; the next section replaces it with something the resource needs more.
