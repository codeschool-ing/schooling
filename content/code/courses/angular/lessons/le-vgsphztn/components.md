---
title: A Material component in the planner
version: 1
---

**A Material component replaces an element you would otherwise style and wire yourself, and brings
its accessibility with it.** The session's checkbox is the plainest case. `mat-checkbox` draws a
themed box, keeps a real `<input type="checkbox">` inside it for keyboards and screen readers, and
reports changes through its own `change` output, with the new state in `checked`:

```typescript
// src/app/session-row/session-row.ts
import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { MatCheckbox } from '@angular/material/checkbox';
import { MinutesPipe } from '../minutes-pipe';
import { Session } from '../planner';

@Component({
  selector: 'app-session-row',
  imports: [DatePipe, MatCheckbox, MinutesPipe],
  template: `
    <mat-checkbox [checked]="session().done" (change)="toggled.emit($event.checked)">
      {{ session().date | date: 'EEE d MMM' }}, {{ session().minutes | minutes }}
    </mat-checkbox>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SessionRow {
  readonly session = input.required<Session>();
  readonly toggled = output<boolean>();
}
```

The row no longer needs its `changed` method: `$event.checked` is already a boolean. Each component is
imported from its own entry point, `@angular/material/checkbox`, so the build includes only the
components that are used.

```
ana@dev:~/planner$ look http://localhost:4200/courses/javascript --today 2026-10-23 --a11y app-course-sessions --do 'check Sat 24 Oct, 50 minutes'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- check Sat 24 Oct, 50 minutes
- list
  - listitem [level=1]
    - ListMarker "• "
    - checkbox "Tue 13 Oct, 45 minutes" [checked]
  - listitem [level=1]
    - ListMarker "• "
    - checkbox "Tue 20 Oct, 1 hour" [checked]
  - listitem [level=1]
    - ListMarker "• "
    - checkbox "Sat 24 Oct, 50 minutes" [focused] [checked]
```

To a screen reader it is the same checkbox as before, with the same name, and the same `look`
action ticks it, because the box is still found by its label. That sameness is the point: a component
library that broke the accessible name of a checkbox would be a step back, however it looked.

Material has a component for most controls an application needs, from `matButton`, an attribute on a
real `<button>`, to `mat-table` and the date picker. The planner takes one more of them in the next
section but one, the dialog, because a dialog is the control that is hardest to build correctly.
