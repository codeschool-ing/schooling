---
title: One card, the Angular way
version: 1
---

**This lesson builds one small piece of the planner four times, in Angular, React, Vue and Svelte,
and puts the four side by side.** The piece is a card: one course's week, its sessions with a box to
tick, and a line that adds up the minutes. It is small enough to read whole in each framework, and
it has the three parts every framework has to answer for: **state** that changes, the sessions;
**derived values** that follow it, the two totals; and a **template** that draws both and sends the
tick back.

The other three courses of this track, `react-ts`, `vue` and `svelte`, end with the same lesson
from their own side, and they build the same planner. What follows is enough of each framework to
read the card, not to learn the framework: that is what those courses are for.

Each card is a project of its own, in a folder beside the planner. Stop any dev server that is
running, make the folder,

```
ana@dev:~$ mkdir compare
```

and start inside it with the framework this course knows. `--skip-install` because the install is the step
lesson 2 had to work around, and the way round it is the planner's `.npmrc`:

```
ana@dev:~/compare$ npx @angular/cli@21.2.28 new angular --defaults --skip-git --skip-install --ssr=false
CREATE angular/.prettierrc (161 bytes)
CREATE angular/README.md (1461 bytes)
CREATE angular/.editorconfig (314 bytes)
CREATE angular/.gitignore (622 bytes)
CREATE angular/angular.json (1906 bytes)
CREATE angular/package.json (784 bytes)
CREATE angular/tsconfig.json (957 bytes)
CREATE angular/tsconfig.app.json (429 bytes)
CREATE angular/tsconfig.spec.json (441 bytes)
CREATE angular/.vscode/extensions.json (130 bytes)
CREATE angular/.vscode/launch.json (470 bytes)
CREATE angular/.vscode/mcp.json (179 bytes)
CREATE angular/.vscode/tasks.json (978 bytes)
CREATE angular/src/main.ts (222 bytes)
CREATE angular/src/index.html (293 bytes)
CREATE angular/src/styles.css (80 bytes)
CREATE angular/src/app/app.css (0 bytes)
CREATE angular/src/app/app.spec.ts (674 bytes)
CREATE angular/src/app/app.ts (289 bytes)
CREATE angular/src/app/app.html (20144 bytes)
CREATE angular/src/app/app.config.ts (313 bytes)
CREATE angular/src/app/app.routes.ts (77 bytes)
CREATE angular/public/favicon.ico (15086 bytes)
```

```
ana@dev:~/compare/angular$ cp ~/planner/.npmrc .
```

Then the same exact versions as the planner, so the card runs on the Angular this course used:

```
ana@dev:~/compare/angular$ npm install --save-exact @angular/common@21.2.25 @angular/compiler@21.2.25 @angular/core@21.2.25 @angular/forms@21.2.25 @angular/platform-browser@21.2.25 @angular/router@21.2.25 rxjs@7.8.2 tslib@2.8.1 @angular/build@21.2.28 @angular/cli@21.2.28 @angular/compiler-cli@21.2.25 jsdom@28.1.0 prettier@3.9.10 typescript@5.9.3 vitest@4.1.12

added 470 packages, and audited 471 packages in 22s

2 vulnerabilities (1 moderate, 1 high)

To address all issues, run:
  npm audit fix --force

Run `npm audit` for details.
```

The two vulnerabilities are the ones lesson 22 read, in `@angular/build`'s development server. The
card is the whole application, so it is the root component, and nothing else is needed:

```
ana@dev:~/compare/angular$ rm src/app/app.html src/app/app.css src/app/app.spec.ts src/app/app.routes.ts
```

```typescript
// src/app/app.ts: one course's week, the Angular way
import { ChangeDetectionStrategy, Component, computed, signal } from '@angular/core';

@Component({
  selector: 'app-root',
  template: `
    <section>
      <h2>JavaScript</h2>
      <ul>
        @for (s of sessions(); track s.id) {
          <li>
            <label>
              <input type="checkbox" [checked]="s.done" (change)="toggle(s.id)" /> {{ s.date }}, {{ s.minutes }} minutes
            </label>
          </li>
        }
      </ul>
      <p>{{ done() }} of {{ planned() }} minutes done</p>
    </section>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {
  protected readonly sessions = signal([
    { id: 3, date: 'Tue 20 Oct', minutes: 60, done: true },
    { id: 5, date: 'Sat 24 Oct', minutes: 50, done: false },
  ]);
  protected readonly planned = computed(() => this.sessions().reduce((sum, s) => sum + s.minutes, 0));
  protected readonly done = computed(() =>
    this.sessions()
      .filter((s) => s.done)
      .reduce((sum, s) => sum + s.minutes, 0),
  );

  constructor() {
    console.log('Angular: the constructor runs');
  }

  toggle(id: number): void {
    this.sessions.update((all) => all.map((s) => (s.id === id ? { ...s, done: !s.done } : s)));
  }
}
```

```typescript
// src/app/app.config.ts: no router, since the card is the whole page
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';

export const appConfig: ApplicationConfig = {
  providers: [provideBrowserGlobalErrorListeners()],
};
```

Everything here is from this course: a signal for the sessions, two `computed`s, `@for` with a
`track`, a property binding and an event binding, OnPush. The one line it does not need is the
`console.log` in the constructor, which says when the component's code runs; the comparison
section reads it. Start `npx ng serve`, and tick the second session:

```
ana@dev:~/compare/angular$ look http://localhost:4200/ --do 'check Sat 24 Oct, 50 minutes' --text body
[vite] connecting...
[vite] connected.
Angular: the constructor runs
Angular is running in development mode.
-- check Sat 24 Oct, 50 minutes
JavaScript
 Tue 20 Oct, 60 minutes
 Sat 24 Oct, 50 minutes

110 of 110 minutes done
```

**110 of 110, and the constructor ran once**, before the page was drawn. The tick called `toggle`,
which replaced the signal's list; the two `computed`s that read it were marked stale, and the parts
of the template that read those were drawn again. Stop the dev server. The next three sections are
the same card, and the same check, in the other three frameworks.
