---
title: Uma diretiva para o planner, e o foco na chegada
version: 1
---

**Quando uma página numa aplicação de página única muda, o foco fica onde estava, e quem usa o teclado
tem de achar o conteúdo novo sozinho.** Abrir o formulário de acrescentar é um clique em "Add
sessions", depois do qual o foco continua nesse link, acima do formulário. O HTML tem um atributo
`autofocus`, e ele não ajuda: o navegador o respeita quando o documento carrega, e numa aplicação o
documento carregou uma vez, há muito tempo. Uma diretiva pode fazer isso toda vez que o elemento dela é
desenhado.

```
ana@dev:~/planner$ npx ng generate directive autofocus
CREATE src/app/autofocus.spec.ts (199 bytes)
CREATE src/app/autofocus.ts (139 bytes)
```

```schooling-example
{"language": "typescript", "file": "src/app/autofocus.ts", "parts": [
 {"code": "// src/app/autofocus.ts\nimport { Directive, ElementRef, afterNextRender, booleanAttribute, inject, input } from '@angular/core';\n\n@Directive({\n  selector: '[appAutofocus]',\n})\nexport class Autofocus {\n  readonly appAutofocus = input(true, { transform: booleanAttribute });", "note": "O `booleanAttribute` transforma o atributo escrito sozinho, `appAutofocus`, em `true`, e deixa uma ligação desligá-lo em alguns elementos."},
 {"code": "  constructor() {\n    const element: HTMLElement = inject(ElementRef).nativeElement;\n    afterNextRender(() => {\n      if (this.appAutofocus()) element.focus();\n    });\n  }\n}", "note": "O `ElementRef` é o elemento em que a diretiva está. O `afterNextRender` da aula 9 espera até ele estar na página, onde pode receber o foco."}
]}
```

O CLI escreveu ao lado um teste que faz uma com `new`:

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E 'FAIL|NG0203|Tests '
⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯
 FAIL  |planner| src/app/autofocus.spec.ts > Autofocus > should create an instance
Error: NG0203: inputFunction() can only be used within an injection context such as a constructor, a factory function, a field initializer, or a function used with `runInInjectionContext`. Find more at https://v21.angular.dev/errors/NG0203
      Tests  1 failed | 9 passed (10)
```

O `NG0203` da aula 10: o `input()` num campo e o `inject()` no construtor precisam de um contexto de
injeção, e o `new`, fora do Angular, não é um. O teste deveria conferir para que a diretiva serve de
qualquer jeito, então ele ganha um pequeno componente hospedeiro próprio, no arquivo do teste, e
pergunta ao documento qual elemento tem o foco:

```typescript
// src/app/autofocus.spec.ts
import { Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Autofocus } from './autofocus';

@Component({
  imports: [Autofocus],
  template: '<input aria-label="first" /><input aria-label="second" appAutofocus />',
})
class Host {}

describe('Autofocus', () => {
  it('focuses the element it is on, once drawn', async () => {
    const fixture = TestBed.createComponent(Host);
    await fixture.whenStable();
    expect(document.activeElement?.getAttribute('aria-label')).toBe('second');
  });
});
```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E 'FAIL|NG0203|Tests '
      Tests  10 passed (10)
```

O formulário a põe só na primeira data, com uma ligação. Uma data acrescentada depois com "Another
date" não é focada por ela, já que a pessoa apertou um botão para obtê-la e sabe onde está.

```schooling-example
{"language": "typescript", "file": "src/app/add-session/add-session.ts", "parts": [
 {"code": "// src/app/add-session/add-session.ts\nimport { HttpClient, HttpErrorResponse } from '@angular/common/http';\nimport { ChangeDetectionStrategy, Component, ElementRef, inject, input, signal } from '@angular/core';\nimport { AbstractControl, AsyncValidatorFn, NonNullableFormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';\nimport { ActivatedRoute, Router } from '@angular/router';\nimport { concatMap, filter, from, map, take } from 'rxjs';\nimport { Autofocus } from '../autofocus';\nimport { PlannerData, isoDay } from '../planner';\nimport { PlannerStore } from '../planner-store';\nimport { TODAY } from '../today';\nimport { distinctDates, notBefore } from '../validators';\n\nconst MESSAGES: Record<string, string> = {\n  required: 'This is needed.',\n  min: 'At least 5 minutes.',\n  max: 'At most 480 minutes.',\n  past: 'That day has already gone.',\n  taken: 'This course already has a session that day.',\n};\n\n@Component({\n  selector: 'app-add-session',\n  imports: [Autofocus, ReactiveFormsModule],\n  template: `\n    <form [formGroup]=\"form\" (ngSubmit)=\"submit()\">\n      <h3>Add sessions</h3>\n      <div formArrayName=\"dates\">\n        @for (date of form.controls.dates.controls; track date; let i = $index) {\n          <label [for]=\"'date-' + i\">Date {{ i + 1 }}</label>\n          <input\n            [id]=\"'date-' + i\"\n            type=\"date\"\n            [formControlName]=\"i\"\n            [appAutofocus]=\"i === 0\"\n            [aria-invalid]=\"shows(date)\"\n            [aria-describedby]=\"shows(date) ? 'date-' + i + '-error' : null\"\n          />\n          @if (shows(date)) {\n            <p [id]=\"'date-' + i + '-error'\">{{ messageFor(date) }}</p>\n          }\n          @if (form.controls.dates.length > 1) {\n            <button type=\"button\" (click)=\"form.controls.dates.removeAt(i)\">Remove date {{ i + 1 }}</button>\n          }\n        }\n        @if (shows(form.controls.dates) && form.controls.dates.hasError('repeated')) {\n          <p>Two of the dates are the same day.</p>\n        }\n      </div>\n      <button type=\"button\" (click)=\"addDate()\">Another date</button>\n      <label for=\"minutes\">Minutes</label>\n      <input\n        id=\"minutes\"\n        type=\"number\"\n        formControlName=\"minutes\"\n        [aria-invalid]=\"shows(form.controls.minutes)\"\n        [aria-describedby]=\"shows(form.controls.minutes) ? 'minutes-error' : null\"\n      />\n      @if (shows(form.controls.minutes)) {\n        <p id=\"minutes-error\">{{ messageFor(form.controls.minutes) }}</p>\n      }\n      <button type=\"submit\">Add</button>\n      @if (error(); as message) {\n        <p role=\"alert\">{{ message }}</p>\n      }\n    </form>\n  `,\n  styles: `\n    form,\n    div {\n      display: grid;\n      gap: 0.5rem;\n      max-width: 20rem;\n    }\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})", "note": "A diretiva é importada como um componente, e a primeira data pede o foco com `[appAutofocus]=\"i === 0\"`."},
 {"code": "export class AddSession {\n  readonly courseId = input.required<string>();\n  private readonly store = inject(PlannerStore);\n  private readonly http = inject(HttpClient);\n  private readonly fb = inject(NonNullableFormBuilder);\n  private readonly host: ElementRef<HTMLElement> = inject(ElementRef);\n  private readonly router = inject(Router);\n  private readonly route = inject(ActivatedRoute);\n  private readonly today = isoDay(inject(TODAY));\n  protected readonly error = signal<string | null>(null);\n  protected readonly submitted = signal(false);\n\n  private readonly freeDay: AsyncValidatorFn = (control) =>\n    this.http\n      .get<PlannerData>('/api/planner')\n      .pipe(\n        map((data) =>\n          data.sessions.some((s) => s.courseId === this.courseId() && s.date === control.value) ? { taken: true } : null,\n        ),\n      );\n\n  protected readonly form = this.fb.group({\n    dates: this.fb.array([this.dateControl()], { validators: distinctDates }),\n    minutes: this.fb.control(30, { validators: [Validators.required, Validators.min(5), Validators.max(480)] }),\n  });\n\n  hasUnsavedWork(): boolean {\n    return this.form.dirty;\n  }\n\n  protected shows(control: AbstractControl): boolean {\n    return control.invalid && (control.touched || this.submitted());\n  }\n\n  protected messageFor(control: AbstractControl): string {\n    const first = Object.keys(control.errors ?? {})[0];\n    return MESSAGES[first] ?? first;\n  }\n\n  protected addDate(): void {\n    this.form.controls.dates.push(this.dateControl());\n  }\n\n  protected submit(): void {\n    this.submitted.set(true);\n    if (this.form.pending) {\n      this.form.statusChanges.pipe(filter((status) => status !== 'PENDING'), take(1)).subscribe(() => this.submit());\n      return;\n    }\n    if (this.form.invalid) {\n      this.focusFirstProblem();\n      return;\n    }\n    this.error.set(null);\n    const { dates, minutes } = this.form.getRawValue();\n    from(dates)\n      .pipe(concatMap((date) => this.store.add({ courseId: this.courseId(), date, minutes })))\n      .subscribe({\n        complete: () => {\n          this.form.markAsPristine();\n          this.router.navigate(['..'], { relativeTo: this.route });\n        },\n        error: (error: HttpErrorResponse) => this.error.set(`Not added: ${error.error?.error ?? error.statusText}`),\n      });\n  }\n\n  private dateControl() {\n    return this.fb.control('', {\n      validators: [Validators.required, notBefore(this.today)],\n      asyncValidators: this.freeDay,\n      updateOn: 'blur',\n    });\n  }\n\n  private focusFirstProblem(): void {\n    const { dates, minutes } = this.form.controls;\n    const i = dates.controls.findIndex((date) => date.invalid);\n    const id = i >= 0 ? `date-${i}` : dates.invalid ? 'date-0' : minutes.invalid ? 'minutes' : null;\n    if (id) this.host.nativeElement.querySelector<HTMLElement>(`#${id}`)?.focus();\n  }\n}"}
]}
```

O `--a11y` marca o elemento com o foco. Um clique em "Add sessions":

```
ana@dev:~/planner$ look http://localhost:4200/courses/git --today 2026-10-23 --a11y app-add-session --do 'click Add sessions'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Add sessions
- form
  - heading "Add sessions" [level=3]
  - LabelText
    - text: Date 1
  - Date "Date 1" [focused]
  - button "Another date"
  - LabelText
    - text: Minutes
  - spinbutton "Minutes": 30
  - button "Add"
```

A primeira data tem o foco, então a próxima tecla de quem usa o teclado digita nela, e um leitor de
tela começa a ler pelo campo. Mover o foco é uma decisão a tomar com cuidado, porque leva o leitor a
um lugar que ele não pediu; aqui ele pediu, ao abrir o formulário.
