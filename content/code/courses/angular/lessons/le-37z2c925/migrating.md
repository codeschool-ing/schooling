---
title: Moving a module-based project to standalone
version: 1
---

**Angular ships a migration that converts a module-based project to standalone, in three steps, and
each step leaves a project that still builds.** That is what makes it usable at work: you can run one
step, commit, ship, and run the next one next month. This section runs all three on `~/legacy`.

Start from a commit, so that each step's changes are the only thing in `git diff`, the habit lesson 2's
`ng update` insisted on:

```
ana@dev:~/legacy$ git init -q && git add -A && git commit -q -m "A module-based project"
```

The migration is a schematic, so `ng generate` runs it, and `--mode` chooses the step. Each run opens
with three lines congratulating you and reminding you to check the result; `tail -n +4` leaves them
out of the transcripts below, and the reminder is a good one.

## Step 1: convert the declarations

```
ana@dev:~/legacy$ npx ng generate @angular/core:standalone --mode=convert-to-standalone 2>&1 | tail -n +4
UPDATE src/app/session-list/session-list.ts (198 bytes)
UPDATE src/app/app-module.ts (488 bytes)
ana@dev:~/legacy$ git diff
diff --git a/src/app/app-module.ts b/src/app/app-module.ts
index 4952227..62e5838 100644
--- a/src/app/app-module.ts
+++ b/src/app/app-module.ts
@@ -6,8 +6,8 @@ import { App } from './app';
 import { SessionList } from './session-list/session-list';
 
 @NgModule({
-  declarations: [App, SessionList],
-  imports: [BrowserModule, AppRoutingModule],
+  declarations: [App],
+  imports: [BrowserModule, AppRoutingModule, SessionList],
   providers: [provideBrowserGlobalErrorListeners()],
   bootstrap: [App],
 })
diff --git a/src/app/session-list/session-list.ts b/src/app/session-list/session-list.ts
index ef498c6..ad1bb7e 100644
--- a/src/app/session-list/session-list.ts
+++ b/src/app/session-list/session-list.ts
@@ -2,7 +2,6 @@ import { Component } from '@angular/core';
 
 @Component({
   selector: 'app-session-list',
-  standalone: false,
   templateUrl: './session-list.html',
   styleUrl: './session-list.css',
 })
```

`SessionList` lost `standalone: false`, so it is standalone now, and the module moved it from
`declarations` to `imports`: **a module can import a standalone component** as if it were a module.
`App` was left alone, because it is the component the module bootstraps, and that is step 3's
business.

## Step 2: remove the modules nothing needs

```
ana@dev:~/legacy$ npx ng generate @angular/core:standalone --mode=prune-ng-modules 2>&1 | tail -n +4
Nothing to be done.
```

Nothing to be done here, and that is a real answer: this step deletes modules that have become empty,
that declare nothing and only pass imports along, and `AppModule` still bootstraps `App`. In a large
application this is the step that deletes a dozen files.

## Step 3: bootstrap without a module

```
ana@dev:~/legacy$ npx ng generate @angular/core:standalone --mode=standalone-bootstrap 2>&1 | tail -n +4
DELETE src/app/app-module.ts
UPDATE src/main.ts (481 bytes)
UPDATE src/app/app.ts (296 bytes)
```

```
ana@dev:~/legacy$ cat src/main.ts
import { platformBrowser, BrowserModule, bootstrapApplication } from '@angular/platform-browser';

import { provideBrowserGlobalErrorListeners, importProvidersFrom } from '@angular/core';
import { AppRoutingModule } from './app/app-routing-module';
import { App } from './app/app';

bootstrapApplication(App, {
  providers: [
    importProvidersFrom(BrowserModule, AppRoutingModule),
    provideBrowserGlobalErrorListeners(),
  ],
}).catch((err) => console.error(err));
```

`AppModule` is gone. `main.ts` now calls `bootstrapApplication`, as the planner's does, and `App`
lists `RouterOutlet` in its own `imports`. The build is the check the reminder asked for:

```
ana@dev:~/legacy$ npx ng build 2>&1 | tail -3

Output location: /home/ana/legacy/dist/legacy
```

**Read what the migration left, though.** It did not write `provideRouter(routes)`, the way the
planner configures its router; it wrapped the old modules in `importProvidersFrom(BrowserModule,
AppRoutingModule)`, which works and is not what anybody would write today. A migration's job is to
keep the application running, and tidying the result is yours. The next section is about why that
wrapper exists at all.
