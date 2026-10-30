---
title: Outputs, events passed up
version: 1
---

**An output is an event a component announces, which its parent listens to with `(name)="…"`.**
Inputs carry data down; outputs carry news up. A child does not change its parent's data: it says
what happened, and the parent, which owns the data, decides what to do. The planner needs one: a
session marked done.

## A row that says it was ticked

Each session gets a row with a checkbox:

```
ana@dev:~/planner$ npx ng generate component session-row --inline-template --inline-style --skip-tests
CREATE src/app/session-row/session-row.ts (286 bytes)
```

```typescript
// src/app/session-row/session-row.ts
import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { Session } from '../planner';

@Component({
  selector: 'app-session-row',
  imports: [],
  template: `
    <label>
      <input type="checkbox" [checked]="session().done" (change)="changed($event)" />
      {{ session().date }}, {{ session().minutes }} minutes
    </label>
  `,
  styles: ``,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SessionRow {
  readonly session = input.required<Session>();
  readonly toggled = output<boolean>();

  protected changed(event: Event): void {
    this.toggled.emit((event.target as HTMLInputElement).checked);
  }
}
```

**`output<boolean>()`** declares an event that carries a boolean, and `emit` announces it. The row does
not set `session().done` itself: the session is an input, read-only to the row, and the data belongs
to whoever passed it.

The list passes the news on, adding which session it was about:

```typescript
// src/app/session-list/session-list.ts
import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { Session } from '../planner';
import { SessionRow } from '../session-row/session-row';

@Component({
  selector: 'app-session-list',
  imports: [SessionRow],
  template: `
    <ul>
      @for (session of sessions(); track session.id) {
        <li><app-session-row [session]="session" (toggled)="toggled.emit({ id: session.id, done: $event })" /></li>
      } @empty {
        <li>No sessions yet.</li>
      }
    </ul>
  `,
  styles: ``,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SessionList {
  readonly sessions = input.required<Session[]>();
  readonly toggled = output<{ id: number; done: boolean }>();
}
```

In `(toggled)="…"`, **`$event` is what the child emitted**, the boolean, not a DOM event: for a
component's output, `$event` is whatever was passed to `emit`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"The course page at the top holds the data. An arrow labelled sessions goes down to the session list, and an arrow labelled session goes down from the list to each row. From a row, an arrow labelled toggled, carrying true, goes up to the list, and from the list an arrow labelled toggled, carrying the id and done, goes up to the page, which updates its data. The new data then flows down again.\"><rect x=\"250\" y=\"20\" width=\"220\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CoursePage</text><text x=\"360.0\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">owns the data</text><rect x=\"250\" y=\"120\" width=\"220\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SessionList</text><text x=\"360.0\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">passes it on</text><rect x=\"250\" y=\"220\" width=\"220\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SessionRow</text><text x=\"360.0\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one per session</text><line x1=\"300\" y1=\"66\" x2=\"300\" y2=\"118\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,118.0 296.9,110.6 303.1,110.6\" fill=\"var(--phosphor)\"></polygon><text x=\"292\" y=\"92\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">[sessions]</text><line x1=\"300\" y1=\"166\" x2=\"300\" y2=\"218\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,218.0 296.9,210.6 303.1,210.6\" fill=\"var(--phosphor)\"></polygon><text x=\"292\" y=\"192\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">[session]</text><text x=\"120\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">data goes down,</text><text x=\"120\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">through inputs</text><line x1=\"420\" y1=\"218\" x2=\"420\" y2=\"168\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"420.0,168.0 423.1,175.4 416.9,175.4\" fill=\"var(--amber)\"></polygon><text x=\"428\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">(toggled) true</text><line x1=\"420\" y1=\"118\" x2=\"420\" y2=\"68\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"420.0,68.0 423.1,75.4 416.9,75.4\" fill=\"var(--amber)\"></polygon><text x=\"428\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">(toggled) { id, done }</text><text x=\"620\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">news goes up,</text><text x=\"620\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">through outputs</text><text x=\"360\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the owner updates its data, and the new value flows down again</text></svg>", "caption": "Inputs carry data down; outputs carry news up; only the owner changes the data."}
```

## The owner changes the data

The course page owns the data, so the change happens there. A `resource`'s value is a writable signal,
and `update` replaces it with a new one, a new array with a new object for the changed session, as
lesson 6 required:

```typescript
// src/app/course-page/course-page.ts
import { ChangeDetectionStrategy, Component, computed, input, resource } from '@angular/core';
import { loadPlanner } from '../planner';
import { SessionList } from '../session-list/session-list';

@Component({
  selector: 'app-course-page',
  imports: [SessionList],
  templateUrl: './course-page.html',
  styleUrl: './course-page.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CoursePage {
  readonly courseId = input.required<string>();
  protected readonly data = resource({ loader: loadPlanner });
  protected readonly course = computed(() =>
    this.data.value()?.courses.find((c) => c.id === this.courseId()),
  );
  protected readonly sessions = computed(() =>
    (this.data.value()?.sessions ?? [])
      .filter((s) => s.courseId === this.courseId())
      .sort((a, b) => a.date.localeCompare(b.date)),
  );

  protected toggle(id: number, done: boolean): void {
    this.data.update((data) =>
      data && { ...data, sessions: data.sessions.map((s) => (s.id === id ? { ...s, done } : s)) },
    );
  }
}
```

```html
<!-- src/app/course-page/course-page.html -->
@if (data.isLoading()) {
  <p>Loading the course…</p>
} @else if (data.error(); as error) {
  <p>The course could not be loaded: {{ error.message }}</p>
} @else if (course(); as course) {
  <h2>{{ course.name }}</h2>
  <app-session-list [sessions]="sessions()" (toggled)="toggle($event.id, $event.done)" />
} @else {
  <p>There is no course called {{ courseId() }}.</p>
}
```

Saturday's JavaScript session is not done yet. Tick it:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --a11y main --do 'check 2026-10-24, 50 minutes'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- check 2026-10-24, 50 minutes
- main
  - heading "This week" [level=2]
  - paragraph
    - text: 165 minutes planned, 90 done.
  - paragraph
    - text: 75 minutes to go.
  - LabelText
    - text: Done this week
  - progressbar "Done this week": 90
  - heading "Courses" [level=3]
  - list
    - listitem [level=1]
      - ListMarker "• "
      - text: HTML and CSS
      - text: : 30 minutes
    - listitem [level=1]
      - ListMarker "• "
      - text: JavaScript
      - text: : 110 minutes
    - listitem [level=1]
      - ListMarker "• "
      - text: Git
      - text: : 25 minutes
  - heading "JavaScript" [level=2]
  - list
    - listitem [level=1]
      - ListMarker "• "
      - checkbox " 2026-10-13, 45 minutes" [checked]
    - listitem [level=1]
      - ListMarker "• "
      - checkbox " 2026-10-20, 60 minutes" [checked]
    - listitem [level=1]
      - ListMarker "• "
      - checkbox " 2026-10-24, 50 minutes" [focused] [checked]
```

The box on the 24th is checked, because the course page's data now says so. **And the week above still
says 90 done**, not 140. The week has its own copy of the data, loaded separately, and nothing told it.
Two components each holding the truth is the problem lesson 6 predicted, and it has now produced a
screen that contradicts itself. Lesson 11 gives the data one owner that both screens share, and lesson
12 sends the change to a server so that it survives a reload, which today it does not.

## The outputs you will still meet

Before Angular 17.3, an output was a decorated `EventEmitter`:

```typescript
@Output() toggled = new EventEmitter<boolean>();
```

It is used the same way, `emit` and `(toggled)`, and `ng generate @angular/core:output-migration`
rewrites it into `output()`.
