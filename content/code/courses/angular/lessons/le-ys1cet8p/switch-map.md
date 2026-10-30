---
title: A search box, and what switchMap is for
version: 1
---

**A search box is the problem RxJS is best at: a stream of keystrokes, each of which could start a
request, where only the answer to the last one matters.** Signals hold the latest value well, and
have nothing to say about time: how long to wait, what to do with a request that is already on its
way when the next key arrives.

The bench gets an input for finding a course by name. The query is a signal, as any state is;
`toObservable` turns it into an Observable of its values, and `toSignal` turns the end of the chain
back into a signal the template can read. Both come from `@angular/core/rxjs-interop`, Angular's
bridge between the two:

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "import { HttpClient } from '@angular/common/http';\nimport { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';\nimport { toObservable, toSignal } from '@angular/core/rxjs-interop';\nimport { map, switchMap } from 'rxjs';\nimport { PlannerData } from '../planner';\n\n@Component({\n  selector: 'app-bench',\n  template: `\n    <label for=\"find\">Find a course</label>\n    <input id=\"find\" [value]=\"query()\" (input)=\"query.set($any($event.target).value)\" />\n    <p>{{ found()?.join(', ') ?? 'nothing yet' }}</p>\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Bench {\n  private readonly http = inject(HttpClient);\n  protected readonly query = signal('');", "note": "`$any` tells the template compiler to accept `$event.target` without its type: it is an input, and this is the shortest way to say so in a template."},
 {"code": "  protected readonly found = toSignal(\n    toObservable(this.query).pipe(\n      switchMap((q) =>\n        this.http.get<PlannerData>('/api/planner').pipe(\n          map((data) => data.courses.filter((c) => c.name.toLowerCase().includes(q.toLowerCase())).map((c) => c.name)),\n        ),\n      ),\n    ),\n  );\n}", "note": "Every value of the query becomes a request, and every answer becomes the names that match. `toSignal` subscribes, and unsubscribes when the bench is destroyed; until the first answer, its value is `undefined`."}
]}
```

`--wait 100` lets a tenth of a second pass between the actions, about as fast as a person types.
`fill` puts a `J` in the box, and `press` types two more letters:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --network --wait 100 --do 'fill Find a course = J' --do 'press a' --do 'press v'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /api/planner  200
net  GET /api/planner  200
-- fill Find a course = J
net  GET /api/planner  200
-- press a
net  GET /api/planner  200
-- press v
net  GET /api/planner  200
Find a course

JavaScript
```

A request for every value the query had, the empty one it started with included, for an answer only
the last of them needed. A real API searching a real catalogue would do the work four times.

## Waiting for a pause

`debounceTime(300)` holds each value for 300 milliseconds and passes it on only if no other value
came in the meantime. One operator, before `switchMap`:

```typescript
// src/app/bench/bench.ts
import { HttpClient } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { toObservable, toSignal } from '@angular/core/rxjs-interop';
import { debounceTime, map, switchMap } from 'rxjs';
import { PlannerData } from '../planner';

@Component({
  selector: 'app-bench',
  template: `
    <label for="find">Find a course</label>
    <input id="find" [value]="query()" (input)="query.set($any($event.target).value)" />
    <p>{{ found()?.join(', ') ?? 'nothing yet' }}</p>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  private readonly http = inject(HttpClient);
  protected readonly query = signal('');
  protected readonly found = toSignal(
    toObservable(this.query).pipe(
      debounceTime(300),
      switchMap((q) =>
        this.http.get<PlannerData>('/api/planner').pipe(
          map((data) => data.courses.filter((c) => c.name.toLowerCase().includes(q.toLowerCase())).map((c) => c.name)),
        ),
      ),
    ),
  );
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --network --wait 100 --do 'fill Find a course = J' --do 'press a' --do 'press v' --do 'wait 600'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /api/planner  200
-- fill Find a course = J
-- press a
-- press v
-- wait 600
net  GET /api/planner  200
Find a course

JavaScript
```

One request, the store's aside, sent 300 milliseconds after the last key.

## Why switchMap and not one of its cousins

Each of the four `...Map` operators turns a value into an inner Observable, here a request. They
differ in what they do when a new value arrives while the last request is still out:

| operator | a new value while a request is out | right for |
|---|---|---|
| `switchMap` | cancels the old request and starts the new one | a search, where an old answer is a wrong answer |
| `mergeMap` | starts the new one and keeps both | independent work, where every answer counts |
| `concatMap` | waits for the old one to finish, then starts the new one | writes that must happen in order |
| `exhaustMap` | ignores the new value until the old one is done | a submit button pressed twice |

The local API answers in milliseconds, so nothing above was ever overtaken. Over a real network it
happens: the request for `Ja` is slow, the one for `Jav` is quick, and with `mergeMap` the slow
answer lands last and the screen shows the results for `Ja` under a box that says `Jav`.
`switchMap` makes that impossible, because the request for `Ja` was cancelled when `Jav` arrived.
