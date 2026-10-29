---
title: Adding SSR to the planner
version: 1
---

**`ng add @angular/ssr` installs server-side rendering and writes the files it needs.** Stop
`ng serve` first with Ctrl-C, because the command changes `angular.json`, which a running dev server
does not read again. As in lesson 21, the version is written in full and the questions are skipped:

```
ana@dev:~/planner$ npx ng add @angular/ssr@21.2.28 --skip-confirmation --interactive=false
❯ Determining Package Manager
› Using package manager: npm
✔ Determining Package Manager
❯ Loading package information
✔ Loading package information
❯ Installing package
✔ Installing package
                        Package dependency "@angular/ssr" already exists with a different specifier. "21.2.28" will be replaced with "^21.2.28".
CREATE src/main.server.ts (292 bytes)
CREATE src/app/app.config.server.ts (426 bytes)
CREATE src/app/app.routes.server.ts (166 bytes)
CREATE src/server.ts (1609 bytes)
UPDATE angular.json (2412 bytes)
UPDATE tsconfig.app.json (447 bytes)
UPDATE package.json (1073 bytes)
UPDATE src/app/app.config.ts (890 bytes)
- Installing packages (npm)...
✔ Packages installed successfully.
```

One line in the middle needs reading. The CLI installed `@angular/ssr` at exactly `21.2.28`, as the
project's `.npmrc` asks; then the set-up step, which edits `package.json` itself, put a caret in
front of it. It did the same to the three packages it added:

```
ana@dev:~/planner$ git diff package.json
diff --git a/package.json b/package.json
index c10b1b0..c24238f 100644
--- a/package.json
+++ b/package.json
@@ -6,7 +6,8 @@
     "start": "ng serve",
     "build": "ng build",
     "watch": "ng build --watch --configuration development",
-    "test": "ng test"
+    "test": "ng test",
+    "serve:ssr:planner": "node dist/planner/server/server.mjs"
   },
   "private": true,
   "packageManager": "npm@10.9.4",
@@ -18,7 +19,10 @@
     "@angular/forms": "21.2.25",
     "@angular/material": "21.2.14",
     "@angular/platform-browser": "21.2.25",
+    "@angular/platform-server": "21.2.25",
     "@angular/router": "21.2.25",
+    "@angular/ssr": "^21.2.28",
+    "express": "^5.1.0",
     "rxjs": "7.8.2",
     "tslib": "2.8.1"
   },
@@ -26,6 +30,8 @@
     "@angular/build": "21.2.28",
     "@angular/cli": "21.2.28",
     "@angular/compiler-cli": "21.2.25",
+    "@types/express": "^5.0.1",
+    "@types/node": "^20.17.19",
     "jsdom": "28.1.0",
     "prettier": "3.9.10",
     "typescript": "5.9.3",
```

**`^21.2.28` means "21.2.28 or any later 21"**, so the next `npm install` on another computer may
choose a different version from the one this project was tested with. The fix is to install the
four again, at exact versions. While doing that, `@types/node` should describe the Node.js the
project runs on, which is 22, not the 20 the set-up wrote:

```
ana@dev:~/planner$ npm install --save-exact @angular/ssr@21.2.28 express@5.3.0 @types/express@5.0.6 @types/node@22.20.5

changed 1 package, and audited 491 packages in 1s

2 vulnerabilities (1 moderate, 1 high)

To address all issues, run:
  npm audit fix --force

Run `npm audit` for details.
```

Only `@types/node` changed on disk; the other three were already installed at those versions, and
what changed for them is the line in `package.json`. The two vulnerabilities are the ones lesson 22
read in `@angular/build`, not something this command brought in. What is left of the diff is what
the project gained:

```
ana@dev:~/planner$ git diff package.json | grep '^[-+] '
-    "test": "ng test"
+    "test": "ng test",
+    "serve:ssr:planner": "node dist/planner/server/server.mjs"
+    "@angular/platform-server": "21.2.25",
+    "@angular/ssr": "21.2.28",
+    "express": "5.3.0",
+    "@types/express": "5.0.6",
+    "@types/node": "22.20.5",
```

`@angular/platform-server` came in without a caret because it is one of Angular's own packages, and
the CLI writes those at the version the project already has. `express` is the web server
`server.ts` is built on; `@types/express` and `@types/node` give TypeScript the shapes of its
functions and of Node's.

## The files

```
ana@dev:~/planner$ git status --short
 M angular.json
 M package-lock.json
 M package.json
 M src/app/app.config.ts
 M tsconfig.app.json
?? src/app/app.config.server.ts
?? src/app/app.routes.server.ts
?? src/main.server.ts
?? src/server.ts
```

| file | what it is |
| --- | --- |
| `src/main.server.ts` | the server's way in: the same `App`, started with the server's configuration |
| `src/app/app.config.server.ts` | the application's configuration, plus `provideServerRendering` |
| `src/app/app.routes.server.ts` | how each route is rendered, the next section's subject |
| `src/server.ts` | an Express server that serves the built files and renders everything else |
| `angular.json` | `outputMode: "server"`, the two entry points, and a `security` block |
| `src/app/app.config.ts` | `provideClientHydration(withEventReplay())`, for the browser |
| `tsconfig.app.json` | `"types": ["node"]`, so `server.ts` can use Node's own modules |

`app.config.server.ts` is short enough to read whole. It takes the browser's configuration and adds
to it, so every provider the planner has, the router and `HttpClient` included, is on the server as
well:

```
ana@dev:~/planner$ cat src/app/app.config.server.ts
import { mergeApplicationConfig, ApplicationConfig } from '@angular/core';
import { provideServerRendering, withRoutes } from '@angular/ssr';
import { appConfig } from './app.config';
import { serverRoutes } from './app.routes.server';

const serverConfig: ApplicationConfig = {
  providers: [provideServerRendering(withRoutes(serverRoutes))],
};

export const config = mergeApplicationConfig(appConfig, serverConfig);
```

Start the dev server again, in its own terminal, with the same command as always. From now on it
renders each page on the server before it sends it.
