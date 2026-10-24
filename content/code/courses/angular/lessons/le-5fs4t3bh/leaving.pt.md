---
title: Perguntando antes de uma página ser deixada
version: 1
---

**O `canDeactivate` é perguntado quando alguém está prestes a deixar uma rota, e é como uma aplicação
evita jogar trabalho fora.** Alguém no meio do formulário de acrescentar que clica em "Sessions" perde
o que digitou, sem uma palavra. Um guard na rota do formulário pode perguntar antes.

O guard não sabe de formulários. Ele pergunta ao componente se tem algo não salvo, por uma interface
que qualquer componente pode implementar, e só pergunta à pessoa se tiver:

```typescript
// src/app/unsaved-work.ts
import { CanDeactivateFn } from '@angular/router';

export interface MayHaveUnsavedWork {
  hasUnsavedWork(): boolean;
}

export const unsavedWork: CanDeactivateFn<MayHaveUnsavedWork> = (component) =>
  !component.hasUnsavedWork() || confirm('Leave this form? What you typed has not been added.');
```

O `confirm()` é o diálogo do próprio navegador: ele para tudo até ser respondido, e é lido por todo
leitor de tela. Um diálogo da própria aplicação poderia ser mais simpático, e teria de ser construído
para ser tão acessível; para uma pergunta tão curta, o do navegador é o certo.

O formulário responde a pergunta:

```schooling-example
{"language": "typescript", "file": "src/app/add-session/add-session.ts", "parts": [
 {"code": "// src/app/add-session/add-session.ts\nimport { HttpClient, HttpErrorResponse } from '@angular/common/http';\nimport { ChangeDetectionStrategy, Component, ElementRef, inject, input, signal } from '@angular/core';\nimport { AbstractControl, AsyncValidatorFn, NonNullableFormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';\nimport { ActivatedRoute, Router } from '@angular/router';\nimport { concatMap, filter, from, map, take } from 'rxjs';\nimport { PlannerData, isoDay } from '../planner';\nimport { PlannerStore } from '../planner-store';\nimport { TODAY } from '../today';\nimport { distinctDates, notBefore } from '../validators';\n\nconst MESSAGES: Record<string, string> = {\n  required: 'This is needed.',\n  min: 'At least 5 minutes.',\n  max: 'At most 480 minutes.',\n  past: 'That day has already gone.',\n  taken: 'This course already has a session that day.',\n};\n\n@Component({\n  selector: 'app-add-session',\n  imports: [ReactiveFormsModule],\n  template: `\n    <form [formGroup]=\"form\" (ngSubmit)=\"submit()\">\n      <h3>Add sessions</h3>\n      <div formArrayName=\"dates\">\n        @for (date of form.controls.dates.controls; track date; let i = $index) {\n          <label [for]=\"'date-' + i\">Date {{ i + 1 }}</label>\n          <input\n            [id]=\"'date-' + i\"\n            type=\"date\"\n            [formControlName]=\"i\"\n            [aria-invalid]=\"shows(date)\"\n            [aria-describedby]=\"shows(date) ? 'date-' + i + '-error' : null\"\n          />\n          @if (shows(date)) {\n            <p [id]=\"'date-' + i + '-error'\">{{ messageFor(date) }}</p>\n          }\n          @if (form.controls.dates.length > 1) {\n            <button type=\"button\" (click)=\"form.controls.dates.removeAt(i)\">Remove date {{ i + 1 }}</button>\n          }\n        }\n        @if (shows(form.controls.dates) && form.controls.dates.hasError('repeated')) {\n          <p>Two of the dates are the same day.</p>\n        }\n      </div>\n      <button type=\"button\" (click)=\"addDate()\">Another date</button>\n      <label for=\"minutes\">Minutes</label>\n      <input\n        id=\"minutes\"\n        type=\"number\"\n        formControlName=\"minutes\"\n        [aria-invalid]=\"shows(form.controls.minutes)\"\n        [aria-describedby]=\"shows(form.controls.minutes) ? 'minutes-error' : null\"\n      />\n      @if (shows(form.controls.minutes)) {\n        <p id=\"minutes-error\">{{ messageFor(form.controls.minutes) }}</p>\n      }\n      <button type=\"submit\">Add</button>\n      @if (error(); as message) {\n        <p role=\"alert\">{{ message }}</p>\n      }\n    </form>\n  `,\n  styles: `\n    form,\n    div {\n      display: grid;\n      gap: 0.5rem;\n      max-width: 20rem;\n    }\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class AddSession {\n  readonly courseId = input.required<string>();\n  private readonly store = inject(PlannerStore);\n  private readonly http = inject(HttpClient);\n  private readonly fb = inject(NonNullableFormBuilder);\n  private readonly host: ElementRef<HTMLElement> = inject(ElementRef);\n  private readonly router = inject(Router);\n  private readonly route = inject(ActivatedRoute);\n  private readonly today = isoDay(inject(TODAY));\n  protected readonly error = signal<string | null>(null);\n  protected readonly submitted = signal(false);\n\n  private readonly freeDay: AsyncValidatorFn = (control) =>\n    this.http\n      .get<PlannerData>('/api/planner')\n      .pipe(\n        map((data) =>\n          data.sessions.some((s) => s.courseId === this.courseId() && s.date === control.value) ? { taken: true } : null,\n        ),\n      );\n\n  protected readonly form = this.fb.group({\n    dates: this.fb.array([this.dateControl()], { validators: distinctDates }),\n    minutes: this.fb.control(30, { validators: [Validators.required, Validators.min(5), Validators.max(480)] }),\n  });"},
 {"code": "  hasUnsavedWork(): boolean {\n    return this.form.dirty;\n  }", "note": "A pergunta do guard. O `dirty` fica verdadeiro assim que algo é digitado no formulário."},
 {"code": "  protected shows(control: AbstractControl): boolean {\n    return control.invalid && (control.touched || this.submitted());\n  }\n\n  protected messageFor(control: AbstractControl): string {\n    const first = Object.keys(control.errors ?? {})[0];\n    return MESSAGES[first] ?? first;\n  }\n\n  protected addDate(): void {\n    this.form.controls.dates.push(this.dateControl());\n  }"},
 {"code": "  protected submit(): void {\n    this.submitted.set(true);\n    if (this.form.pending) {\n      this.form.statusChanges.pipe(filter((status) => status !== 'PENDING'), take(1)).subscribe(() => this.submit());\n      return;\n    }\n    if (this.form.invalid) {\n      this.focusFirstProblem();\n      return;\n    }\n    this.error.set(null);\n    const { dates, minutes } = this.form.getRawValue();\n    from(dates)\n      .pipe(concatMap((date) => this.store.add({ courseId: this.courseId(), date, minutes })))\n      .subscribe({\n        complete: () => {\n          this.form.markAsPristine();\n          this.router.navigate(['..'], { relativeTo: this.route });\n        },\n        error: (error: HttpErrorResponse) => this.error.set(`Not added: ${error.error?.error ?? error.statusText}`),\n      });\n  }", "note": "Antes de sair sozinho, depois de um envio bem-sucedido, o formulário diz que não tem nada não salvo, senão o próprio guard dele perguntaria."},
 {"code": "  private dateControl() {\n    return this.fb.control('', {\n      validators: [Validators.required, notBefore(this.today)],\n      asyncValidators: this.freeDay,\n      updateOn: 'blur',\n    });\n  }\n\n  private focusFirstProblem(): void {\n    const { dates, minutes } = this.form.controls;\n    const i = dates.controls.findIndex((date) => date.invalid);\n    const id = i >= 0 ? `date-${i}` : dates.invalid ? 'date-0' : minutes.invalid ? 'minutes' : null;\n    if (id) this.host.nativeElement.querySelector<HTMLElement>(`#${id}`)?.focus();\n  }\n}"}
]}
```

E a rota usa o guard:

```typescript
// src/app/app.routes.ts
import { Routes } from '@angular/router';
import { AddSession } from './add-session/add-session';
import { CoursePage } from './course-page/course-page';
import { CourseSessions } from './course-sessions/course-sessions';
import { courseExists } from './course-exists';
import { courseTitle } from './course-title';
import { NotFound } from './not-found/not-found';
import { unsavedWork } from './unsaved-work';
import { Week } from './week/week';

export const routes: Routes = [
  { path: '', component: Week, title: 'This week · Study planner' },
  {
    path: 'courses/:courseId',
    component: CoursePage,
    title: courseTitle,
    canActivate: [courseExists],
    children: [
      { path: '', component: CourseSessions },
      { path: 'add', component: AddSession, canDeactivate: [unsavedWork] },
    ],
  },
  { path: 'week', redirectTo: '' },
  { path: 'course/:courseId', redirectTo: 'courses/:courseId' },
  { path: '**', component: NotFound, title: 'Not found · Study planner' },
];
```

O `look` imprime um diálogo como `[dialog]` e responde não, como uma pessoa apertando Cancelar
faria; o `--accept` responde sim. Alguns minutos digitados, depois um clique em "Sessions":

```
ana@dev:~/planner$ look http://localhost:4200/courses/git/add --today 2026-10-23 --url --text h2 --do 'fill Minutes = 45' --do 'click Sessions'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Minutes = 45
-- click Sessions
[dialog] Leave this form? What you typed has not been added.
url: /courses/git/add
Git
```

```
ana@dev:~/planner$ look http://localhost:4200/courses/git/add --today 2026-10-23 --url --text h2 --accept --do 'fill Minutes = 45' --do 'click Sessions'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Minutes = 45
-- click Sessions
[dialog] Leave this form? What you typed has not been added.
url: /courses/git
Git
```

O Cancelar manteve a pessoa no formulário, com o que ela digitou; o OK a deixou sair. E um formulário
que fez o seu trabalho não pergunta nada, porque se marcou como intocado antes de navegar:

```
ana@dev:~/planner$ look http://localhost:4200/courses/git/add --today 2026-10-23 --url --text main --do 'fill Date 1 = 2026-10-27' --do 'click Add'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Date 1 = 2026-10-27
-- click Add
url: /courses/git
Git

25 minutes planned this week.

Sessions
Add sessions
 2026-10-22, 25 minutes
 2026-10-27, 30 minutes
```

O `canDeactivate` cobre a navegação dentro da aplicação. Fechar a aba ou digitar outro endereço deixa
a aplicação de vez, e o router não é perguntado; o evento `beforeunload` do navegador é o único lugar
para perguntar nessa hora, e os navegadores mostram ali, de propósito, a própria frase, não a sua.
