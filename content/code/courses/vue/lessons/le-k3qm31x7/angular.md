---
title: Angular
version: 1
---

**Angular is a whole platform, a framework, its own command-line tool, a router, forms and a test setup,
and its components are TypeScript classes with a template beside them.** Since Angular 17 its templates
have their own control flow, `@for` and `@if`, and its reactivity, since signals arrived in Angular 16,
is more and more **signals**, which are close kin of Vue's refs. Its project generator is the Angular
CLI, run at a fixed version:

```
ana@dev:~/vue/compare$ npx --yes @angular/cli@22.2.4 new angular --defaults --skip-git --skip-install --ssr=false
CREATE angular/.prettierrc (161 bytes)
CREATE angular/README.md (1460 bytes)
CREATE angular/.editorconfig (314 bytes)
CREATE angular/.gitignore (622 bytes)
CREATE angular/angular.json (1906 bytes)
CREATE angular/package.json (782 bytes)
CREATE angular/tsconfig.json (908 bytes)
CREATE angular/tsconfig.app.json (398 bytes)
CREATE angular/tsconfig.spec.json (409 bytes)
CREATE angular/.vscode/extensions.json (130 bytes)
CREATE angular/.vscode/launch.json (470 bytes)
CREATE angular/.vscode/tasks.json (978 bytes)
CREATE angular/src/main.ts (222 bytes)
CREATE angular/src/index.html (293 bytes)
CREATE angular/src/styles.css (80 bytes)
CREATE angular/src/app/app.css (0 bytes)
CREATE angular/src/app/app.spec.ts (681 bytes)
CREATE angular/src/app/app.ts (290 bytes)
CREATE angular/src/app/app.html (20144 bytes)
CREATE angular/src/app/app.config.ts (312 bytes)
CREATE angular/src/app/app.routes.ts (77 bytes)
CREATE angular/public/favicon.ico (15086 bytes)
```

`--defaults` takes the default answer to every question the CLI would ask, and `--ssr=false` leaves
out server rendering, which Angular can do as Nuxt does. Install, and pin the framework's
packages at 22.2.3; the CLI and the build tool are released apart from them, and are at 22.2.4:

```
ana@dev:~/vue/compare/angular$ npm install

added 281 packages, and audited 282 packages in 13s

84 packages are looking for funding
  run `npm fund` for details

2 vulnerabilities (1 low, 1 high)

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/vue/compare/angular$ npm install --save-exact @angular/common@22.2.3 @angular/compiler@22.2.3 @angular/core@22.2.3 @angular/forms@22.2.3 @angular/platform-browser@22.2.3 @angular/router@22.2.3

added 7 packages, and audited 289 packages in 1s

86 packages are looking for funding
  run `npm fund` for details

2 vulnerabilities (1 low, 1 high)

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

## Two vulnerabilities, and one of them matters

This time the audit is worth more than the minute lesson 18 gave it:

```
ana@dev:~/vue/compare/angular$ npm audit
# npm audit report

vite  8.3.0 - 8.3.2
Severity: high
launch-editor: escapeCmdArgs() omits % escaping on Windows - https://github.com/advisories/GHSA-698v-4r3x-3vcv
launch-editor: Editor CLI flag misinterpretation causing arbitrary command execution for some editors - https://github.com/advisories/GHSA-r825-w8mm-5pxw
launch-editor: `fs.existsSync()` existence check can be bypassed on Windows - https://github.com/advisories/GHSA-587h-7wmj-h5pm
Vite: Cross origin script execution through Vite custom middleware - https://github.com/advisories/GHSA-9jrq-w75r-8gcw
Vite: Files outside `server.fs.allow` could be served when project paths match system paths on non-Windows machine - https://github.com/advisories/GHSA-rq7h-c2jc-7f22
Vite: First 4 bytes of files outside of `server.fs` setting is exposed by `?vite-wasm-instance` - https://github.com/advisories/GHSA-vfpm-58rq-9qcg
fix available via `npm audit fix --force`
Will install @angular/build@22.1.9, which is a breaking change
node_modules/@angular/build/node_modules/vite
  @angular/build  22.2.0-next.0 - 22.3.0-next.1
  Depends on vulnerable versions of vite
  node_modules/@angular/build

2 vulnerabilities (1 low, 1 high)

To address all issues (including breaking changes), run:
  npm audit fix --force
```

**The Vite inside Angular's build tool is 8.3.0 to 8.3.2, and the advisories are about the dev server**:
one is about a script from another origin run through the server's middleware, others about files served
from outside the folders it is allowed to serve. That is the server you leave running on your computer
while you browse, so *it only runs on localhost* is no comfort here. The fix the audit offers,
`--force`, would move `@angular/build` back to 22.1.9, an older minor version than the rest of Angular
in the project. The planner's own Vite, 8.3.5, already has the fixes, and npm can be told to use it
everywhere in this project with an **override**:

```
ana@dev:~/vue/compare/angular$ npm pkg set overrides.vite=8.3.5
ana@dev:~/vue/compare/angular$ npm install

removed 1 package, and audited 288 packages in 4s

85 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/vue/compare/angular$ npm ls vite
angular@0.0.0 /home/ana/vue/compare/angular
├─┬ @angular/build@22.2.4
│ ├─┬ @vitejs/plugin-basic-ssl@2.3.0
│ │ └── vite@8.3.5 deduped
│ └── vite@8.3.5 overridden
└─┬ vitest@5.0.5
  ├─┬ @vitest/mocker@5.0.5
  │ └── vite@8.3.5 deduped
  └── vite@8.3.5 deduped
```

**`overridden`, and no vulnerabilities**: every package that asked for a Vite now gets 8.3.5. An
override is a decision you have taken over a dependency's head, so it is worth writing down why, and
taking out once `@angular/build` ships the fix itself; the next `npm audit` after an update says when.

## The card

```typescript
// src/app/week-card.ts: one course's week, the Angular way.
import { Component, computed, signal } from '@angular/core'

@Component({
  selector: 'app-root',
  template: `
    <section>
      <h2>Spanish</h2>
      <ul>
        @for (s of sessions(); track s.id) {
          <li>
            <label>
              <input type="checkbox" [checked]="s.done" (change)="toggle(s.id)" />
              {{ s.date }}, {{ s.minutes }} minutes
            </label>
          </li>
        }
      </ul>
      <p>{{ done() }} of {{ planned() }} minutes done</p>
    </section>
  `,
})
export class WeekCard {
  readonly sessions = signal([
    { id: 's3', date: '19 October', minutes: 30, done: true },
    { id: 's6', date: '23 October', minutes: 40, done: false },
  ])
  readonly planned = computed(() => this.sessions().reduce((sum, s) => sum + s.minutes, 0))
  readonly done = computed(() =>
    this.sessions()
      .filter((s) => s.done)
      .reduce((sum, s) => sum + s.minutes, 0),
  )

  constructor() {
    console.log('Angular: the constructor runs')
  }

  toggle(id: string) {
    this.sessions.update((list) => list.map((s) => (s.id === id ? { ...s, done: !s.done } : s)))
  }
}
```

The entry starts the application with the card as its root, in the template's `<app-root>`:

```typescript
// src/main.ts: the card is the whole application.
import { bootstrapApplication } from '@angular/platform-browser'
import { WeekCard } from './app/week-card'

bootstrapApplication(WeekCard).catch((err) => console.error(err))
```

Against the Vue card:

- **`signal([...])`** is a `ref`, read by calling it, `this.sessions()`, rather than with `.value`, and
  changed with `.set` or `.update`. The update here builds a new list, as React's does, because a
  signal notices a new value and not a change inside the old one.
- **`computed(() => ...)`** is Vue's `computed`, with the same name, the same caching and the same
  automatic tracking of what it read.
- **`[checked]` and `(change)`** are Angular's binding syntax: square brackets for a value into an
  element, round ones for an event out of it. `[(ngModel)]` would be the two-way form, from the
  forms package, and the card does without it.
- **`@for (...; track s.id)`** is `v-for` with its `key`, and Angular makes the `track` compulsory.

`npm start` runs `ng serve`, on port `4200`:

```
ana@dev:~/vue/compare/angular$ npm start

> angular@0.0.0 start
> ng serve

❯ Building...
✔ Building...
Initial chunk files | Names         | Raw size
main.js             | main          |  5.48 kB | 
styles.css          | styles        | 95 bytes | 

                    | Initial total |  5.57 kB

Application bundle generation complete. [2.022 seconds] - 2026-10-24T01:17:37.717Z

Watch mode enabled. Watching for file changes...
NOTE: Raw file sizes do not reflect development server per-request transformations.
  ➜  Local:   http://localhost:4200/
10:17:38 PM [vite] (client) [optimizer] bundling dependencies...
```

```
ana@dev:~/vue/compare/angular$ look http://localhost:4200/ --do 'check text=23 October' --text body
[vite] connecting...
[vite] connected.
Angular: the constructor runs
Angular is running in development mode.
-- check text=23 October
== the text of body
Spanish
 19 October, 30 minutes
 23 October, 40 minutes

70 of 70 minutes done
```

**`[vite] connecting...` on an Angular page**: `ng serve` is Vite's development server, under Angular's
own build. And the constructor ran once, as Vue's setup did; the tick redrew what read the signals.
