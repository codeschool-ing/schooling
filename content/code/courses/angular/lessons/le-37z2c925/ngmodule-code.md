---
title: The NgModule code you will still meet
version: 1
---

**Before standalone components, every component belonged to an NgModule, and the module, not the
component, decided what its template could use.** Standalone components arrived as a preview in
Angular 14, became stable in 15 and the default in 19, but an application written in 2020 and still earning money in
2026 is full of modules, and the first ticket you pick up at work may well be in one. This section
builds a small one so that you have seen every part before you meet them in somebody else's code.

## A project the old way

`--standalone=false` asks `ng new` for a module-based application. It is a second project, so it
gets the planner's two fixes, the `.npmrc` and the exact versions, copied from `~/planner` rather
than typed again:

```
ana@dev:~$ npx @angular/cli@21.2.28 new legacy --standalone=false --style=css --ssr=false --zoneless --ai-config=none --skip-install --skip-git
CREATE legacy/.prettierrc (161 bytes)
CREATE legacy/README.md (1460 bytes)
CREATE legacy/.editorconfig (314 bytes)
CREATE legacy/.gitignore (622 bytes)
CREATE legacy/angular.json (2156 bytes)
CREATE legacy/package.json (783 bytes)
CREATE legacy/tsconfig.json (957 bytes)
CREATE legacy/tsconfig.app.json (429 bytes)
CREATE legacy/tsconfig.spec.json (436 bytes)
CREATE legacy/.vscode/extensions.json (130 bytes)
CREATE legacy/.vscode/launch.json (470 bytes)
CREATE legacy/.vscode/mcp.json (179 bytes)
CREATE legacy/.vscode/tasks.json (978 bytes)
CREATE legacy/src/main.ts (198 bytes)
CREATE legacy/src/index.html (292 bytes)
CREATE legacy/src/styles.css (80 bytes)
CREATE legacy/src/app/app-routing-module.ts (245 bytes)
CREATE legacy/src/app/app-module.ts (437 bytes)
CREATE legacy/src/app/app.css (0 bytes)
CREATE legacy/src/app/app.spec.ts (801 bytes)
CREATE legacy/src/app/app.ts (234 bytes)
CREATE legacy/src/app/app.html (20144 bytes)
CREATE legacy/public/favicon.ico (15086 bytes)
```

```
ana@dev:~/legacy$ cp ../planner/.npmrc .
ana@dev:~/legacy$ sed 's/"planner"/"legacy"/' ../planner/package.json > package.json
ana@dev:~/legacy$ npm install

added 470 packages, and audited 471 packages in 10s

found 0 vulnerabilities
```

`--skip-install` this time, because the install would fail exactly as it did in lesson 2, and the
`sed` writes the planner's `package.json` with only the name changed. The project is about 320 MB
once installed; the end of this lesson deletes it.

## The module

```
ana@dev:~/legacy$ cat src/app/app-module.ts
import { NgModule, provideBrowserGlobalErrorListeners } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';

import { AppRoutingModule } from './app-routing-module';
import { App } from './app';

@NgModule({
  declarations: [
    App
  ],
  imports: [
    BrowserModule,
    AppRoutingModule
  ],
  providers: [
    provideBrowserGlobalErrorListeners(),
  ],
  bootstrap: [App]
})
export class AppModule { }
```

Five fields, and each one is a list:

| field | what it lists |
|---|---|
| `declarations` | the components, directives and pipes that **belong** to this module. Each one belongs to exactly one |
| `imports` | other modules whose exported pieces this module's templates may use |
| `exports` | which of its own pieces, or of its imports, other modules may use. Empty here, so nothing is offered |
| `providers` | what can be injected; lesson 10 is about this |
| `bootstrap` | the component to draw at start-up, only in the root module |

**The template scope is the module's.** Every component declared in `AppModule` may use everything
declared in it and everything its imports export, and no component has its own list. That is the
one idea standalone changed: the scope moved from the module to the component.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Two ways to decide what a template may use. On the left, a module: one box, AppModule, declares App and SessionList and imports BrowserModule and RouterModule, and both components share that one scope. On the right, standalone: each component carries its own imports list, App importing RouterOutlet and Week, and Week importing WeekSummary.\"><text x=\"180\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">NgModule: the module decides</text><text x=\"540\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">standalone: each component decides</text><line x1=\"360\" y1=\"8\" x2=\"360\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></line><rect x=\"30\" y=\"34\" width=\"300\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"180\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">AppModule</text><text x=\"180\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one scope, shared by everything declared</text><rect x=\"50\" y=\"90\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">App</text><rect x=\"190\" y=\"90\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SessionList</text><text x=\"180\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">declarations</text><rect x=\"50\" y=\"168\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"110\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BrowserModule</text><rect x=\"190\" y=\"168\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"250\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">RouterModule</text><text x=\"180\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">imports</text><rect x=\"390\" y=\"50\" width=\"300\" height=\"82\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"406\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">App</text><text x=\"406\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">imports:</text><rect x=\"476\" y=\"82\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"524\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">RouterOutlet</text><rect x=\"580\" y=\"82\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"628\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Week</text><rect x=\"390\" y=\"150\" width=\"300\" height=\"82\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"406\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">Week</text><text x=\"406\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">imports:</text><rect x=\"476\" y=\"182\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"524\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">WeekSummary</text><text x=\"540\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no module anywhere</text></svg>", "caption": "Standalone moved the list of what a template may use from the module to the component."}
```

The component says so in its decorator, and the start-up code asks for a module rather than a
component:

```
ana@dev:~/legacy$ cat src/app/app.ts
import { Component, signal } from '@angular/core';

@Component({
  selector: 'app-root',
  templateUrl: './app.html',
  standalone: false,
  styleUrl: './app.css'
})
export class App {
  protected readonly title = signal('legacy');
}
```

`standalone: false` is the line that marks the old model. In code written before Angular 19 you will
not see it at all, because then it was the default; you will see `standalone: true` on the
components that had already moved.

`AppRoutingModule` is a module whose only job is to configure the router, with
`RouterModule.forRoot(routes)` and export `RouterModule` so the templates can use
`<router-outlet>`. Every module-based application has one, and `forRoot` against `forChild` is the
detail that tells the root's routes from a feature's.

## A component, declared

Generate a component in this project and the CLI does what a module-based project needs:

```
ana@dev:~/legacy$ npx ng generate component session-list
CREATE src/app/session-list/session-list.css (0 bytes)
CREATE src/app/session-list/session-list.spec.ts (572 bytes)
CREATE src/app/session-list/session-list.ts (215 bytes)
CREATE src/app/session-list/session-list.html (27 bytes)
UPDATE src/app/app-module.ts (513 bytes)
```

`UPDATE src/app/app-module.ts` is the CLI adding `SessionList` to `declarations`. Forget that line, in
a project where people add components by hand, and the template using `<app-session-list>` fails with
the same `NG8001` you saw in the previous section. In a module-based project the fix goes in the
**module**, either `declarations` or the `imports` of a module that exports it, and that is the
question to ask first when you meet the error at work: which module declares this, and does it
export it?

Larger applications split into **feature modules**, one per area, and a `SharedModule` that declares
the buttons and pipes everybody uses and exports them all. It works, and it has a known cost: every
component that imports `SharedModule` can use everything in it, so nobody can tell from a component
what it really depends on. That cost is what standalone was introduced to remove.
