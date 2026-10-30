---
title: A group of controls, typed together
version: 1
---

**A `FormGroup` is a set of named controls that behaves as one: one value, made of theirs, and one
status.** A session needs a date as well as minutes, so the form becomes a group of two. In the
template, `[formGroup]` binds the `<form>` to the group, and `formControlName` binds each input to a
control inside it by its name:

```typescript
// src/app/add-session/add-session.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { FormControl, FormGroup, ReactiveFormsModule } from '@angular/forms';

@Component({
  selector: 'app-add-session',
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="form">
      <h3>Add a session</h3>
      <label for="date">Date</label>
      <input id="date" type="date" formControlName="date" />
      <label for="minutes">Minutes</label>
      <input id="minutes" type="number" formControlName="minutes" />
    </form>
    <p>{{ asText() }}</p>
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
export class AddSession {
  protected readonly form = new FormGroup({
    date: new FormControl('', { nonNullable: true }),
    minutes: new FormControl(30, { nonNullable: true }),
  });

  protected asText(): string {
    return JSON.stringify(this.form.value);
  }
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-add-session --do 'fill Date = 2026-10-26' --do 'fill Minutes = 40'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Date = 2026-10-26
-- fill Minutes = 40
Add a session
Date
Minutes

{"date":"2026-10-26","minutes":40}
```

A date input's value is a string in the form `YYYY-MM-DD`, whatever the browser shows on the screen,
which is the form the API wants.

## What the types know

The group's type is worked out from its controls: `FormGroup<{ date: FormControl<string>; minutes:
FormControl<number> }>`. So the compiler knows `form.controls.minutes` exists and holds a number, and
refuses `form.controls.minuts` as it refuses any misspelt property. It also knows something less
obvious, which a method that adds ten minutes shows:

```typescript
// src/app/add-session/add-session.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { FormControl, FormGroup, ReactiveFormsModule } from '@angular/forms';

@Component({
  selector: 'app-add-session',
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="form">
      <h3>Add a session</h3>
      <label for="date">Date</label>
      <input id="date" type="date" formControlName="date" />
      <label for="minutes">Minutes</label>
      <input id="minutes" type="number" formControlName="minutes" />
    </form>
    <p>{{ asText() }}</p>
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
export class AddSession {
  protected readonly form = new FormGroup({
    date: new FormControl('', { nonNullable: true }),
    minutes: new FormControl(30, { nonNullable: true }),
  });

  protected asText(): string {
    return JSON.stringify(this.form.value);
  }

  protected tenMore(): number {
    return this.form.value.minutes + 10;
  }
}
```

```
ana@dev:~/planner$ npx ng build 2>&1 | grep -A4 ERROR
✘ [ERROR] TS2532: Object is possibly 'undefined'. [plugin angular-compiler]

    src/app/add-session/add-session.ts:38:11:
      38 │     return this.form.value.minutes + 10;
         ╵            ~~~~~~~~~~~~~~~~~~~~~~~
```

**`form.value` leaves out disabled controls**, so every field in its type is optional: a control
could be disabled at the moment it is read, and its value would be missing. `getRawValue()` includes
every control, disabled or not, so its type has every field: `this.form.getRawValue().minutes + 10`
compiles. That is the one to send to a server, and the next section does. The method was only there
to meet the error; it goes, and `add-session.ts` is the version before it again.
