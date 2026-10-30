---
title: NgRx Store, the same idea with more ceremony
version: 1
---

**NgRx is the state library most large Angular applications use, and its Store is the pattern of the
first section with every part made explicit.** The state is one object for the whole application. A
component never calls a method that changes it: it **dispatches an action**, a plain object that says
what happened. A **reducer**, a pure function, takes the state and the action and returns the next
state. **Selectors** read from it. Side effects, such as requests, live in a fourth kind of thing,
NgRx's own effects, outside this overview.

The library is a package like Material, at an exact version that matches Angular 21. Installed for a
bench, to see it run:

```
ana@dev:~/planner$ npm install @ngrx/store@21.1.1

added 1 package, and audited 478 packages in 898ms

found 0 vulnerabilities
```

No vulnerabilities, NgRx's or anybody's: the two that lesson 2's first install counted went with
the patch lesson 2 took, as lesson 7 showed.

```
ana@dev:~/planner$ npx ng generate component bench --inline-template --inline-style --skip-tests
CREATE src/app/bench/bench.ts (269 bytes)
```

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "// src/app/bench/bench.ts\nimport { ChangeDetectionStrategy, Component, inject } from '@angular/core';\nimport { Store, createAction, createFeatureSelector, createReducer, createSelector, on, props } from '@ngrx/store';\n\nexport const minutesAdded = createAction('[Bench] Minutes added', props<{ minutes: number }>());\nexport const cleared = createAction('[Bench] Cleared');", "note": "Actions: a type, by convention `[Source] Event`, and what came with it. They say what happened, not what to do about it."},
 {"code": "export const minutesReducer = createReducer(\n  [] as number[],\n  on(minutesAdded, (state, { minutes }) => [...state, minutes]),\n  on(cleared, () => []),\n);", "note": "The reducer: given the state and an action, the next state. It is pure, so it can be tested with a call, and it never changes the state it was given."},
 {"code": "const selectMinutes = createFeatureSelector<number[]>('minutes');\nconst selectTotal = createSelector(selectMinutes, (minutes) => minutes.reduce((sum, m) => sum + m, 0));", "note": "Selectors read the state, and remember their last answer, as a `computed` does."},
 {"code": "@Component({\n  selector: 'app-bench',\n  template: `\n    <p>{{ minutes().join(' + ') || 'nothing' }} = {{ total() }}</p>\n    <button type=\"button\" (click)=\"add(30)\">Add 30</button>\n    <button type=\"button\" (click)=\"clear()\">Clear</button>\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Bench {\n  private readonly store = inject(Store);\n  protected readonly minutes = this.store.selectSignal(selectMinutes);\n  protected readonly total = this.store.selectSignal(selectTotal);\n\n  protected add(minutes: number): void {\n    this.store.dispatch(minutesAdded({ minutes }));\n  }\n\n  protected clear(): void {\n    this.store.dispatch(cleared());\n  }\n}", "note": "`selectSignal` hands a selector to the template as a signal; `dispatch` is the only way in."}
]}
```

The store is provided for the whole application, with each reducer under the key its state lives at.
This is the `provideStore` lesson 3's table mentioned:

```typescript
// src/app/app.config.ts
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import {
  PreloadAllModules,
  provideRouter,
  withComponentInputBinding,
  withPreloading,
  withRouterConfig,
} from '@angular/router';
import { provideStore } from '@ngrx/store';

import { routes } from './app.routes';
import { minutesReducer } from './bench/bench';
import { requestedBy } from './requested-by';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(
      routes,
      withComponentInputBinding(),
      withRouterConfig({ paramsInheritanceStrategy: 'always' }),
      withPreloading(PreloadAllModules),
    ),
    provideHttpClient(withInterceptors([requestedBy])),
    provideStore({ minutes: minutesReducer }),
  ]
};
```

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<nav aria-label="Planner">
  <a routerLink="/" routerLinkActive="current" [routerLinkActiveOptions]="{ exact: true }" ariaCurrentWhenActive="page">This week</a>
</nav>
<main>
  <router-outlet />
</main>
<app-bench />
```

```typescript
// src/app/app.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { Bench } from './bench/bench';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, RouterLink, RouterLinkActive, Bench],
  templateUrl: './app.html',
  styleUrl: './app.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text 'app-bench p' --do 'click Add 30' --do 'click Add 30' --do 'click Clear' --do 'click Add 30'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Add 30
-- click Add 30
-- click Clear
-- click Add 30
30 = 30
```

The same arithmetic `PlannerStore` would do with a signal and a method, written as two actions, a
reducer, two selectors and a provider. **That ceremony is the product, not a flaw**: every change to the state is an action object, so all of them can be logged, replayed and inspected in a browser extension that shows the state before and after each one. And a team of forty can read any feature the same way. For one person and one planner, it is more code than the problem.

The bench, its provider and the package go:

```
ana@dev:~/planner$ rm -r src/app/bench && git checkout -- src/app/app.html src/app/app.ts src/app/app.config.ts
```

```
ana@dev:~/planner$ npm uninstall @ngrx/store

removed 1 package, and audited 477 packages in 722ms

found 0 vulnerabilities
```
