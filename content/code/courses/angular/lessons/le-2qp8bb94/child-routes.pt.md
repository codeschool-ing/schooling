---
title: Rotas filhas, uma página com partes próprias
version: 1
---

**Uma rota filha é uma rota dentro do componente de outra rota.** O pai desenha o que todo filho
compartilha, e o próprio `<router-outlet>` dele desenha o filho que o endereço nomeia. A página do
curso tem duas partes que não precisam estar na tela juntas, as sessões e o formulário para
acrescentar mais, então cada uma ganha um endereço: `/courses/javascript` para as sessões,
`/courses/javascript/add` para o formulário.

As sessões saem do `CoursePage` para um componente próprio, com a mensagem de salvamento que é delas:

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

O `CoursePage` fica com o que as duas partes compartilham: o nome do curso, os minutos dele na semana,
que o store calcula desde a aula 11, e uma navegação entre as duas partes. O `routerLink="."` é a
própria rota, e o `"add"`, sem barra, é relativo a ela:

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

As rotas aninham as duas sob o curso:

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

Os filhos não têm um `:courseId` próprio, e mesmo assim os dois têm um input `courseId`. Por padrão um
filho só herda os parâmetros do pai quando o próprio caminho é vazio, então as sessões receberiam um e
o formulário em `add` não. O `paramsInheritanceStrategy: 'always'` faz todo filho ver todo parâmetro
acima dele, e o input binding define o `courseId` nos dois:

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

O formulário volta para as sessões quando terminou de acrescentá-las:

```schooling-example
{"language": "typescript", "file": "src/app/add-session/add-session.ts", "parts": [
 {"code": "// src/app/add-session/add-session.ts\nimport { HttpClient, HttpErrorResponse } from '@angular/common/http';\nimport { ChangeDetectionStrategy, Component, ElementRef, inject, input, signal } from '@angular/core';\nimport { AbstractControl, AsyncValidatorFn, NonNullableFormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';\nimport { ActivatedRoute, Router } from '@angular/router';\nimport { concatMap, filter, from, map, take } from 'rxjs';\nimport { PlannerData, isoDay } from '../planner';\nimport { PlannerStore } from '../planner-store';\nimport { TODAY } from '../today';\nimport { distinctDates, notBefore } from '../validators';\n\nconst MESSAGES: Record<string, string> = {\n  required: 'This is needed.',\n  min: 'At least 5 minutes.',\n  max: 'At most 480 minutes.',\n  past: 'That day has already gone.',\n  taken: 'This course already has a session that day.',\n};", "note": "O `Router` navega a partir do código; o `ActivatedRoute` é a rota para a qual este componente foi desenhado, então um caminho pode ser relativo a ela."},
 {"code": "@Component({\n  selector: 'app-add-session',\n  imports: [ReactiveFormsModule],\n  template: `\n    <form [formGroup]=\"form\" (ngSubmit)=\"submit()\">\n      <h3>Add sessions</h3>\n      <div formArrayName=\"dates\">\n        @for (date of form.controls.dates.controls; track date; let i = $index) {\n          <label [for]=\"'date-' + i\">Date {{ i + 1 }}</label>\n          <input\n            [id]=\"'date-' + i\"\n            type=\"date\"\n            [formControlName]=\"i\"\n            [aria-invalid]=\"shows(date)\"\n            [aria-describedby]=\"shows(date) ? 'date-' + i + '-error' : null\"\n          />\n          @if (shows(date)) {\n            <p [id]=\"'date-' + i + '-error'\">{{ messageFor(date) }}</p>\n          }\n          @if (form.controls.dates.length > 1) {\n            <button type=\"button\" (click)=\"form.controls.dates.removeAt(i)\">Remove date {{ i + 1 }}</button>\n          }\n        }\n        @if (shows(form.controls.dates) && form.controls.dates.hasError('repeated')) {\n          <p>Two of the dates are the same day.</p>\n        }\n      </div>\n      <button type=\"button\" (click)=\"addDate()\">Another date</button>\n      <label for=\"minutes\">Minutes</label>\n      <input\n        id=\"minutes\"\n        type=\"number\"\n        formControlName=\"minutes\"\n        [aria-invalid]=\"shows(form.controls.minutes)\"\n        [aria-describedby]=\"shows(form.controls.minutes) ? 'minutes-error' : null\"\n      />\n      @if (shows(form.controls.minutes)) {\n        <p id=\"minutes-error\">{{ messageFor(form.controls.minutes) }}</p>\n      }\n      <button type=\"submit\">Add</button>\n      @if (error(); as message) {\n        <p role=\"alert\">{{ message }}</p>\n      }\n    </form>\n  `,\n  styles: `\n    form,\n    div {\n      display: grid;\n      gap: 0.5rem;\n      max-width: 20rem;\n    }\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class AddSession {\n  readonly courseId = input.required<string>();\n  private readonly store = inject(PlannerStore);\n  private readonly http = inject(HttpClient);\n  private readonly fb = inject(NonNullableFormBuilder);\n  private readonly host: ElementRef<HTMLElement> = inject(ElementRef);\n  private readonly router = inject(Router);\n  private readonly route = inject(ActivatedRoute);\n  private readonly today = isoDay(inject(TODAY));\n  protected readonly error = signal<string | null>(null);\n  protected readonly submitted = signal(false);\n\n  private readonly freeDay: AsyncValidatorFn = (control) =>\n    this.http\n      .get<PlannerData>('/api/planner')\n      .pipe(\n        map((data) =>\n          data.sessions.some((s) => s.courseId === this.courseId() && s.date === control.value) ? { taken: true } : null,\n        ),\n      );\n\n  protected readonly form = this.fb.group({\n    dates: this.fb.array([this.dateControl()], { validators: distinctDates }),\n    minutes: this.fb.control(30, { validators: [Validators.required, Validators.min(5), Validators.max(480)] }),\n  });\n\n  protected shows(control: AbstractControl): boolean {\n    return control.invalid && (control.touched || this.submitted());\n  }\n\n  protected messageFor(control: AbstractControl): string {\n    const first = Object.keys(control.errors ?? {})[0];\n    return MESSAGES[first] ?? first;\n  }\n\n  protected addDate(): void {\n    this.form.controls.dates.push(this.dateControl());\n  }"},
 {"code": "  protected submit(): void {\n    this.submitted.set(true);\n    if (this.form.pending) {\n      this.form.statusChanges.pipe(filter((status) => status !== 'PENDING'), take(1)).subscribe(() => this.submit());\n      return;\n    }\n    if (this.form.invalid) {\n      this.focusFirstProblem();\n      return;\n    }\n    this.error.set(null);\n    const { dates, minutes } = this.form.getRawValue();\n    from(dates)\n      .pipe(concatMap((date) => this.store.add({ courseId: this.courseId(), date, minutes })))\n      .subscribe({\n        complete: () => this.router.navigate(['..'], { relativeTo: this.route }),\n        error: (error: HttpErrorResponse) => this.error.set(`Not added: ${error.error?.error ?? error.statusText}`),\n      });\n  }\n\n  private dateControl() {\n    return this.fb.control('', {\n      validators: [Validators.required, notBefore(this.today)],\n      asyncValidators: this.freeDay,\n      updateOn: 'blur',\n    });\n  }\n\n  private focusFirstProblem(): void {\n    const { dates, minutes } = this.form.controls;\n    const i = dates.controls.findIndex((date) => date.invalid);\n    const id = i >= 0 ? `date-${i}` : dates.invalid ? 'date-0' : minutes.invalid ? 'minutes' : null;\n    if (id) this.host.nativeElement.querySelector<HTMLElement>(`#${id}`)?.focus();\n  }\n}", "note": "Quando toda sessão foi acrescentada, o formulário volta para as sessões do curso: `..` a partir de `courses/javascript/add` é `courses/javascript`. O formulário é destruído no caminho, então o `startAgain` da aula 15 não tem mais o que fazer e sai."}
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

O formulário abriu no próprio endereço, sob o título do curso. Depois dos `POST`s o router levou a
página de volta às sessões, que já tinham a nova, porque o store a acrescentou antes da navegação.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas caixas aninhadas para o endereço /courses/javascript/add. A caixa de fora é o App, com o título, a navegação e um router-outlet. Dentro desse outlet está o CoursePage, desenhado para courses/:courseId, com o nome do curso, os minutos da semana, a própria navegação e um router-outlet. Dentro desse está o AddSession, desenhado para o caminho filho add. Ao lado de cada outlet, a parte do endereço que escolheu o que o preenche.\"><text x=\"360\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/courses/javascript/add</text><rect x=\"30\" y=\"34\" width=\"460\" height=\"254\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">App</text><text x=\"44\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">título, navegação</text><rect x=\"50\" y=\"84\" width=\"420\" height=\"192\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"62\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">&lt;router-outlet&gt;</text><text x=\"62\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CoursePage</text><text x=\"62\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nome, minutos da semana, Sessions | Add sessions</text><rect x=\"72\" y=\"150\" width=\"376\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"84\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">&lt;router-outlet&gt;</text><text x=\"84\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">AddSession</text><text x=\"84\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o formulário</text><line x1=\"470\" y1=\"116\" x2=\"520\" y2=\"116\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><text x=\"528\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">courses/:courseId</text><text x=\"528\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">javascript → o input</text><line x1=\"448\" y1=\"184\" x2=\"520\" y2=\"184\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><text x=\"528\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">add</text><text x=\"528\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma rota filha</text></svg>", "caption": "Cada outlet é preenchido pela rota que casou com a parte dele do endereço; o componente de uma rota filha fica no outlet do pai."}
```
