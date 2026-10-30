---
title: Submitting, and waiting for the server
version: 1
---

**A form is submitted with `(ngSubmit)` on the `<form>`, which Angular fires when the form is
submitted and stops the browser's own submission, the one that would reload the page.** Pressing
Enter in a field submits as well as clicking a `type="submit"` button does, which is half the reason
to use a real `<form>` and a real submit button: keyboards and screen readers already know what they
mean.

The store gets the method lesson 11 promised. Unlike `toggle`, it is not optimistic: a new session
has no id until the server gives it one, so the store waits for the answer and adds the session the
server sent back. It returns the Observable rather than subscribing to it, so whoever calls it can
know when it has finished:

```schooling-example
{"language": "typescript", "file": "src/app/planner-store.ts", "parts": [
 {"code": "// src/app/planner-store.ts\nimport { HttpClient, HttpErrorResponse, httpResource } from '@angular/common/http';\nimport { Injectable, computed, inject, signal } from '@angular/core';\nimport { Observable, retry, tap, throwError, timer } from 'rxjs';\nimport { Session, isoDay, parsePlanner, totals, weekOf } from './planner';\nimport { TODAY } from './today';\n\nconst transient = (error: HttpErrorResponse) => error.status === 0 || error.status >= 500;\n\n@Injectable({\n  providedIn: 'root',\n})\nexport class PlannerStore {\n  private readonly http = inject(HttpClient);\n  private readonly data = httpResource(() => '/api/planner', { parse: parsePlanner });\n\n  readonly isLoading = this.data.isLoading;\n  readonly error = this.data.error;\n  readonly courses = computed(() => (this.data.hasValue() ? this.data.value().courses : []));\n  readonly sessions = computed(() => (this.data.hasValue() ? this.data.value().sessions : []));\n  readonly week = weekOf(isoDay(inject(TODAY)));\n  readonly weekTotals = computed(() => totals(this.sessions(), this.week));\n  readonly saveError = signal<string | null>(null);\n\n  minutesThisWeek(courseId: string): number {\n    return totals(this.sessions().filter((s) => s.courseId === courseId), this.week).planned;\n  }\n\n  toggle(id: number, done: boolean): void {\n    this.saveError.set(null);\n    this.setDone(id, done);\n    this.http\n      .patch<Session>(`/api/sessions/${id}`, { done })\n      .pipe(retry({ count: 3, delay: (error: HttpErrorResponse) => (transient(error) ? timer(2000) : throwError(() => error)) }))\n      .subscribe({\n        error: (error: HttpErrorResponse) => {\n          this.setDone(id, !done);\n          this.saveError.set(`Session ${id} was not saved: ${error.error?.error ?? error.statusText}`);\n        },\n      });\n  }", "note": "`Observable` for the return type, and `tap`, which runs for each value and passes it on."},
 {"code": "  add(draft: Omit<Session, 'id' | 'done'>): Observable<Session> {\n    return this.http.post<Session>('/api/sessions', draft).pipe(\n      tap((session) => this.data.update((data) => data && { ...data, sessions: [...data.sessions, session] })),\n    );\n  }", "note": "What the caller sends is a session without the two fields the server decides. The session added to the copy is the one in the answer, id and all. No `retry`: lesson 13 said why."},
 {"code": "  private setDone(id: number, done: boolean): void {\n    this.data.update((data) =>\n      data && { ...data, sessions: data.sessions.map((s) => (s.id === id ? { ...s, done } : s)) },\n    );\n  }\n}"}
]}
```

The form needs to know which course it adds to, so it takes the id as an input, and it subscribes
to `add` to reset itself when the server has said yes:

```schooling-example
{"language": "typescript", "file": "src/app/add-session/add-session.ts", "parts": [
 {"code": "import { HttpErrorResponse } from '@angular/common/http';\nimport { ChangeDetectionStrategy, Component, inject, input, signal } from '@angular/core';\nimport { FormControl, FormGroup, ReactiveFormsModule } from '@angular/forms';\nimport { PlannerStore } from '../planner-store';\n\n@Component({\n  selector: 'app-add-session',\n  imports: [ReactiveFormsModule],"},
 {"code": "  template: `\n    <form [formGroup]=\"form\" (ngSubmit)=\"submit()\">\n      <h3>Add a session</h3>\n      <label for=\"date\">Date</label>\n      <input id=\"date\" type=\"date\" formControlName=\"date\" />\n      <label for=\"minutes\">Minutes</label>\n      <input id=\"minutes\" type=\"number\" formControlName=\"minutes\" />\n      <button type=\"submit\">Add</button>\n      @if (error(); as message) {\n        <p role=\"alert\">{{ message }}</p>\n      }\n    </form>\n  `,\n  styles: `\n    form {\n      display: grid;\n      gap: 0.5rem;\n      max-width: 20rem;\n    }\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class AddSession {\n  readonly courseId = input.required<string>();\n  private readonly store = inject(PlannerStore);\n  protected readonly error = signal<string | null>(null);\n  protected readonly form = new FormGroup({\n    date: new FormControl('', { nonNullable: true }),\n    minutes: new FormControl(30, { nonNullable: true }),\n  });", "note": "`(ngSubmit)` on the form, a submit button inside it, and the server's refusal in an alert, as lesson 12 did for a save."},
 {"code": "  protected submit(): void {\n    this.error.set(null);\n    this.store.add({ courseId: this.courseId(), ...this.form.getRawValue() }).subscribe({\n      next: () => this.form.reset(),\n      error: (error: HttpErrorResponse) => this.error.set(`Not added: ${error.error?.error ?? error.statusText}`),\n    });\n  }\n}", "note": "`getRawValue()` is `{ date, minutes }`, typed in full, and the spread puts the course beside it. `reset()` puts both controls back to their first values, because they are `nonNullable`."}
]}
```

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
  <app-add-session [courseId]="course.id" />
} @else {
  <p>There is no course called {{ courseId() }}.</p>
}
```

A session on Monday the 26th, for 40 minutes:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-course-page --do 'fill Date = 2026-10-26' --do 'fill Minutes = 40' --do 'click Add'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Date = 2026-10-26
-- fill Minutes = 40
-- click Add
JavaScript
 2026-10-13, 45 minutes
 2026-10-20, 60 minutes
 2026-10-24, 50 minutes
 2026-10-26, 40 minutes
Add a session
Date
Minutes
Add
```

The new session is in the list, in date order, because `CoursePage` sorts what the store has, and
the store now has it. The API's terminal has the `POST`, and a reload would show it again from
`planner.json`. Now the same button with no date:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-course-page --do 'click Add'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Add
[error] Failed to load resource: the server responded with a status of 400 (Bad Request)
JavaScript
 2026-10-13, 45 minutes
 2026-10-20, 60 minutes
 2026-10-24, 50 minutes
 2026-10-26, 40 minutes
Add a session
Date
Minutes
Add

Not added: date must be YYYY-MM-DD
```

The form sent an empty date, and the server refused it in its own words. That is the server doing
its job, and the form not doing its own: nothing told the person the date was missing until a
request had crossed the network and come back. Lesson 15 checks the fields before anything is
sent, and keeps the server's check, which is the one that cannot be skipped.
