---
title: When the server says no, or says nothing
version: 1
---

**A request can fail in two ways, and `HttpClient` reports both as an `HttpErrorResponse`.** The
server can answer with an error status, 400, 404 or 500, and a body saying why; or there can be no
answer at all, because the server is down or the network is, and then the status is 0, or, through
the dev server's proxy, a 500 the proxy made up. Either way the request's Observable ends with an
error instead of a value.

Reading already handles it. The resource goes into its error state, and lesson 6's templates show
the message. Stop the API with `Ctrl-C` in its terminal, and load the page:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-week --network
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /api/planner  500
[error] Failed to load resource: the server responded with a status of 500 (Internal Server Error)
This week

2026-10-19 to 2026-10-25

The week could not be loaded: Http failure response for http://localhost:4200/api/planner: 500 Internal Server Error
```

The dev server's terminal says what happened behind that 500, in two lines:
`[vite] http proxy error: /api/planner` and `Error: connect ECONNREFUSED 127.0.0.1:3000`. The proxy
tried port 3000, nothing was listening, and it answered the browser with a status of its own.

## A write that fails

Writing is the harder case, because the page has already said yes. Start the API again with
`node server/api.mjs`, and this time let the page load and then stop the API before ticking.
`--do 'wait 5000'` gives five seconds to press `Ctrl-C` in the API's terminal. `--a11y` shows the box's
state as a screen reader would hear it, `checked` or not:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --a11y app-course-page --do 'wait 5000' --do 'check 2026-10-24, 50 minutes'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- wait 5000
-- check 2026-10-24, 50 minutes
[error] Failed to load resource: the server responded with a status of 500 (Internal Server Error)
[error] HttpErrorResponse
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

The `PATCH` failed, and the box stayed ticked. The page says the session is done and the server
never heard about it: reload, and the tick is gone. The error itself reached the console, as
`HttpErrorResponse`, because nobody handled it; a person looking at the page sees nothing. **An optimistic update has to be undone when the server refuses it**, and the person
has to be told.

`subscribe` takes an object with an `error` callback. The store puts the session back and keeps a
message, in a signal the course page can show:

```schooling-example
{"language": "typescript", "file": "src/app/planner-store.ts", "parts": [
 {"code": "// src/app/planner-store.ts\nimport { HttpClient, HttpErrorResponse, httpResource } from '@angular/common/http';\nimport { Injectable, computed, inject, signal } from '@angular/core';\nimport { Session, isoDay, parsePlanner, totals, weekOf } from './planner';\nimport { TODAY } from './today';\n\n@Injectable({\n  providedIn: 'root',\n})\nexport class PlannerStore {\n  private readonly http = inject(HttpClient);\n  private readonly data = httpResource(() => '/api/planner', { parse: parsePlanner });\n\n  readonly isLoading = this.data.isLoading;\n  readonly error = this.data.error;\n  readonly courses = computed(() => (this.data.hasValue() ? this.data.value().courses : []));\n  readonly sessions = computed(() => (this.data.hasValue() ? this.data.value().sessions : []));\n  readonly week = weekOf(isoDay(inject(TODAY)));\n  readonly weekTotals = computed(() => totals(this.sessions(), this.week));\n  readonly saveError = signal<string | null>(null);\n\n  minutesThisWeek(courseId: string): number {\n    return totals(this.sessions().filter((s) => s.courseId === courseId), this.week).planned;\n  }", "note": "`HttpErrorResponse` is the type of what a failed request reports, and `signal` holds the message."},
 {"code": "  toggle(id: number, done: boolean): void {\n    this.saveError.set(null);\n    this.setDone(id, done);\n    this.http.patch<Session>(`/api/sessions/${id}`, { done }).subscribe({\n      error: (error: HttpErrorResponse) => {\n        this.setDone(id, !done);\n        this.saveError.set(`Session ${id} was not saved: ${error.error?.error ?? error.statusText}`);\n      },\n    });\n  }", "note": "The tick shows at once, as before. If the server refuses, the session goes back and the message says why: the server's own sentence when it sent one, the status text when there was nobody to send it."},
 {"code": "  private setDone(id: number, done: boolean): void {\n    this.data.update((data) =>\n      data && { ...data, sessions: data.sessions.map((s) => (s.id === id ? { ...s, done } : s)) },\n    );\n  }\n}", "note": "The change to the copy, now made in two places, is a private method of its own."}
]}
```

The course page shows the message above its list. `role="alert"` makes a screen reader announce
it the moment it appears, which matters here: the box a person just ticked has unticked itself, and
somebody who cannot see that needs to hear why.

```html
<!-- src/app/course-page/course-page.html -->
@if (store.isLoading()) {
  <p>Loading the course…</p>
} @else if (store.error(); as error) {
  <p>The course could not be loaded: {{ error.message }}</p>
} @else if (course(); as course) {
  <h2>{{ course.name }}</h2>
  @if (store.saveError(); as message) {
    <p role="alert">{{ message }}</p>
  }
  <app-session-list [sessions]="sessions()" (toggled)="store.toggle($event.id, $event.done)" />
} @else {
  <p>There is no course called {{ courseId() }}.</p>
}
```

Start the API, and the same five seconds and the same `Ctrl-C`:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --a11y app-course-page --do 'wait 5000' --do 'check 2026-10-24, 50 minutes'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- wait 5000
-- check 2026-10-24, 50 minutes
[error] Failed to load resource: the server responded with a status of 500 (Internal Server Error)
- heading "JavaScript" [level=2]
- alert
  - text: Session 5 was not saved: Internal Server Error
- list
  - listitem [level=1]
    - ListMarker "• "
    - checkbox " 2026-10-13, 45 minutes" [checked]
  - listitem [level=1]
    - ListMarker "• "
    - checkbox " 2026-10-20, 60 minutes" [checked]
  - listitem [level=1]
    - ListMarker "• "
    - checkbox " 2026-10-24, 50 minutes" [focused]
```

The box is unticked, and the page says why. "Internal Server Error" is the proxy's, because the API
was not there to say anything; with the API up and refusing, the message would be its own sentence,
`done must be true or false` or `there is no session 9`.

**Not every failure deserves a retry, and none deserves silence.** A 400 will fail the same way
every time, so retrying it is noise. A network failure may not, and lesson 13 retries those with
one RxJS operator. What no failure may do is leave the page saying something the server does not
believe.

With the API running again, the planner is committed:

```
ana@dev:~/planner$ git add -A && git commit -q -m "HttpClient: the planner talks to its own API"
```
