---
title: Deferred blocks, lazy loading inside a template
version: 1
---

**`@defer` does for part of a template what `loadChildren` does for part of the routes**: what is
inside the block, and the components it uses, go into a chunk of their own, fetched when a trigger
says so. A chart library that weighs more than the rest of the page, a comments section below the
fold, an editor behind a button: none of them needs to be in the first download.

A bench with a stand-in for something heavy, in a file of its own, as a deferred component has to be:

```
ana@dev:~/planner$ npx ng generate component bench --inline-template --inline-style --skip-tests
CREATE src/app/bench/bench.ts (269 bytes)
```

```typescript
// src/app/bench/chart.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
  selector: 'app-chart',
  template: '<p>The chart is drawn.</p>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Chart {
  constructor() {
    console.log('the chart code has arrived and runs');
  }
}
```

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { Chart } from './chart';

@Component({
  selector: 'app-bench',
  imports: [Chart],
  template: `
    <button type="button" #show>Show the chart</button>
    @defer (on interaction(show)) {
      <app-chart />
    } @placeholder {
      <p>The chart loads when it is asked for.</p>
    } @loading {
      <p>Loading the chart…</p>
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {}
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

`on interaction(show)` fetches the chunk when the button is clicked or focused and Enter pressed.
`@placeholder` is what shows until then, `@loading` while the chunk is on its way. Other triggers
are `on viewport`, when the block scrolls into view, `on idle`, when the browser has nothing else to
do, `on hover`, `on timer(2s)`, and `when` a condition becomes true.

```
ana@dev:~/planner$ look http://localhost:4200/ --scripts --text app-bench
[vite] connecting...
[vite] connected.
NG0751: Angular has detected that this application contains `@defer` blocks and the hot module replacement (HMR) mode is enabled. All `@defer` block dependencies will be loaded eagerly. Find more at https://v21.angular.dev/errors/NG0751
Angular is running in development mode.
scripts: /main.js /chunk-KGABQYFU.js /chunk-5ODBP7SE.js
Show the chart

The chart loads when it is asked for.
```

**`NG0751` says the chart's code was loaded with everything else, before anybody asked for it.** The
dev server replaces changed code in the page without a reload, which is called hot module
replacement, and to do that it loads every deferred block's code at once. The build still splits it:

```
ana@dev:~/planner$ npx ng build 2>&1 | sed -n '/Lazy chunk/,/^$/p'
Lazy chunk files    | Names          |  Raw size | Estimated transfer size
chunk-OGPL5X64.js   | courses-routes |  44.10 kB |                10.16 kB
chunk-XNMGY5HJ.js   | chart          | 387 bytes |               387 bytes
```

To see `@defer` behave in the dev server, stop `ng serve` with `Ctrl-C` and start it with HMR off,
`npx ng serve --no-hmr`. Then the page before the click, and after:

```
ana@dev:~/planner$ look http://localhost:4200/ --scripts --text app-bench
[vite] connecting...
[vite] connected.
Angular is running in development mode.
scripts: /main.js /chunk-OZXTPHRX.js /chunk-VUJOFXKG.js /chunk-CEZKWLVC.js
Show the chart

The chart loads when it is asked for.
```

```
ana@dev:~/planner$ look http://localhost:4200/ --scripts --text app-bench --do 'click Show the chart'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Show the chart
the chart code has arrived and runs
scripts: /main.js /chunk-OZXTPHRX.js /chunk-VUJOFXKG.js /chunk-CEZKWLVC.js /chunk-FDXEIX35.js
Show the chart

The chart is drawn.
```

Before the click, the application's files, the course area among them because it is preloaded, and
the placeholder. After the click, one file more, the chart's chunk, and the chart's own code running
for the first time.

The bench goes, and the dev server goes back to plain `npx ng serve`:

```
ana@dev:~/planner$ rm -r src/app/bench && git checkout -- src/app/app.html src/app/app.ts
```

```
ana@dev:~/planner$ git status --short
 M src/app/add-session/add-session.ts
 M src/app/app.config.ts
 M src/app/app.routes.ts
?? src/app/course-exists.ts
?? src/app/courses.routes.ts
?? src/app/unsaved-work.ts
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "Guards, lazy loading and preloading"
```
