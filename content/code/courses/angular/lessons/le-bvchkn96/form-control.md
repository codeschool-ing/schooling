---
title: A form control, and where its value lives
version: 1
---

**In a reactive form the form is an object in the component's class, and the template only points
at it.** A `FormControl` holds one field's value, knows whether it has been touched or changed, and
later in this lesson and the next whether it is valid. The `<input>` in the template is bound to it
and kept in step with it both ways: typing changes the control, and setting the control changes what
the input shows. Because the model is code, it can be read, tested and typed without any template.

The planner's form will add sessions to a course, so it is a component of its own, beside the list
on the course page:

```
ana@dev:~/planner$ npx ng generate component add-session --inline-template --inline-style --skip-tests
CREATE src/app/add-session/add-session.ts (286 bytes)
```

A first version with one control, for the minutes, and a line under it that says what the control
holds:

```schooling-example
{"language": "typescript", "file": "src/app/add-session/add-session.ts", "parts": [
 {"code": "import { ChangeDetectionStrategy, Component } from '@angular/core';\nimport { FormControl, ReactiveFormsModule } from '@angular/forms';\n\n@Component({\n  selector: 'app-add-session',\n  imports: [ReactiveFormsModule],", "note": "The reactive form directives, `[formControl]` among them, come from `ReactiveFormsModule`, imported like a component."},
 {"code": "  template: `\n    <label for=\"minutes\">Minutes</label>\n    <input id=\"minutes\" type=\"number\" [formControl]=\"minutes\" />\n    <p>The value is {{ minutes.value }}, of type {{ typeOfValue() }}.</p>\n  `,\n  styles: `\n    :host {\n      display: grid;\n      gap: 0.5rem;\n      max-width: 20rem;\n    }\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class AddSession {", "note": "`[formControl]` ties the input to the control in the class. There is no `(input)` handler: the directive listens for you."},
 {"code": "  protected readonly minutes = new FormControl(30);\n\n  protected typeOfValue(): string {\n    return typeof this.minutes.value;\n  }\n}", "note": "The control's type comes from its first value: `FormControl<number | null>`."}
]}
```

The course page puts it under the list:

```typescript
// src/app/course-page/course-page.ts
import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { AddSession } from '../add-session/add-session';
import { PlannerStore } from '../planner-store';
import { SessionList } from '../session-list/session-list';

@Component({
  selector: 'app-course-page',
  imports: [SessionList, AddSession],
  templateUrl: './course-page.html',
  styleUrl: './course-page.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CoursePage {
  readonly courseId = input.required<string>();
  protected readonly store = inject(PlannerStore);
  protected readonly course = computed(() => this.store.courses().find((c) => c.id === this.courseId()));
  protected readonly sessions = computed(() =>
    this.store
      .sessions()
      .filter((s) => s.courseId === this.courseId())
      .sort((a, b) => a.date.localeCompare(b.date)),
  );
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
  @if (store.saveError(); as message) {
    <p role="alert">{{ message }}</p>
  }
  <app-session-list [sessions]="sessions()" (toggled)="store.toggle($event.id, $event.done)" />
  <app-add-session />
} @else {
  <p>There is no course called {{ courseId() }}.</p>
}
```

Type a number into the field, and then empty it:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-add-session --do 'fill Minutes = 45'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Minutes = 45
Minutes

The value is 45, of type number.
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-add-session --do 'fill Minutes = '
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Minutes = 
Minutes

The value is , of type object.
```

**A number field gives the control a `number`, and an empty one gives it `null`**, which `typeof`
calls `object`. That is why the control's type is `FormControl<number | null>` rather than
`FormControl<number>`: Angular cannot rule out the empty field, and nor can `reset()`, which by
default sets a control back to `null`. `new FormControl(30, { nonNullable: true })` makes `reset()`
go back to 30 instead and drops the `null` from the type. The empty field can still put a `null`
there at run time; lesson 15's `Validators.required` is what refuses it.
