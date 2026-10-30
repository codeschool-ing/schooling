---
title: FormArray, for a list the person decides the length of
version: 1
---

**A `FormArray` is a list of controls whose length can change while the form is on the screen.** A
group has a fixed set of names; an array has positions, and controls can be pushed and removed. The
planner uses one for a thing that is tedious otherwise: planning the same length of session on
several days at once. One date to start with, a button for another, and a button beside each date
to take it out.

```schooling-example
{"language": "typescript", "file": "src/app/add-session/add-session.ts", "parts": [
 {"code": "import { HttpErrorResponse } from '@angular/common/http';\nimport { ChangeDetectionStrategy, Component, inject, input, signal } from '@angular/core';\nimport { NonNullableFormBuilder, ReactiveFormsModule } from '@angular/forms';\nimport { concatMap, from } from 'rxjs';\nimport { PlannerStore } from '../planner-store';\n\n@Component({\n  selector: 'app-add-session',\n  imports: [ReactiveFormsModule],", "note": "`concatMap` and `from`, from lesson 13: one request per date, one after the other."},
 {"code": "  template: `\n    <form [formGroup]=\"form\" (ngSubmit)=\"submit()\">\n      <h3>Add sessions</h3>\n      <div formArrayName=\"dates\">\n        @for (date of form.controls.dates.controls; track date; let i = $index) {\n          <label [for]=\"'date-' + i\">Date {{ i + 1 }}</label>\n          <input [id]=\"'date-' + i\" type=\"date\" [formControlName]=\"i\" />\n          @if (form.controls.dates.length > 1) {\n            <button type=\"button\" (click)=\"form.controls.dates.removeAt(i)\">Remove date {{ i + 1 }}</button>\n          }\n        }\n      </div>\n      <button type=\"button\" (click)=\"addDate()\">Another date</button>\n      <label for=\"minutes\">Minutes</label>\n      <input id=\"minutes\" type=\"number\" formControlName=\"minutes\" />\n      <button type=\"submit\">Add</button>\n      @if (error(); as message) {\n        <p role=\"alert\">{{ message }}</p>\n      }\n    </form>\n  `,\n  styles: `\n    form,\n    div {\n      display: grid;\n      gap: 0.5rem;\n      max-width: 20rem;\n    }\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class AddSession {\n  readonly courseId = input.required<string>();\n  private readonly store = inject(PlannerStore);\n  private readonly fb = inject(NonNullableFormBuilder);\n  protected readonly error = signal<string | null>(null);", "note": "`formArrayName` points at the array, and inside it `[formControlName]` takes a position instead of a name. Each date gets its own label and id, numbered, so a screen reader can tell them apart."},
 {"code": "  protected readonly form = this.fb.group({\n    dates: this.fb.array([this.fb.control('')]),\n    minutes: 30,\n  });\n\n  protected addDate(): void {\n    this.form.controls.dates.push(this.fb.control(''));\n  }", "note": "An array of date controls, starting with one, inside the group."},
 {"code": "  protected submit(): void {\n    this.error.set(null);\n    const { dates, minutes } = this.form.getRawValue();\n    from(dates)\n      .pipe(concatMap((date) => this.store.add({ courseId: this.courseId(), date, minutes })))\n      .subscribe({\n        complete: () => this.startAgain(),\n        error: (error: HttpErrorResponse) => this.error.set(`Not added: ${error.error?.error ?? error.statusText}`),\n      });\n  }", "note": "One `POST` per date, in order, and the form is put back only when all of them have answered. An error stops the rest and says why."},
 {"code": "  private startAgain(): void {\n    this.form.controls.dates.clear();\n    this.addDate();\n    this.form.reset();\n  }\n}", "note": "`reset()` resets values, not structure: it would leave three empty dates where there were three. So the array goes back to one control first."}
]}
```

`track date` tracks each control object itself, which stays the same for a date when another date
is removed above it. So when a date is removed, it is that date's input that leaves the page, and
the inputs after it keep what the browser holds in them, focus included. Two dates, for half an hour
each:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-course-page --do 'fill Date 1 = 2026-10-27' --do 'click Another date' --do 'fill Date 2 = 2026-10-29' --do 'fill Minutes = 30' --do 'click Add'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Date 1 = 2026-10-27
-- click Another date
-- fill Date 2 = 2026-10-29
-- fill Minutes = 30
-- click Add
JavaScript
 2026-10-13, 45 minutes
 2026-10-20, 60 minutes
 2026-10-24, 50 minutes
 2026-10-26, 40 minutes
 2026-10-27, 30 minutes
 2026-10-29, 30 minutes
Add sessions
Date 1
Another date
Minutes
Add
```

Two sessions added, the form back to one empty date. `concatMap` sent the second `POST` only after
the first was answered, which keeps the ids in the order the dates were typed. `forkJoin` would
have sent them at once; for two sessions the difference is invisible, and for twenty, the order
the server saw them in would be whichever arrived first.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Two columns joined by lines. On the left, the form model in the class: a FormGroup named form, holding a FormArray named dates, which holds FormControls at positions 0 and 1, and a FormControl named minutes. On the right, the template: the form element with [formGroup]=&quot;form&quot;, a div with formArrayName=&quot;dates&quot;, two date inputs with [formControlName] set to 0 and 1, and a number input with formControlName=&quot;minutes&quot;. Each line joins a part of the model to the element bound to it.\"><text x=\"150\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">in the class</text><text x=\"530\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">in the template</text><rect x=\"40\" y=\"36\" width=\"220\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"50\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">form: FormGroup</text><rect x=\"70\" y=\"92\" width=\"190\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">dates: FormArray</text><rect x=\"100\" y=\"148\" width=\"160\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">[0]: FormControl</text><rect x=\"100\" y=\"196\" width=\"160\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">[1]: FormControl</text><rect x=\"70\" y=\"244\" width=\"190\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">minutes: FormControl</text><rect x=\"400\" y=\"36\" width=\"260\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"410\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;form [formGroup]=\"form\"&gt;</text><rect x=\"420\" y=\"92\" width=\"240\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"430\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;div formArrayName=\"dates\"&gt;</text><rect x=\"440\" y=\"148\" width=\"220\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;input [formControlName]=\"0\"&gt;</text><rect x=\"440\" y=\"196\" width=\"220\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;input [formControlName]=\"1\"&gt;</text><rect x=\"420\" y=\"244\" width=\"240\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"430\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;input formControlName=\"minutes\"&gt;</text><line x1=\"260\" y1=\"52\" x2=\"400\" y2=\"52\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><line x1=\"260\" y1=\"108\" x2=\"420\" y2=\"108\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><line x1=\"260\" y1=\"164\" x2=\"440\" y2=\"164\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><line x1=\"260\" y1=\"212\" x2=\"440\" y2=\"212\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><line x1=\"260\" y1=\"260\" x2=\"420\" y2=\"260\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><path d=\"M 55 68 L 55 108 L 70 108\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><path d=\"M 55 108 L 55 260 L 70 260\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><path d=\"M 85 124 L 85 164 L 100 164\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><path d=\"M 85 164 L 85 212 L 100 212\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path></svg>", "caption": "The model is a tree in the class; the template names each part of it on the element that shows it."}
```
