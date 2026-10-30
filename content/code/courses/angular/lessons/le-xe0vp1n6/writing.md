---
title: Writing back
version: 1
---

**Reading is a resource; writing is a request you make when something happens.** `http.patch`
builds one: a method, a URL and a body, here `{ done }`. What it returns is an **Observable**, the
type lesson 13 is about, and an Observable does nothing until somebody subscribes to it. A request
nobody subscribes to is never sent, which is the commonest way to write one that silently does
nothing.

`toggle` keeps changing the store's copy at once, so the box ticks the moment it is clicked, and now
tells the server too:

```typescript
// src/app/planner-store.ts
import { HttpClient, httpResource } from '@angular/common/http';
import { Injectable, computed, inject } from '@angular/core';
import { Session, isoDay, parsePlanner, totals, weekOf } from './planner';
import { TODAY } from './today';

@Injectable({
  providedIn: 'root',
})
export class PlannerStore {
  private readonly http = inject(HttpClient);
  private readonly data = httpResource(() => '/api/planner', { parse: parsePlanner });

  readonly isLoading = this.data.isLoading;
  readonly error = this.data.error;
  readonly courses = computed(() => (this.data.hasValue() ? this.data.value().courses : []));
  readonly sessions = computed(() => (this.data.hasValue() ? this.data.value().sessions : []));
  readonly week = weekOf(isoDay(inject(TODAY)));
  readonly weekTotals = computed(() => totals(this.sessions(), this.week));

  minutesThisWeek(courseId: string): number {
    return totals(this.sessions().filter((s) => s.courseId === courseId), this.week).planned;
  }

  toggle(id: number, done: boolean): void {
    this.data.update((data) =>
      data && { ...data, sessions: data.sessions.map((s) => (s.id === id ? { ...s, done } : s)) },
    );
    this.http.patch<Session>(`/api/sessions/${id}`, { done }).subscribe();
  }
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-week-summary --network --do 'check 2026-10-24, 50 minutes'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /api/planner  200
-- check 2026-10-24, 50 minutes
net  PATCH /api/sessions/5  200
165 minutes planned, 140 done.

25 minutes to go.

Done this week
```

The `PATCH` went out after the tick, and the server answered 200. The real test is a fresh page,
which knows nothing the last one did:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-week-summary
[vite] connecting...
[vite] connected.
Angular is running in development mode.
165 minutes planned, 140 done.

25 minutes to go.

Done this week
```

**140 minutes done, on a page that loaded it from the server.** The tick outlived the page for the
first time in this course. `CoursePage` and `Week` did not change: lesson 11 put every change to a
session behind `toggle`, so there was one place to teach about the server.

Changing the copy first and telling the server second is called an **optimistic** update. It makes
the page feel instant, and it makes a promise the server may not keep; the last section of this
lesson deals with the server saying no. `curl` sets session 5 back, for the sections after this one:

```
ana@dev:~/planner$ curl -s -X PATCH http://localhost:3000/api/sessions/5 -d '{"done":false}'; echo
{"id":5,"courseId":"javascript","date":"2026-10-24","minutes":50,"done":false}
```
