---
title: Between Observables and signals, and the async pipe
version: 1
---

**An Observable that is subscribed to has to be unsubscribed from, or it outlives what started
it.** Lesson 9's clock kept ticking after its component was gone; a subscription does the same. A
request completes by itself after its answer, so forgetting one costs little. `interval`, a
`toObservable` of a signal, the events of a form: those go on until somebody unsubscribes, and the
somebody is the code that subscribed.

There are three ways to have it done for you, and the bench has used one of them already.

**`toSignal(observable)`** subscribes at once and unsubscribes when the component, or the service,
that made it is destroyed. What comes out is a signal like any other: a template reads it, a
`computed` reads it. It is the default in new code, because the rest of a modern component is
signals.

**`takeUntilDestroyed()`** is an operator, from the same package, for a subscription that has to
be written out, because what it does is a side effect rather than a value:

```typescript
constructor() {
  interval(1000)
    .pipe(takeUntilDestroyed())
    .subscribe(() => console.log('still here'));
}
```

It completes the chain when the component is destroyed. Called outside a constructor or a field it
needs to be given the component's `DestroyRef`, for the reason lesson 10 gave about `inject`.

**The `async` pipe** is the third, and the one most existing Angular code uses. It subscribes in the
template, shows the latest value, and unsubscribes when the element goes:

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "import { AsyncPipe } from '@angular/common';\nimport { HttpClient } from '@angular/common/http';\nimport { ChangeDetectionStrategy, Component, inject } from '@angular/core';\nimport { map } from 'rxjs';\nimport { PlannerData } from '../planner';\n\n@Component({\n  selector: 'app-bench',\n  imports: [AsyncPipe],\n  template: '<p>Sessions left to do: {{ left$ | async }}</p>',\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Bench {", "note": "A pipe has to be imported into the component, like a component. Lesson 19 is about pipes."},
 {"code": "  protected readonly left$ = inject(HttpClient)\n    .get<PlannerData>('/api/planner')\n    .pipe(map((data) => data.sessions.filter((s) => !s.done).length));\n}", "note": "The `$` at the end of the name is a convention, not syntax: it says the field is an Observable, so a reader knows to subscribe rather than read."}
]}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Sessions left to do: 3
```

The pipe marks the component for checking whenever a value arrives, so it works under `OnPush` and
without zone.js. Two `| async` on the same Observable in one template subscribe twice, and since the
Observable is cold, that is two requests; `@if (left$ | async; as left)` subscribes once and names
the value for the block inside. With `toSignal` the question does not come up: one subscription,
read as often as you like.
