---
title: zone.js, and checking everything after everything
version: 1
---

**For its first eight years, Angular answered "when" with a library called zone.js: it wrapped every
asynchronous thing the browser can do, and after any of them finished, Angular walked the whole tree.**
A click, a timer, a server's answer, a promise resolving: zone.js knew, because it had replaced
`setTimeout`, `addEventListener`, `fetch` and the rest with versions that tell Angular when their
callback has run. Nobody had to say that something changed, because Angular assumed something might
have, every time.

Most Angular applications in production still work this way, so it is worth seeing. The planner does
not use zone.js, and adding it is three changes. First, the bench, now with three small components,
each with a counter that a timer sets from 0 to 1:

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "import { ChangeDetectionStrategy, Component, signal } from '@angular/core';\n\n@Component({\n  selector: 'app-tick',\n  template: '<p>default, plain field: {{ count }}</p>',\n})\nexport class Tick {\n  protected count = 0;\n  constructor() {\n    setTimeout(() => (this.count = 1), 300);\n  }\n}", "note": "A component as written before signals: a plain field, set by a timer after 300 milliseconds."},
 {"code": "@Component({\n  selector: 'app-tick-onpush',\n  template: '<p>OnPush, plain field: {{ count }}</p>',\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class TickOnPush {\n  protected count = 0;\n  constructor() {\n    setTimeout(() => (this.count = 1), 300);\n  }\n}", "note": "The same component, with `changeDetection: ChangeDetectionStrategy.OnPush`, which the next section explains."},
 {"code": "@Component({\n  selector: 'app-tick-signal',\n  template: '<p>OnPush, signal: {{ count() }}</p>',\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class TickSignal {\n  protected readonly count = signal(0);\n  constructor() {\n    setTimeout(() => this.count.set(1), 100);\n  }\n}", "note": "OnPush too, with the counter in a signal, set sooner, at 100 milliseconds."},
 {"code": "@Component({\n  selector: 'app-bench',\n  imports: [Tick, TickOnPush, TickSignal],\n  template: '<h2>Bench</h2><app-tick /><app-tick-onpush /><app-tick-signal />',\n})\nexport class Bench {}", "note": "The bench shows the three."}
]}
```

Commit it, so that the next step can be undone exactly:

```
ana@dev:~/planner$ git add -A && git commit -q -m "A bench for change detection"
```

Then zone.js itself, at the version Angular 21 accepts:

```
ana@dev:~/planner$ npm install zone.js@0.16.3

added 1 package, and audited 476 packages in 782ms

found 0 vulnerabilities
```

npm added the package and found nothing to report. The two vulnerabilities lesson 2's first install
counted were in `@angular/build` 21.2.28, and the `ng update` at the end of lesson 2 took 21.2.29,
which carries the fix. `npm audit` agrees:

```
ana@dev:~/planner$ npm audit 2>&1 | head -12
found 0 vulnerabilities
```

That is the case for taking patches as they come rather than when something breaks: the fix arrived
in one, and taking it was one command. The database `npm audit` reads changes every day, so a
project that was clean yesterday can carry a report today without a line of it changing. `front-quality` is the course about reading these reports.

It has to be loaded before anything else, so it goes on the first line of `main.ts`, where it replaces
the browser's asynchronous functions before Angular's code runs:

```typescript
// src/main.ts
import 'zone.js';
import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { App } from './app/app';

bootstrapApplication(App, appConfig)
  .catch((err) => console.error(err));
```

and the application is told to use it, in its configuration:

```typescript
// src/app/app.config.ts
import { ApplicationConfig, provideBrowserGlobalErrorListeners, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';

import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes)
  ]
};
```

`--wait 1000` lets the page run for a second after loading, long enough for both timers:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --wait 1000
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Bench

default, plain field: 1

OnPush, plain field: 0

OnPush, signal: 1
```

**The plain field in the default component showed 1.** Its timer was zone.js's timer; when the
callback finished, zone.js told Angular, and Angular walked the tree and found `count` changed. That
is the convenience zone.js bought: assign to any field, from anywhere asynchronous, and the page
follows.

It also cost something on every page. zone.js is code the browser downloads and runs before the application starts. And a walk of the whole tree after every timer, every mouse move a listener sees and every resolved promise is work done whether anything changed or not. And the middle line already
shows the trouble: the OnPush component kept its 0, for a reason the next section gives.
