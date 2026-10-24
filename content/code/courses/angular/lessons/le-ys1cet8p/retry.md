---
title: Retrying what may work the second time
version: 1
---

**Lesson 12 left the planner undoing a tick whenever a `PATCH` failed, whatever the reason.** That
is right for a 400, which will fail the same way every time it is sent. It is too quick for a 500
from a server that is restarting, or a network that dropped for a second, where the same request a
moment later would have worked.

`retry` subscribes again after an error, which for an `HttpClient` Observable means sending the
request again. Its `delay` option decides, for each error, whether to try again and when: an
Observable that emits means "try now", one that errors means "stop, and pass this error on".

```schooling-example
{"language": "typescript", "file": "src/app/planner-store.ts", "parts": [
 {"code": "// src/app/planner-store.ts\nimport { HttpClient, HttpErrorResponse, httpResource } from '@angular/common/http';\nimport { Injectable, computed, inject, signal } from '@angular/core';\nimport { retry, throwError, timer } from 'rxjs';\nimport { Session, isoDay, parsePlanner, totals, weekOf } from './planner';\nimport { TODAY } from './today';\n\nconst transient = (error: HttpErrorResponse) => error.status === 0 || error.status >= 500;", "note": "The operators come from `rxjs`; `transient` is a plain function that says which failures are worth a second try."},
 {"code": "@Injectable({\n  providedIn: 'root',\n})\nexport class PlannerStore {\n  private readonly http = inject(HttpClient);\n  private readonly data = httpResource(() => '/api/planner', { parse: parsePlanner });\n\n  readonly isLoading = this.data.isLoading;\n  readonly error = this.data.error;\n  readonly courses = computed(() => (this.data.hasValue() ? this.data.value().courses : []));\n  readonly sessions = computed(() => (this.data.hasValue() ? this.data.value().sessions : []));\n  readonly week = weekOf(isoDay(inject(TODAY)));\n  readonly weekTotals = computed(() => totals(this.sessions(), this.week));\n  readonly saveError = signal<string | null>(null);\n\n  minutesThisWeek(courseId: string): number {\n    return totals(this.sessions().filter((s) => s.courseId === courseId), this.week).planned;\n  }"},
 {"code": "  toggle(id: number, done: boolean): void {\n    this.saveError.set(null);\n    this.setDone(id, done);\n    this.http\n      .patch<Session>(`/api/sessions/${id}`, { done })\n      .pipe(retry({ count: 3, delay: (error: HttpErrorResponse) => (transient(error) ? timer(2000) : throwError(() => error)) }))\n      .subscribe({\n        error: (error: HttpErrorResponse) => {\n          this.setDone(id, !done);\n          this.saveError.set(`Session ${id} was not saved: ${error.error?.error ?? error.statusText}`);\n        },\n      });\n  }", "note": "Up to three more tries, two seconds apart, for a failure that may pass. Anything else, a 400 or a 404, goes straight to the `error` callback, as before."},
 {"code": "  private setDone(id: number, done: boolean): void {\n    this.data.update((data) =>\n      data && { ...data, sessions: data.sessions.map((s) => (s.id === id ? { ...s, done } : s)) },\n    );\n  }\n}"}
]}
```

The test is the course page, with the same five seconds as lesson 12, the same `Ctrl-C` in the API's terminal, and then, within a couple
of seconds of the tick, `node server/api.mjs` again:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --a11y app-course-page --network --do 'wait 5000' --do 'check 2026-10-24, 50 minutes' --do 'wait 4000'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /api/planner  200
net  GET /api/planner  200
-- wait 5000
-- check 2026-10-24, 50 minutes
net  PATCH /api/sessions/5  500
[error] Failed to load resource: the server responded with a status of 500 (Internal Server Error)
-- wait 4000
net  PATCH /api/sessions/5  200
- heading "JavaScript" [level=2]
- list
  - listitem [level=1]
    - ListMarker "• "
    - checkbox " 2026-10-13, 45 minutes" [checked]
  - listitem [level=1]
    - ListMarker "• "
    - checkbox " 2026-10-20, 60 minutes" [checked]
  - listitem [level=1]
    - ListMarker "• "
    - checkbox " 2026-10-24, 50 minutes" [focused] [checked]
```

The first `PATCH` met the proxy's 500. Two seconds later `retry` sent it again, the API was back,
and it answered 200. The box stayed ticked, no message appeared, and the person never knew.

**Retry only what is safe to send twice.** Setting `done` to `true` twice leaves the same session
as setting it once; a `PATCH` like this one, and a `GET`, are safe to repeat. A `POST` that adds a
session is not: if the first one reached the server and only its answer was lost, a retry adds a
second session. Lesson 14's form sends a `POST`, and it does not retry.
