---
title: A dialog for unsaved work
version: 1
---

**Lesson 18's guard asked with `confirm()`, which works and cannot be designed or worded beyond a
sentence.** A Material dialog can say more, use the application's own buttons, and still behave as a
dialog must: focus moves into it, stays there, and goes back where it came from.

The dialog is a component like any other, with Material's dialog directives for its parts:

```typescript
// src/app/confirm-leave/confirm-leave.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { MatButton } from '@angular/material/button';
import { MatDialogActions, MatDialogClose, MatDialogContent, MatDialogTitle } from '@angular/material/dialog';

@Component({
  selector: 'app-confirm-leave',
  imports: [MatButton, MatDialogActions, MatDialogClose, MatDialogContent, MatDialogTitle],
  template: `
    <h2 mat-dialog-title>Leave this form?</h2>
    <mat-dialog-content>What you typed has not been added.</mat-dialog-content>
    <mat-dialog-actions>
      <button matButton [mat-dialog-close]="false">Stay</button>
      <button matButton="filled" [mat-dialog-close]="true">Leave</button>
    </mat-dialog-actions>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ConfirmLeave {}
```

`[mat-dialog-close]` closes the dialog with a value: `false` for Stay, `true` for Leave. The guard opens
it and waits for that value. A guard runs in an injection context, so it can `inject(MatDialog)`, and
it can return an Observable, which the router waits for:

```typescript
// src/app/unsaved-work.ts
import { inject } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { CanDeactivateFn } from '@angular/router';
import { map } from 'rxjs';
import { ConfirmLeave } from './confirm-leave/confirm-leave';

export interface MayHaveUnsavedWork {
  hasUnsavedWork(): boolean;
}

export const unsavedWork: CanDeactivateFn<MayHaveUnsavedWork> = (component) => {
  if (!component.hasUnsavedWork()) return true;
  return inject(MatDialog)
    .open(ConfirmLeave)
    .afterClosed()
    .pipe(map((leave) => leave === true));
};
```

The route did not change, and neither did the form. The same minutes typed, the same click:

```
ana@dev:~/planner$ look http://localhost:4200/courses/git/add --today 2026-10-23 --url --a11y body --do 'fill Minutes = 45' --do 'click Sessions'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Minutes = 45
-- click Sessions
url: /courses/git/add
- group
  - dialog "Leave this form?"
    - heading "Leave this form?" [level=2]
    - button "Stay" [focused]
    - button "Leave"
```

**The whole page, as a screen reader has it, is now the dialog**: the CDK hides everything behind it
while it is open, so nobody can wander out of it by accident. Its name is its title, and the focus is
on "Stay", the first button, which is the safe answer to have under a finger.

Escape closes it, which counts as staying, and the focus goes back to the link that opened it:

```
ana@dev:~/planner$ look http://localhost:4200/courses/git/add --today 2026-10-23 --a11y 'app-course-page nav' --do 'fill Minutes = 45' --do 'click Sessions' --do 'press Escape'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Minutes = 45
-- click Sessions
-- press Escape
- navigation "Course"
  - link "Sessions" [focused]
  - link "Add sessions"
```

```
ana@dev:~/planner$ look http://localhost:4200/courses/git/add --today 2026-10-23 --url --text h2 --do 'fill Minutes = 45' --do 'click Sessions' --do 'click Leave'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Minutes = 45
-- click Sessions
-- click Leave
url: /courses/git
Git
```

Stay kept the form; Leave went to the sessions. Every part of what a dialog must do came from the
library, and the planner wrote a template and three lines of guard.
