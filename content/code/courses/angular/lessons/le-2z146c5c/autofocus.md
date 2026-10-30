---
title: A directive for the planner, and the focus on arrival
version: 1
---

**When a page in a single-page application changes, the focus stays where it was, and a keyboard
user has to find the new content themselves.** Opening the add form is a click on "Add sessions",
after which the focus is still on that link, above the form. HTML has an `autofocus` attribute, and
it does not help: the browser honours it when the document loads, and in an application the document
loaded once, long ago. A directive can do it each time its element is drawn.

```
ana@dev:~/planner$ npx ng generate directive autofocus
CREATE src/app/autofocus.spec.ts (199 bytes)
CREATE src/app/autofocus.ts (139 bytes)
```

```schooling-example
{"language": "typescript", "file": "src/app/autofocus.ts", "parts": [
 {"code": "// src/app/autofocus.ts\nimport { Directive, ElementRef, afterNextRender, booleanAttribute, inject, input } from '@angular/core';\n\n@Directive({\n  selector: '[appAutofocus]',\n})\nexport class Autofocus {\n  readonly appAutofocus = input(true, { transform: booleanAttribute });", "note": "`booleanAttribute` turns the attribute written alone, `appAutofocus`, into `true`, and lets a binding switch it off for some elements."},
 {"code": "  constructor() {\n    const element: HTMLElement = inject(ElementRef).nativeElement;\n    afterNextRender(() => {\n      if (this.appAutofocus()) element.focus();\n    });\n  }\n}", "note": "`ElementRef` is the element the directive sits on. Lesson 9's `afterNextRender` waits until it is on the page, where it can take the focus."}
]}
```

The CLI wrote a test beside it that makes one with `new`:

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E 'FAIL|NG0203|Tests '
⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯
 FAIL  |planner| src/app/autofocus.spec.ts > Autofocus > should create an instance
Error: NG0203: inputFunction() can only be used within an injection context such as a constructor, a factory function, a field initializer, or a function used with `runInInjectionContext`. Find more at https://v21.angular.dev/errors/NG0203
      Tests  1 failed | 9 passed (10)
```

Lesson 10's `NG0203`: `input()` in a field and `inject()` in the constructor both need an injection
context, and `new`, outside Angular, is not one. The test should check what the directive is for anyway, so it gets a small host component of
its own, in the test file, and asks the document which element has the focus:

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

The form puts it on the first date only, with a binding. A date added later with "Another date" is not
focused by this, since the person pressed a button to get it and knows where they are.

```schooling-example
{"language": "typescript", "file": "src/app/add-session/add-session.ts", "parts": [
 {"code": "// src/app/add-session/add-session.ts\nimport { HttpClient, HttpErrorResponse } from '@angular/common/http';\nimport { ChangeDetectionStrategy, Component, ElementRef, inject, input, signal } from '@angular/core';\nimport { AbstractControl, AsyncValidatorFn, NonNullableFormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';\nimport { ActivatedRoute, Router } from '@angular/router';\nimport { concatMap, filter, from, map, take } from 'rxjs';\nimport { Autofocus } from '../autofocus';\nimport { PlannerData, isoDay } from '../planner';\nimport { PlannerStore } from '../planner-store';\nimport { TODAY } from '../today';\nimport { distinctDates, notBefore } from '../validators';\n\nconst MESSAGES: Record<string, string> = {\n  required: 'This is needed.',\n  min: 'At least 5 minutes.',\n  max: 'At most 480 minutes.',\n  past: 'That day has already gone.',\n  taken: 'This course already has a session that day.',\n};\n\n@Component({\n  selector: 'app-add-session',\n  imports: [Autofocus, ReactiveFormsModule],\n  template: `\n    <form [formGroup]=\"form\" (ngSubmit)=\"submit()\">\n      <h3>Add sessions</h3>\n      <div formArrayName=\"dates\">\n        @for (date of form.controls.dates.controls; track date; let i = $index) {\n          <label [for]=\"'date-' + i\">Date {{ i + 1 }}</label>\n          <input\n            [id]=\"'date-' + i\"\n            type=\"date\"\n            [formControlName]=\"i\"\n            [appAutofocus]=\"i === 0\"\n            [aria-invalid]=\"shows(date)\"\n            [aria-describedby]=\"shows(date) ? 'date-' + i + '-error' : null\"\n          />\n          @if (shows(date)) {\n            <p [id]=\"'date-' + i + '-error'\">{{ messageFor(date) }}</p>\n          }\n          @if (form.controls.dates.length > 1) {\n            <button type=\"button\" (click)=\"form.controls.dates.removeAt(i)\">Remove date {{ i + 1 }}</button>\n          }\n        }\n        @if (shows(form.controls.dates) && form.controls.dates.hasError('repeated')) {\n          <p>Two of the dates are the same day.</p>\n        }\n      </div>\n      <button type=\"button\" (click)=\"addDate()\">Another date</button>\n      <label for=\"minutes\">Minutes</label>\n      <input\n        id=\"minutes\"\n        type=\"number\"\n        formControlName=\"minutes\"\n        [aria-invalid]=\"shows(form.controls.minutes)\"\n        [aria-describedby]=\"shows(form.controls.minutes) ? 'minutes-error' : null\"\n      />\n      @if (shows(form.controls.minutes)) {\n        <p id=\"minutes-error\">{{ messageFor(form.controls.minutes) }}</p>\n      }\n      <button type=\"submit\">Add</button>\n      @if (error(); as message) {\n        <p role=\"alert\">{{ message }}</p>\n      }\n    </form>\n  `,\n  styles: `\n    form,\n    div {\n      display: grid;\n      gap: 0.5rem;\n      max-width: 20rem;\n    }\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})", "note": "The directive is imported like a component, and the first date asks for the focus with `[appAutofocus]=\"i === 0\"`."},
 {"code": "export class AddSession {\n  readonly courseId = input.required<string>();\n  private readonly store = inject(PlannerStore);\n  private readonly http = inject(HttpClient);\n  private readonly fb = inject(NonNullableFormBuilder);\n  private readonly host: ElementRef<HTMLElement> = inject(ElementRef);\n  private readonly router = inject(Router);\n  private readonly route = inject(ActivatedRoute);\n  private readonly today = isoDay(inject(TODAY));\n  protected readonly error = signal<string | null>(null);\n  protected readonly submitted = signal(false);\n\n  private readonly freeDay: AsyncValidatorFn = (control) =>\n    this.http\n      .get<PlannerData>('/api/planner')\n      .pipe(\n        map((data) =>\n          data.sessions.some((s) => s.courseId === this.courseId() && s.date === control.value) ? { taken: true } : null,\n        ),\n      );\n\n  protected readonly form = this.fb.group({\n    dates: this.fb.array([this.dateControl()], { validators: distinctDates }),\n    minutes: this.fb.control(30, { validators: [Validators.required, Validators.min(5), Validators.max(480)] }),\n  });\n\n  hasUnsavedWork(): boolean {\n    return this.form.dirty;\n  }\n\n  protected shows(control: AbstractControl): boolean {\n    return control.invalid && (control.touched || this.submitted());\n  }\n\n  protected messageFor(control: AbstractControl): string {\n    const first = Object.keys(control.errors ?? {})[0];\n    return MESSAGES[first] ?? first;\n  }\n\n  protected addDate(): void {\n    this.form.controls.dates.push(this.dateControl());\n  }\n\n  protected submit(): void {\n    this.submitted.set(true);\n    if (this.form.pending) {\n      this.form.statusChanges.pipe(filter((status) => status !== 'PENDING'), take(1)).subscribe(() => this.submit());\n      return;\n    }\n    if (this.form.invalid) {\n      this.focusFirstProblem();\n      return;\n    }\n    this.error.set(null);\n    const { dates, minutes } = this.form.getRawValue();\n    from(dates)\n      .pipe(concatMap((date) => this.store.add({ courseId: this.courseId(), date, minutes })))\n      .subscribe({\n        complete: () => {\n          this.form.markAsPristine();\n          this.router.navigate(['..'], { relativeTo: this.route });\n        },\n        error: (error: HttpErrorResponse) => this.error.set(`Not added: ${error.error?.error ?? error.statusText}`),\n      });\n  }\n\n  private dateControl() {\n    return this.fb.control('', {\n      validators: [Validators.required, notBefore(this.today)],\n      asyncValidators: this.freeDay,\n      updateOn: 'blur',\n    });\n  }\n\n  private focusFirstProblem(): void {\n    const { dates, minutes } = this.form.controls;\n    const i = dates.controls.findIndex((date) => date.invalid);\n    const id = i >= 0 ? `date-${i}` : dates.invalid ? 'date-0' : minutes.invalid ? 'minutes' : null;\n    if (id) this.host.nativeElement.querySelector<HTMLElement>(`#${id}`)?.focus();\n  }\n}"}
]}
```

`--a11y` marks the element with the focus. A click on "Add sessions":

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

The first date has the focus, so the next key a keyboard user presses types into it, and a screen
reader starts reading at the field. Moving the focus is a decision to make with care, because it
takes the reader somewhere they did not ask to go; here they asked, by opening the form.
