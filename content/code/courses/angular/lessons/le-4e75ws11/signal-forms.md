---
title: Signal Forms, the experimental third way
version: 1
---

**Angular 21 ships a third kind of form, Signal Forms, marked experimental.** The model is a signal
you own, of a plain object. `form(model, schema)` builds a tree of fields over it, one per
property, and each field's value, errors and state are signals. The rules are written once, in the
schema function, against paths into the model. In the template, `[formField]` binds an input to a
field.

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, signal } from '@angular/core';
import { FormField, form, min, required } from '@angular/forms/signals';

@Component({
  selector: 'app-bench',
  imports: [FormField],
  template: `
    <form novalidate>
      <label for="s-day">Day</label>
      <input id="s-day" type="date" [formField]="draft.date" />
      @for (error of draft.date().errors(); track error.kind) {
        <p>{{ error.message }}</p>
      }
      <label for="s-minutes">Length in minutes</label>
      <input id="s-minutes" type="number" [formField]="draft.minutes" />
      @for (error of draft.minutes().errors(); track error.kind) {
        <p>{{ error.message }}</p>
      }
    </form>
    <p>{{ model().date }}, {{ model().minutes }} minutes, valid: {{ draft().valid() }}</p>
  `,
  styles: `
    form {
      display: grid;
      gap: 0.5rem;
      max-width: 20rem;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  protected readonly model = signal({ date: '', minutes: 30 });
  protected readonly draft = form(this.model, (path) => {
    required(path.date, { message: 'This is needed.' });
    min(path.minutes, 5, { message: 'At least 5 minutes.' });
  });
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'fill Length in minutes = 2'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Length in minutes = 2
Day

This is needed.

Length in minutes

At least 5 minutes.

, 2 minutes, valid: false
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'fill Day = 2026-10-26' --do 'fill Length in minutes = 45'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Day = 2026-10-26
-- fill Length in minutes = 45
Day
Length in minutes

2026-10-26, 45 minutes, valid: true
```

The input wrote straight into `model`: `model().minutes` was 2, then 45, with no `getRawValue` in
between, because the form's value and the signal are the same thing. `draft().valid()` is a signal,
so a `computed` can read it like any other. Every message here shows at once; each field also has a
`touched()` signal, for the rule lesson 15 used.

It writes some of the form's rules into the page as well. The form's own HTML shows it:

```
ana@dev:~/planner$ look http://localhost:4200/ --html 'app-bench form'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
<form novalidate=""><label for="s-day">Day</label><input id="s-day" type="date" name="ng.form0.date" required=""><p>This is needed.</p><!--container--><label for="s-minutes">Length in minutes</label><input id="s-minutes" type="number" min="5" name="ng.form0.minutes"><!--container--></form>
```

`[formField]` put the browser's own attributes on the inputs, `required` on the date and `min="5"`
on the minutes, from the schema, so assistive technology knows the date is required without being
told twice. That is also why the `<form>` carries `novalidate`, written by hand: nothing from
`FormsModule` or `ReactiveFormsModule` is imported here to add it, and without it the browser would
show its own bubbles for those attributes. Connecting a message to its field is still yours to
write, with `aria-describedby`, as it was in lesson 15.

**Experimental means the API may change in a minor release**, without the deprecation period the
rest of Angular promises. For an application that has to be maintained for years, the planner's
choice is the one to make today: reactive forms, which are stable, and which Signal Forms are
designed to be adopted beside, one form at a time.
