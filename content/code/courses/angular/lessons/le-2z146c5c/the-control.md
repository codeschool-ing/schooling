---
title: A directive that finds the control on its element
version: 1
---

**A directive shares its element with whatever else is on it, and can inject it.** Lesson 10 said that
`self`, `skipSelf` and `host` matter mostly to directives that need to find a particular component
around them. Here is one. Lesson 15 bound `aria-invalid` by hand on each field, with the same rule
written twice. A directive can set it on every field of every form, because on an element with
`formControlName` there is already a directive holding the control: `NgControl`.

```schooling-example
{"language": "typescript", "file": "src/app/aria-invalid.ts", "parts": [
 {"code": "// src/app/aria-invalid.ts\nimport { Directive, inject } from '@angular/core';\nimport { FormGroupDirective, NgControl } from '@angular/forms';\n\n@Directive({\n  selector: '[formControlName],[formControl]',\n  host: { '[attr.aria-invalid]': 'shows() || null' },\n})\nexport class AriaInvalid {", "note": "The selector is the reactive forms' own attributes, so the directive arrives on every bound field, in any component that imports it, without anybody writing it."},
 {"code": "  private readonly control = inject(NgControl, { self: true });\n  private readonly form = inject(FormGroupDirective, { optional: true });", "note": "`self: true`: the control on this element, not one further up. `optional: true`: a lone `[formControl]` has no form around it."},
 {"code": "  protected shows(): boolean {\n    return Boolean(this.control.invalid && (this.control.touched || this.form?.submitted));\n  }\n}", "note": "Lesson 15's rule, once: invalid, and either touched or the form submitted. `null` removes the attribute."}
]}
```

`FormGroupDirective` is the `[formGroup]` on the `<form>`, found by walking up from the field, and its
`submitted` is true once somebody has tried to submit. The form drops its two `[aria-invalid]`
bindings and imports the directive:

```schooling-example
{"language": "typescript", "file": "src/app/add-session/add-session.ts", "parts": [
 {"code": "// src/app/add-session/add-session.ts\nimport { HttpClient, HttpErrorResponse } from '@angular/common/http';\nimport { ChangeDetectionStrategy, Component, ElementRef, inject, input, signal } from '@angular/core';\nimport { AbstractControl, AsyncValidatorFn, NonNullableFormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';\nimport { ActivatedRoute, Router } from '@angular/router';\nimport { concatMap, filter, from, map, take } from 'rxjs';\nimport { AriaInvalid } from '../aria-invalid';\nimport { Autofocus } from '../autofocus';\nimport { PlannerData, isoDay } from '../planner';\nimport { PlannerStore } from '../planner-store';\nimport { TODAY } from '../today';\nimport { distinctDates, notBefore } from '../validators';\n\nconst MESSAGES: Record<string, string> = {\n  required: 'This is needed.',\n  min: 'At least 5 minutes.',\n  max: 'At most 480 minutes.',\n  past: 'That day has already gone.',\n  taken: 'This course already has a session that day.',\n};\n\n@Component({\n  selector: 'app-add-session',\n  imports: [AriaInvalid, Autofocus, ReactiveFormsModule],\n  template: `\n    <form [formGroup]=\"form\" (ngSubmit)=\"submit()\">\n      <h3>Add sessions</h3>\n      <div formArrayName=\"dates\">\n        @for (date of form.controls.dates.controls; track date; let i = $index) {\n          <label [for]=\"'date-' + i\">Date {{ i + 1 }}</label>\n          <input\n            [id]=\"'date-' + i\"\n            type=\"date\"\n            [formControlName]=\"i\"\n            [appAutofocus]=\"i === 0\"\n            [aria-describedby]=\"shows(date) ? 'date-' + i + '-error' : null\"\n          />\n          @if (shows(date)) {\n            <p [id]=\"'date-' + i + '-error'\">{{ messageFor(date) }}</p>\n          }\n          @if (form.controls.dates.length > 1) {\n            <button type=\"button\" (click)=\"form.controls.dates.removeAt(i)\">Remove date {{ i + 1 }}</button>\n          }\n        }\n        @if (shows(form.controls.dates) && form.controls.dates.hasError('repeated')) {\n          <p>Two of the dates are the same day.</p>\n        }\n      </div>\n      <button type=\"button\" (click)=\"addDate()\">Another date</button>\n      <label for=\"minutes\">Minutes</label>\n      <input\n        id=\"minutes\"\n        type=\"number\"\n        formControlName=\"minutes\"\n        [aria-describedby]=\"shows(form.controls.minutes) ? 'minutes-error' : null\"\n      />\n      @if (shows(form.controls.minutes)) {\n        <p id=\"minutes-error\">{{ messageFor(form.controls.minutes) }}</p>\n      }\n      <button type=\"submit\">Add</button>\n      @if (error(); as message) {\n        <p role=\"alert\">{{ message }}</p>\n      }\n    </form>\n  `,\n  styles: `\n    form,\n    div {\n      display: grid;\n      gap: 0.5rem;\n      max-width: 20rem;\n    }\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})", "note": "`AriaInvalid` is imported, and both `[aria-invalid]` bindings are gone from the template: the directive sets the attribute on every field with `formControlName`."},
 {"code": "export class AddSession {\n  readonly courseId = input.required<string>();\n  private readonly store = inject(PlannerStore);\n  private readonly http = inject(HttpClient);\n  private readonly fb = inject(NonNullableFormBuilder);\n  private readonly host: ElementRef<HTMLElement> = inject(ElementRef);\n  private readonly router = inject(Router);\n  private readonly route = inject(ActivatedRoute);\n  private readonly today = isoDay(inject(TODAY));\n  protected readonly error = signal<string | null>(null);\n  protected readonly submitted = signal(false);\n\n  private readonly freeDay: AsyncValidatorFn = (control) =>\n    this.http\n      .get<PlannerData>('/api/planner')\n      .pipe(\n        map((data) =>\n          data.sessions.some((s) => s.courseId === this.courseId() && s.date === control.value) ? { taken: true } : null,\n        ),\n      );\n\n  protected readonly form = this.fb.group({\n    dates: this.fb.array([this.dateControl()], { validators: distinctDates }),\n    minutes: this.fb.control(30, { validators: [Validators.required, Validators.min(5), Validators.max(480)] }),\n  });\n\n  hasUnsavedWork(): boolean {\n    return this.form.dirty;\n  }\n\n  protected shows(control: AbstractControl): boolean {\n    return control.invalid && (control.touched || this.submitted());\n  }\n\n  protected messageFor(control: AbstractControl): string {\n    const first = Object.keys(control.errors ?? {})[0];\n    return MESSAGES[first] ?? first;\n  }\n\n  protected addDate(): void {\n    this.form.controls.dates.push(this.dateControl());\n  }\n\n  protected submit(): void {\n    this.submitted.set(true);\n    if (this.form.pending) {\n      this.form.statusChanges.pipe(filter((status) => status !== 'PENDING'), take(1)).subscribe(() => this.submit());\n      return;\n    }\n    if (this.form.invalid) {\n      this.focusFirstProblem();\n      return;\n    }\n    this.error.set(null);\n    const { dates, minutes } = this.form.getRawValue();\n    from(dates)\n      .pipe(concatMap((date) => this.store.add({ courseId: this.courseId(), date, minutes })))\n      .subscribe({\n        complete: () => {\n          this.form.markAsPristine();\n          this.router.navigate(['..'], { relativeTo: this.route });\n        },\n        error: (error: HttpErrorResponse) => this.error.set(`Not added: ${error.error?.error ?? error.statusText}`),\n      });\n  }\n\n  private dateControl() {\n    return this.fb.control('', {\n      validators: [Validators.required, notBefore(this.today)],\n      asyncValidators: this.freeDay,\n      updateOn: 'blur',\n    });\n  }\n\n  private focusFirstProblem(): void {\n    const { dates, minutes } = this.form.controls;\n    const i = dates.controls.findIndex((date) => date.invalid);\n    const id = i >= 0 ? `date-${i}` : dates.invalid ? 'date-0' : minutes.invalid ? 'minutes' : null;\n    if (id) this.host.nativeElement.querySelector<HTMLElement>(`#${id}`)?.focus();\n  }\n}"}
]}
```

```
ana@dev:~/planner$ look http://localhost:4200/courses/git/add --today 2026-10-23 --a11y app-add-session --do 'fill Minutes = 2' --do 'click Add'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Minutes = 2
-- click Add
- form
  - heading "Add sessions" [level=3]
  - LabelText
    - text: Date 1
  - Date "Date 1" [invalid] [focused] (description: This is needed.)
  - paragraph
    - text: This is needed.
  - button "Another date"
  - LabelText
    - text: Minutes
  - spinbutton "Minutes" [invalid]: 2 (description: At least 5 minutes.)
  - paragraph
    - text: At least 5 minutes.
  - button "Add"
```

Both fields are `invalid`, with their descriptions, as in lesson 15, and the template no longer says
so: the rule lives in one directive, and a form written tomorrow gets it by importing `AriaInvalid`.
The descriptions stay in the template, because which paragraph describes which field is the form's own
decision.
