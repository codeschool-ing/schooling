---
title: What ng new wrote
version: 1
---

**An Angular project is a handful of configuration files at the top and an application under
`src/`.** You will edit almost nothing at the top and almost everything under `src/`, and knowing
which file does what saves the afternoon somebody spends looking for a setting in the wrong one.

```
ana@dev:~/planner$ ls -A
.editorconfig
.git
.gitignore
.npmrc
.prettierrc
.vscode
README.md
angular.json
node_modules
package-lock.json
package.json
public
src
tsconfig.app.json
tsconfig.json
tsconfig.spec.json
```

## The files at the top

| file | what it is for |
|---|---|
| `package.json`, `package-lock.json`, `.npmrc` | the packages, their exact versions, and how npm installs them; the previous section |
| `angular.json` | the CLI's own configuration: what `ng build`, `ng serve` and `ng test` do |
| `tsconfig.json`, `tsconfig.app.json`, `tsconfig.spec.json` | TypeScript's settings, for everything, for the application, and for the tests |
| `.editorconfig`, `.prettierrc` | indentation and quotes, for your editor and for Prettier |
| `.vscode/` | suggestions for Visual Studio Code: lesson 1's extension, and how to run and debug |
| `.gitignore` | what git leaves out: `node_modules`, the build output, caches |
| `README.md` | a page of the commands below, for whoever opens the project next |

`angular.json` is long, and most of it is defaults written out. Its heart is three **targets**,
one per command, each naming the **builder**, the program that does the work:

```
ana@dev:~/planner$ node -e "console.log(Object.keys(require('./angular.json').projects.planner.architect))"
[ 'build', 'serve', 'test' ]
```

`ng build` runs the `build` target, `ng serve` the `serve` target, and so on. A target has
**configurations**: `production` and `development` for the build, with different answers to
questions such as whether to minify. The sections below use each one.

`tsconfig.json` opens with `"strict": true`, the switch lesson 1 passed to `tsc` by hand, and its
`angularCompilerOptions` turn on `strictTemplates`: **templates are type-checked as strictly as the
code**, which lesson 4 relies on.

## The application

```
ana@dev:~/planner$ find src public -type f | sort
public/favicon.ico
src/app/app.config.ts
src/app/app.css
src/app/app.html
src/app/app.routes.ts
src/app/app.spec.ts
src/app/app.ts
src/index.html
src/main.ts
src/styles.css
```

The browser asks for one page, `src/index.html`, and it is almost empty:

```
ana@dev:~/planner$ cat src/index.html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Planner</title>
  <base href="/">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="icon" type="image/x-icon" href="favicon.ico">
</head>
<body>
  <app-root></app-root>
</body>
</html>
```

`<app-root></app-root>` is not HTML the browser knows. It is the place the application draws
itself, and the name comes from the root component's `selector`. Nothing else in the page is
written by you; the build adds the `<script>` and `<link>` tags.

`src/main.ts` is the first code that runs:

```
ana@dev:~/planner$ cat src/main.ts
import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { App } from './app/app';

bootstrapApplication(App, appConfig)
  .catch((err) => console.error(err));
```

`bootstrapApplication` takes the root component, `App`, and a configuration, builds the
application, and draws `App` where `<app-root>` is. If it fails, the `catch` prints why in the
browser's console, which is the first place to look when a page stays blank.

The configuration is in its own file:

```
ana@dev:~/planner$ cat src/app/app.config.ts
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter } from '@angular/router';

import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes)
  ]
};
```

`providers` is a list of things the application can be given when it asks: the router, here, and
a listener that sends errors nobody caught to Angular's error handler. Lesson 10 is about what a
provider is; for now, read the list as the application's settings, written as function calls.

And the root component itself, which lesson 3 takes apart line by line:

```
ana@dev:~/planner$ cat src/app/app.ts
import { Component, signal } from '@angular/core';
import { RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly title = signal('planner');
}
```

`templateUrl` and `styleUrl` point at the two files beside it, `app.html` and `app.css`.
`app.html` is the welcome page, all 20 kilobytes of it, and the next section replaces it.
`app.spec.ts` is the test of this component, and the section on `ng test` breaks it on purpose.
`app.routes.ts` is the router's list of addresses, empty until lesson 17. `public/` is copied into
the build as it is; the planner's data goes there in the next section.
