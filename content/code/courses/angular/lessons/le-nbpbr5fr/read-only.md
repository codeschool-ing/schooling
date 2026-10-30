---
title: Signals out, methods in
version: 1
---

**A store is only one copy if nothing outside it can change the copy behind its back.** Every
component that injects `PlannerStore` gets the same instance, so a component that could write to its
data directly would change it for every screen, in a way the store never sees and cannot check. The
store above is shaped so that it cannot happen, and the compiler says so when somebody tries.

A method in `CoursePage` that tries both ways in:

```typescript
// src/app/course-page/course-page.ts
import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { PlannerStore } from '../planner-store';
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
  protected readonly store = inject(PlannerStore);
  protected readonly course = computed(() => this.store.courses().find((c) => c.id === this.courseId()));
  protected readonly sessions = computed(() =>
    this.store
      .sessions()
      .filter((s) => s.courseId === this.courseId())
      .sort((a, b) => a.date.localeCompare(b.date)),
  );

  protected clear(): void {
    this.store.sessions.set([]);
    this.store.data.set(undefined);
  }
}
```

```
ana@dev:~/planner$ npx ng build 2>&1 | grep -A4 ERROR
✘ [ERROR] TS2339: Property 'set' does not exist on type 'Signal<Session[]>'. [plugin angular-compiler]

    src/app/course-page/course-page.ts:25:24:
      25 │     this.store.sessions.set([]);
         ╵                         ~~~
--
✘ [ERROR] TS2341: Property 'data' is private and only accessible within class 'PlannerStore'. [plugin angular-compiler]

    src/app/course-page/course-page.ts:26:15:
      26 │     this.store.data.set(undefined);
         ╵                ~~~~
```

**`sessions` is a `computed`, and a `computed` has no `set`.** Its type is `Signal<Session[]>`,
which can be read and nothing else: the value is worked out from the resource, so the only way to
change it is to change the resource. And the resource is `private`, so only the store's own
methods can. Two errors, both at build time, before anybody ran anything.

The shape has a name in most state libraries, and it is worth having one here: **signals out,
methods in**. Whatever the rest of the application reads is a read-only signal; whatever it may
do is a method with a name, `toggle`, that says what it does and is the one place that does it.
When lesson 14 adds a form for new sessions, it calls `store.add(...)`, and lesson 12 turns
`toggle` into a request to a server, without either component changing.

When the state is a plain `signal` rather than a resource, `asReadonly()` gives the same
protection: `readonly sessions = this.state.asReadonly();` hands out a `Signal` that reads the
writable one and cannot write it.

The method goes, and `course-page.ts` goes back to what it was in the last section:

```typescript
// src/app/course-page/course-page.ts
import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { PlannerStore } from '../planner-store';
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
