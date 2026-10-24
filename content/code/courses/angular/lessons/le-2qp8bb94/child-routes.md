---
title: Child routes, a page with parts of its own
version: 1
---

**A child route is a route inside another route's component.** The parent draws what every child
shares, and its own `<router-outlet>` draws the child the address names. The course page has two
parts that do not need to be on screen together, its sessions and the form for adding more, so each
gets an address: `/courses/javascript` for the sessions, `/courses/javascript/add` for the form.

The sessions move out of `CoursePage` into a component of their own, with the save message that
belongs to them:

```
ana@dev:~/planner$ npx ng generate component course-sessions --inline-template --inline-style --skip-tests
CREATE src/app/course-sessions/course-sessions.ts (298 bytes)
```

```typescript
// src/app/course-sessions/course-sessions.ts
import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { PlannerStore } from '../planner-store';
import { SessionList } from '../session-list/session-list';

@Component({
  selector: 'app-course-sessions',
  imports: [SessionList],
  template: `
    @if (store.saveError(); as message) {
      <p role="alert">{{ message }}</p>
    }
    <app-session-list [sessions]="sessions()" (toggled)="store.toggle($event.id, $event.done)" />
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CourseSessions {
  readonly courseId = input.required<string>();
  protected readonly store = inject(PlannerStore);
  protected readonly sessions = computed(() =>
    this.store
      .sessions()
      .filter((s) => s.courseId === this.courseId())
      .sort((a, b) => a.date.localeCompare(b.date)),
  );
}
```

`CoursePage` keeps what both parts share: the course's name, its minutes this week, which the store
has worked out since lesson 11, and a navigation between the two parts. `routerLink="."` is this
route itself, and `"add"`, with no slash, is relative to it:

```typescript
// src/app/course-page/course-page.ts
import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { PlannerStore } from '../planner-store';

@Component({
  selector: 'app-course-page',
  imports: [RouterLink, RouterLinkActive, RouterOutlet],
  templateUrl: './course-page.html',
  styleUrl: './course-page.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CoursePage {
  readonly courseId = input.required<string>();
  protected readonly store = inject(PlannerStore);
  protected readonly course = computed(() => this.store.courses().find((c) => c.id === this.courseId()));
}
```

```html
<!-- src/app/course-page/course-page.html -->
@if (store.isLoading()) {
  <p>Loading the course…</p>
} @else if (store.error(); as error) {
  <p>The course could not be loaded: {{ error.message }}</p>
} @else if (course(); as course) {
  <h2>{{ course.name }}</h2>
  <p>{{ store.minutesThisWeek(course.id) }} minutes planned this week.</p>
  <nav aria-label="Course">
    <a routerLink="." routerLinkActive="current" [routerLinkActiveOptions]="{ exact: true }" ariaCurrentWhenActive="page">Sessions</a>
    <a routerLink="add" routerLinkActive="current" ariaCurrentWhenActive="page">Add sessions</a>
  </nav>
  <router-outlet />
} @else {
  <p>There is no course called {{ courseId() }}.</p>
}
```

```css
/* src/app/course-page/course-page.css */
nav {
  display: flex;
  gap: 1rem;
}
```

The routes nest the two under the course:

```typescript
// src/app/app.routes.ts
import { Routes } from '@angular/router';
import { AddSession } from './add-session/add-session';
import { CoursePage } from './course-page/course-page';
import { CourseSessions } from './course-sessions/course-sessions';
import { NotFound } from './not-found/not-found';
import { Week } from './week/week';

export const routes: Routes = [
  { path: '', component: Week },
  {
    path: 'courses/:courseId',
    component: CoursePage,
    children: [
      { path: '', component: CourseSessions },
      { path: 'add', component: AddSession },
    ],
  },
  { path: '**', component: NotFound },
];
```

The children have no `:courseId` of their own, yet both have a `courseId` input. By default a child
inherits its parent's parameters only when its own path is empty, so the sessions would get one and
the form at `add` would not. `paramsInheritanceStrategy: 'always'` makes every child see every
parameter above it, and input binding sets `courseId` on both:

```typescript
// src/app/app.config.ts
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter, withComponentInputBinding, withRouterConfig } from '@angular/router';

import { routes } from './app.routes';
import { requestedBy } from './requested-by';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes, withComponentInputBinding(), withRouterConfig({ paramsInheritanceStrategy: 'always' })),
    provideHttpClient(withInterceptors([requestedBy])),
  ]
};
```

The form goes back to the sessions when it has added them:

```schooling-example
{"language": "typescript", "file": "src/app/add-session/add-session.ts", "parts": [
 {"code": "// src/app/add-session/add-session.ts\nimport { HttpClient, HttpErrorResponse } from '@angular/common/http';\nimport { ChangeDetectionStrategy, Component, ElementRef, inject, input, signal } from '@angular/core';\nimport { AbstractControl, AsyncValidatorFn, NonNullableFormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';\nimport { ActivatedRoute, Router } from '@angular/router';\nimport { concatMap, filter, from, map, take } from 'rxjs';\nimport { PlannerData, isoDay } from '../planner';\nimport { PlannerStore } from '../planner-store';\nimport { TODAY } from '../today';\nimport { distinctDates, notBefore } from '../validators';\n\nconst MESSAGES: Record<string, string> = {\n  required: 'This is needed.',\n  min: 'At least 5 minutes.',\n  max: 'At most 480 minutes.',\n  past: 'That day has already gone.',\n  taken: 'This course already has a session that day.',\n};", "note": "`Router` navigates from code; `ActivatedRoute` is the route this component was drawn for, so a path can be relative to it."},
 {"code": "@Component({\n  selector: 'app-add-session',\n  imports: [ReactiveFormsModule],\n  template: `\n    <form [formGroup]=\"form\" (ngSubmit)=\"submit()\">\n      <h3>Add sessions</h3>\n      <div formArrayName=\"dates\">\n        @for (date of form.controls.dates.controls; track date; let i = $index) {\n          <label [for]=\"'date-' + i\">Date {{ i + 1 }}</label>\n          <input\n            [id]=\"'date-' + i\"\n            type=\"date\"\n            [formControlName]=\"i\"\n            [aria-invalid]=\"shows(date)\"\n            [aria-describedby]=\"shows(date) ? 'date-' + i + '-error' : null\"\n          />\n          @if (shows(date)) {\n            <p [id]=\"'date-' + i + '-error'\">{{ messageFor(date) }}</p>\n          }\n          @if (form.controls.dates.length > 1) {\n            <button type=\"button\" (click)=\"form.controls.dates.removeAt(i)\">Remove date {{ i + 1 }}</button>\n          }\n        }\n        @if (shows(form.controls.dates) && form.controls.dates.hasError('repeated')) {\n          <p>Two of the dates are the same day.</p>\n        }\n      </div>\n      <button type=\"button\" (click)=\"addDate()\">Another date</button>\n      <label for=\"minutes\">Minutes</label>\n      <input\n        id=\"minutes\"\n        type=\"number\"\n        formControlName=\"minutes\"\n        [aria-invalid]=\"shows(form.controls.minutes)\"\n        [aria-describedby]=\"shows(form.controls.minutes) ? 'minutes-error' : null\"\n      />\n      @if (shows(form.controls.minutes)) {\n        <p id=\"minutes-error\">{{ messageFor(form.controls.minutes) }}</p>\n      }\n      <button type=\"submit\">Add</button>\n      @if (error(); as message) {\n        <p role=\"alert\">{{ message }}</p>\n      }\n    </form>\n  `,\n  styles: `\n    form,\n    div {\n      display: grid;\n      gap: 0.5rem;\n      max-width: 20rem;\n    }\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class AddSession {\n  readonly courseId = input.required<string>();\n  private readonly store = inject(PlannerStore);\n  private readonly http = inject(HttpClient);\n  private readonly fb = inject(NonNullableFormBuilder);\n  private readonly host: ElementRef<HTMLElement> = inject(ElementRef);\n  private readonly router = inject(Router);\n  private readonly route = inject(ActivatedRoute);\n  private readonly today = isoDay(inject(TODAY));\n  protected readonly error = signal<string | null>(null);\n  protected readonly submitted = signal(false);\n\n  private readonly freeDay: AsyncValidatorFn = (control) =>\n    this.http\n      .get<PlannerData>('/api/planner')\n      .pipe(\n        map((data) =>\n          data.sessions.some((s) => s.courseId === this.courseId() && s.date === control.value) ? { taken: true } : null,\n        ),\n      );\n\n  protected readonly form = this.fb.group({\n    dates: this.fb.array([this.dateControl()], { validators: distinctDates }),\n    minutes: this.fb.control(30, { validators: [Validators.required, Validators.min(5), Validators.max(480)] }),\n  });\n\n  protected shows(control: AbstractControl): boolean {\n    return control.invalid && (control.touched || this.submitted());\n  }\n\n  protected messageFor(control: AbstractControl): string {\n    const first = Object.keys(control.errors ?? {})[0];\n    return MESSAGES[first] ?? first;\n  }\n\n  protected addDate(): void {\n    this.form.controls.dates.push(this.dateControl());\n  }"},
 {"code": "  protected submit(): void {\n    this.submitted.set(true);\n    if (this.form.pending) {\n      this.form.statusChanges.pipe(filter((status) => status !== 'PENDING'), take(1)).subscribe(() => this.submit());\n      return;\n    }\n    if (this.form.invalid) {\n      this.focusFirstProblem();\n      return;\n    }\n    this.error.set(null);\n    const { dates, minutes } = this.form.getRawValue();\n    from(dates)\n      .pipe(concatMap((date) => this.store.add({ courseId: this.courseId(), date, minutes })))\n      .subscribe({\n        complete: () => this.router.navigate(['..'], { relativeTo: this.route }),\n        error: (error: HttpErrorResponse) => this.error.set(`Not added: ${error.error?.error ?? error.statusText}`),\n      });\n  }\n\n  private dateControl() {\n    return this.fb.control('', {\n      validators: [Validators.required, notBefore(this.today)],\n      asyncValidators: this.freeDay,\n      updateOn: 'blur',\n    });\n  }\n\n  private focusFirstProblem(): void {\n    const { dates, minutes } = this.form.controls;\n    const i = dates.controls.findIndex((date) => date.invalid);\n    const id = i >= 0 ? `date-${i}` : dates.invalid ? 'date-0' : minutes.invalid ? 'minutes' : null;\n    if (id) this.host.nativeElement.querySelector<HTMLElement>(`#${id}`)?.focus();\n  }\n}", "note": "When every session is added, the form goes back to the course's sessions: `..` from `courses/javascript/add` is `courses/javascript`. The form is destroyed on the way, so lesson 15's `startAgain` has nothing left to do and goes."}
]}
```

```
ana@dev:~/planner$ look http://localhost:4200/courses/javascript --today 2026-10-23 --text main --do 'click Add sessions' --url
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Add sessions
url: /courses/javascript/add
JavaScript

110 minutes planned this week.

Sessions
Add sessions
Add sessions
Date 1
Another date
Minutes
Add
```

```
ana@dev:~/planner$ look http://localhost:4200/courses/javascript/add --today 2026-10-23 --text main --do 'fill Date 1 = 2026-10-26' --do 'click Add' --url
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Date 1 = 2026-10-26
-- click Add
url: /courses/javascript
JavaScript

110 minutes planned this week.

Sessions
Add sessions
 2026-10-13, 45 minutes
 2026-10-20, 60 minutes
 2026-10-24, 50 minutes
 2026-10-26, 30 minutes
```

The form opened at its own address, under the course's heading. After the `POST`s the router took
the page back to the sessions, which already had the new one, because the store had added it
before the navigation.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two nested boxes for the address /courses/javascript/add. The outer box is App, with its heading, its navigation and a router-outlet. Inside that outlet is CoursePage, drawn for courses/:courseId, with the course&#x27;s name, its minutes this week, its own navigation and a router-outlet. Inside that one is AddSession, drawn for the child path add. Beside each outlet, the part of the address that chose what fills it.\"><text x=\"360\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/courses/javascript/add</text><rect x=\"30\" y=\"34\" width=\"460\" height=\"254\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">App</text><text x=\"44\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">heading, navigation</text><rect x=\"50\" y=\"84\" width=\"420\" height=\"192\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"62\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">&lt;router-outlet&gt;</text><text x=\"62\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CoursePage</text><text x=\"62\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">name, minutes this week, Sessions | Add sessions</text><rect x=\"72\" y=\"150\" width=\"376\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"84\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">&lt;router-outlet&gt;</text><text x=\"84\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">AddSession</text><text x=\"84\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the form</text><line x1=\"470\" y1=\"116\" x2=\"520\" y2=\"116\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><text x=\"528\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">courses/:courseId</text><text x=\"528\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">javascript → the input</text><line x1=\"448\" y1=\"184\" x2=\"520\" y2=\"184\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><text x=\"528\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">add</text><text x=\"528\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a child route</text></svg>", "caption": "Each outlet is filled by the route that matched its part of the address; a child route's component sits in its parent's outlet."}
```
