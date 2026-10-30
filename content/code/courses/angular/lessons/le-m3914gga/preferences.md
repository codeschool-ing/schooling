---
title: A second store, for a preference
version: 1
---

**A preference is state like any other, and it gets the same shape.** The course page lists every
session, done or not; somebody planning what is left wants to hide the ones already done, and wants
the choice to stay when they open another course. That is state shared between visits to different
courses, so it belongs in a service, not in `CourseSessions`.

```schooling-example
{"language": "typescript", "file": "src/app/preferences.ts", "parts": [
 {"code": "// src/app/preferences.ts\nimport { Injectable, computed, signal } from '@angular/core';\n\ninterface Saved {\n  hideDone: boolean;\n}\n\n@Injectable({ providedIn: 'root' })\nexport class Preferences {\n  private readonly state = signal<Saved>({ hideDone: false });\n  readonly hideDone = computed(() => this.state().hideDone);\n\n  setHideDone(hide: boolean): void {\n    this.state.update((saved) => ({ ...saved, hideDone: hide }));\n  }\n}", "note": "The same shape as `PlannerStore`, small: private state, a read-only signal out, a method in."}
]}
```

The course's sessions read it, and offer the box that sets it. `shown` is a `computed` over two stores
at once, which signals make unremarkable:

```typescript
// src/app/course-sessions/course-sessions.ts
import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { MatCheckbox } from '@angular/material/checkbox';
import { PlannerStore } from '../planner-store';
import { Preferences } from '../preferences';
import { SessionList } from '../session-list/session-list';

@Component({
  selector: 'app-course-sessions',
  imports: [MatCheckbox, SessionList],
  template: `
    @if (store.saveError(); as message) {
      <p role="alert">{{ message }}</p>
    }
    <mat-checkbox [checked]="preferences.hideDone()" (change)="preferences.setHideDone($event.checked)">
      Hide sessions that are done
    </mat-checkbox>
    <app-session-list [sessions]="shown()" (toggled)="store.toggle($event.id, $event.done)" />
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CourseSessions {
  readonly courseId = input.required<string>();
  protected readonly store = inject(PlannerStore);
  protected readonly preferences = inject(Preferences);
  protected readonly sessions = computed(() =>
    this.store
      .sessions()
      .filter((s) => s.courseId === this.courseId())
      .sort((a, b) => a.date.localeCompare(b.date)),
  );
  protected readonly shown = computed(() =>
    this.preferences.hideDone() ? this.sessions().filter((s) => !s.done) : this.sessions(),
  );
}
```

The box ticked on JavaScript's page, then a link to the week and a click on Git, which has no session
done; and back to JavaScript, by address, which loads the application again:

```
ana@dev:~/planner$ look http://localhost:4200/courses/javascript --today 2026-10-23 --text app-course-sessions --do 'check Hide sessions that are done' --do 'click This week' --do 'click JavaScript'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- check Hide sessions that are done
-- click This week
-- click JavaScript
Hide sessions that are done
Sat 24 Oct, 50 minutes
```

```
ana@dev:~/planner$ look http://localhost:4200/courses/javascript --today 2026-10-23 --text app-course-sessions --do 'check Hide sessions that are done' --do 'go /courses/javascript'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- check Hide sessions that are done
-- go /courses/javascript
[vite] connecting...
Angular is running in development mode.
[vite] connected.
Hide sessions that are done
Tue 13 Oct, 45 minutes
Tue 20 Oct, 1 hour
Sat 24 Oct, 50 minutes
```

The first kept the choice from one page of the application to the next, because the service outlived
the components. The second lost it: loading the application again made a new `Preferences`, with
the state it starts with. A preference that is forgotten on every visit is half a preference.
