---
title: Adding Angular Material
version: 1
---

**Angular Material is the Angular team's library of ready-made components: buttons, checkboxes,
dialogs, menus, date pickers, tables, built to the Material Design system and to the accessibility
patterns each kind of control needs.** Under it sits the **CDK**, the Component Dev Kit: the
behaviour without the look, which this lesson uses on its own as well. Neither is part of a new
project; both are packages, added at exact versions like everything else in it.

How big the application is before, to compare with at the end:

```
ana@dev:~/planner$ npx ng build 2>&1 | grep -E 'Initial total|courses-routes'
                      | Initial total  | 294.50 kB |                81.56 kB
chunk-RJNJDY6E.js     | courses-routes |  44.80 kB |                10.34 kB
```

`ng add` installs a package and runs its set-up. The version is the one that matches the project's
Angular 21, written in full. `--skip-confirmation` and `--interactive=false` accept its defaults instead
of asking, which is what a transcript needs; at a terminal of your own, the questions are about the
colours and are safe to answer either way:

```
ana@dev:~/planner$ npx ng add @angular/material@21.2.14 --skip-confirmation --interactive=false
❯ Determining Package Manager
› Using package manager: npm
✔ Determining Package Manager
❯ Loading package information
✔ Loading package information
❯ Installing package
✔ Installing package
UPDATE package.json (845 bytes)
- Installing packages (npm)...
✔ Packages installed successfully.
CREATE src/material-theme.scss (1179 bytes)
UPDATE angular.json (2183 bytes)
UPDATE src/index.html (626 bytes)
```

```
ana@dev:~/planner$ git status --short
 M angular.json
 M package-lock.json
 M package.json
 M src/index.html
?? src/material-theme.scss
```

Two packages in `package.json`, `@angular/material` and `@angular/cdk`, at exact versions because the
project's `.npmrc` says `save-exact`. A theme, `src/material-theme.scss`, added to the build's styles
in `angular.json`:

```
ana@dev:~/planner$ cat src/material-theme.scss
// Include theming for Angular Material with `mat.theme()`.
// This Sass mixin will define CSS variables that are used for styling Angular Material
// components according to the Material 3 design spec.
// Learn more about theming and how to use it for your application's
// custom components at https://material.angular.dev/guide/theming
@use '@angular/material' as mat;

html {
  height: 100%;
  @include mat.theme(
    (
      color: (
        primary: mat.$azure-palette,
        tertiary: mat.$blue-palette,
      ),
      typography: Roboto,
      density: 0,
    )
  );
}

body {
  // Default the application to a light color theme. This can be changed to
  // `dark` to enable the dark color theme, or to `light dark` to defer to the
  // user's system settings.
  color-scheme: light;

  // Set a default background, font and text colors for the application using
  // Angular Material's system-level CSS variables. Learn more about these
  // variables at https://material.angular.dev/guide/system-variables
  background-color: var(--mat-sys-surface);
  color: var(--mat-sys-on-surface);
  font: var(--mat-sys-body-medium);

  // Reset the user agent margin.
  margin: 0;
  height: 100%;
}
```

`mat.theme` turns three choices, colours, a typeface and a density, into the CSS custom properties
every Material component reads, `--mat-sys-surface`, `--mat-sys-on-surface` and the rest, and the
`body` rule uses them for the page. It is Sass, which the Angular build reads without anything more.

**And `index.html`, which now loads two stylesheets from `fonts.googleapis.com`.** Every visit to the
planner would ask Google for a font, telling it who opened the planner and when, and a planner with no
connection would wait for it. The theme falls back to the system's own sans-serif font without them,
so the planner keeps its `index.html` as it was:

```
ana@dev:~/planner$ git checkout -- src/index.html
```

A typeface you want can be installed with the application instead, as a file in `public/` and an
`@font-face` rule, served from the same origin as everything else. The dev server reads `angular.json`
when it starts, so stop it with `Ctrl-C` and start `npx ng serve` again.
