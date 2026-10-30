---
title: An Observable is a function that has not been called yet
version: 1
---

**An Observable is a description of values that will arrive over time, and nothing happens until
somebody subscribes to it.** Lesson 12 met one without dwelling on it: `http.patch` returned an
Observable, and the request went out only when `subscribe` was called. RxJS, the library Angular
uses for them, is installed in every Angular project; `rxjs` has been in `package.json` since
lesson 2.

Three things set an Observable apart, and a bench shows all three. Making one by hand shows what it
is: a function that is given a **subscriber** and calls `next` on it with each value, and
`complete` at the end.

```
ana@dev:~/planner$ npx ng generate component bench --inline-template --inline-style --skip-tests
CREATE src/app/bench/bench.ts (269 bytes)
```

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "import { HttpClient } from '@angular/common/http';\nimport { ChangeDetectionStrategy, Component, inject } from '@angular/core';\nimport { Observable } from 'rxjs';\nimport { PlannerData } from '../planner';\n\n@Component({\n  selector: 'app-bench',\n  template: '',\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Bench {\n  constructor() {", "note": "`Observable` comes from `rxjs`, not from Angular."},
 {"code": "    const numbers = new Observable<number>((subscriber) => {\n      console.log('subscribed');\n      subscriber.next(1);\n      subscriber.next(2);\n      setTimeout(() => {\n        subscriber.next(3);\n        subscriber.complete();\n      }, 100);\n    });", "note": "The function inside runs once per subscriber. Two values at once, a third a tenth of a second later, then the end."},
 {"code": "    console.log('before subscribe');\n    numbers.subscribe({ next: (n) => console.log('got', n), complete: () => console.log('done') });\n    console.log('after subscribe');", "note": "`subscribe` takes an object with a callback for each kind of event: a value, an error, the end."},
 {"code": "    const planner = inject(HttpClient).get<PlannerData>('/api/planner');\n    planner.subscribe();\n    planner.subscribe();\n  }\n}", "note": "One request described, and subscribed to twice."}
]}
```

The bench goes into `App` beside the two screens:

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<main>
  <app-week />
  <app-course-page courseId="javascript" />
  <app-bench />
</main>
<router-outlet />
```

```typescript
// src/app/app.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { Bench } from './bench/bench';
import { CoursePage } from './course-page/course-page';
import { Week } from './week/week';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, Week, CoursePage, Bench],
  templateUrl: './app.html',
  styleUrl: './app.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --network --wait 1000
[vite] connecting...
[vite] connected.
before subscribe
subscribed
got 1
got 2
after subscribe
Angular is running in development mode.
net  GET /api/planner  200
net  GET /api/planner  200
net  GET /api/planner  200
got 3
done
```

**It is lazy.** `subscribed` comes after `before subscribe`: making the Observable ran nothing, and
the function inside ran when `subscribe` was called. **It can be synchronous, asynchronous or
both.** `got 1` and `got 2` arrived before `subscribe` even returned, and `got 3` a moment later,
after everything else on the page. **It is cold.** Three requests for `/api/planner`, the store's
and two more: every `subscribe` ran the function again, and for an `HttpClient` Observable that
function sends a request. Two subscribers means two requests, which is right for a request and
surprising the first time it costs a second one.

## Against what you already know

| | gives | when it starts | how many values | has a current value |
|---|---|---|---|---|
| a `Promise` | one value, or an error | at once, when made | one | no |
| a `signal` | the value now | it always has one | one at a time, each replacing the last | yes |
| an `Observable` | values as they happen, an error, an end | when subscribed, once per subscriber | none, one, or any number | no |

A signal answers "what is it now". An Observable answers "what happens, and when". The planner's
data is the first kind of question, which is why lessons 6 to 12 needed so little of RxJS. The
rest of this lesson is the second kind.
