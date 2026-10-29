---
title: Zoneless, the planner's way since lesson 2
version: 1
---

**Without zone.js, nothing tells Angular that "something asynchronous happened", so Angular walks the
tree only when something it trusts says a value changed.** That is how the planner has run since
lesson 2: `ng new --zoneless` wrote no zone.js, and Angular 21 is zoneless unless told otherwise. Take
zone.js out of the planner again. `git status` lists the four files the previous section changed,
`git checkout` puts them back as they were in the last commit, and `npm ci` makes `node_modules` match
the lockfile again:

```
ana@dev:~/planner$ git status --short
 M package-lock.json
 M package.json
 M src/app/app.config.ts
 M src/main.ts
ana@dev:~/planner$ git checkout -- .
ana@dev:~/planner$ npm ci

added 474 packages, and audited 475 packages in 8s

2 moderate severity vulnerabilities

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

The same bench, the same timers:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --wait 1000
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Bench

default, plain field: 0

OnPush, plain field: 0

OnPush, signal: 1
```

**Now the default component kept its 0 as well.** Its timer was the browser's own setTimeout, nobody
was listening, and the field changed in a class no walk visited. The signal still worked: setting it
marked its component and scheduled a walk, and the page showed 1.

What schedules a walk in a zoneless application:

- **a signal read by a template changes**, which is why lesson 6 moved the planner's data into signals
  before this lesson explained it;
- **an event bound in a template fires**, so every `(click)` of lesson 4 still redraws as it did;
- **`markForCheck()` is called**, by you or by something you use, such as the `async` pipe of lesson
  13;
- **a `resource` finishes loading**, since its value is a signal.

**The failure is silent.** A field assigned in a timer, a promise's `then` or a callback from a
library shows its old value until something else happens to trigger a walk, and then jumps. In a
zone.js application the same code worked, which is exactly what makes moving an old application
zoneless the part that needs care: the code that relied on zone.js does not fail, it goes stale.

Here is the plain field made right, the way the planner's code is written:

```typescript
protected readonly count = signal(0);
constructor() {
  setTimeout(() => this.count.set(1), 300);
}
```

and its template reads `{{ count() }}`. That is the whole migration for most components: state that
changes asynchronously goes into a signal.
