---
title: Installing Storybook
version: 1
---

**Storybook is four packages in the project, pinned like everything else, and two configuration files in
a folder called `.storybook`.** Its own setup command, `npm create storybook`, asks questions and writes
example files; installing the packages by hand is shorter for a project this size and leaves nothing you
did not choose.

```
ana@dev:~/planner$ npm install --save-dev --save-exact storybook@10.6.3 @storybook/html-vite@10.6.3 @storybook/addon-docs@10.6.3 @storybook/addon-a11y@10.6.3 2>&1 | tail -3
  run `npm fund` for details

found 0 vulnerabilities
```

**Storybook 10.6.3**, in four parts: the program itself; `@storybook/html-vite`, the framework for
components that return plain DOM, built with Vite; and two addons, one for documentation pages and one
that runs axe on each story. A project in React, Angular, Vue or Svelte installs that framework's package
instead of `html-vite`, and everything else in this lesson is the same.

## Two files

`main.ts` says where the stories are and what Storybook loads:

```typescript
// .storybook/main.ts
import type { StorybookConfig } from "@storybook/html-vite";

const config: StorybookConfig = {
  framework: "@storybook/html-vite",
  stories: ["../src/**/*.stories.ts"],
  addons: ["@storybook/addon-docs", "@storybook/addon-a11y"],
  core: { disableTelemetry: true },
};

export default config;
```

`disableTelemetry` stops Storybook from sending usage data to its makers, which it does by default and
says so in its documentation. Whether to send it is your choice; the course turns it off so nothing in
these lessons talks to a server you did not ask for.

`preview.ts` sets up the frame each story is drawn in. For now it only loads the planner's stylesheet, so
a story looks as it does in the app; the section on themes adds to it:

```typescript
// .storybook/preview.ts
import type { Preview } from "@storybook/html-vite";
import "../src/style.css";

const preview: Preview = {
  tags: ["autodocs"],
};

export default preview;
```

Add two scripts, one to run the workshop while you work and one to build it:

```
ana@dev:~/planner$ npm pkg set scripts.storybook="storybook dev -p 6006" scripts.build-storybook="storybook build"
```

`npm run storybook` starts it on port 6006 and opens a browser tab; it prints a framed banner, *Storybook
ready!*, with the address, `http://127.0.0.1:6006/`. There are no stories yet, so there is nothing to show;
the next section writes the first.

Two folders it writes should not be committed: the static build, `storybook-static`, and the results
Playwright leaves in the section on tests. Add them to `.gitignore` now:

```
ana@dev:~/planner$ printf 'storybook-static\ntest-results\nplaywright-report\n' >> .gitignore
```
