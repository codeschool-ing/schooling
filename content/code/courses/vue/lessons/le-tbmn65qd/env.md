---
title: Modes and environment variables
version: 1
---

**Code that runs in the browser has no `process.env`, so Vite gives it `import.meta.env` instead, and
fills it in when it serves or builds the file.** A few names are always there: `MODE`, which is
`development` under `npm run dev` and `production` in a build, `DEV` and `PROD`, its two booleans, and
`BASE_URL`, the `base` of the configuration. The planner's footer can say which kind of page it is:

```html
<!-- src/components/AppFooter.vue -->
<script setup lang="ts">
import { version } from 'vue'

// "development" under the dev server, "production" in a build.
const mode = import.meta.env.MODE
</script>

<template>
  <footer>
    <p>Built with Vue {{ version }}, {{ mode }} build</p>
  </footer>
</template>

<style scoped>
p {
  color: #666;
  font-size: 0.875rem;
}
</style>
```

## The planner's own variable

Anything else comes from files called `.env`, in the project's folder, next to `package.json`. The
planner gets one, for the address it reads its data from, which is the thing most likely to change
when the planner moves to a server of its own:

```sh
# .env: settings for every mode. Only names that start with VITE_ reach the browser.
VITE_DATA_URL=/courses.json
```

TypeScript does not know the name yet. `env.d.ts`, from lesson 16, gets a comment at the top, a
declaration of what `import.meta.env` carries beyond Vite's own names, and a switch Vite's types offer,
`strictImportMetaEnv`, without which any name at all would be accepted and typed `any`:

```typescript
// env.d.ts: what TypeScript knows of the things Vite adds.
/// <reference types="vite/client" />

// A name not declared below is an error, not an `any`.
interface ViteTypeOptions {
  strictImportMetaEnv: unknown
}

// The planner's own settings, as import.meta.env carries them.
interface ImportMetaEnv {
  readonly VITE_DATA_URL: string
}
```

The store's `load` stops naming the address and asks for the variable:

```
ana@dev:~/vue/planner$ sed -i "s#fetch('/courses.json')#fetch(import.meta.env.VITE_DATA_URL)#" src/stores/planner.ts
ana@dev:~/vue/planner$ grep -n VITE_ src/stores/planner.ts
20:    loading ??= fetch(import.meta.env.VITE_DATA_URL)
```

```
ana@dev:~/vue/planner$ npm run type-check

> planner@0.0.0 type-check
> vue-tsc --noEmit
```

A typo in the name is caught there now, before it can become a `fetch(undefined)`:

```
ana@dev:~/vue/planner$ sed -i 's/VITE_DATA_URL/VITE_DATA_ULR/' src/stores/planner.ts
ana@dev:~/vue/planner$ npm run type-check

> planner@0.0.0 type-check
> vue-tsc --noEmit

src/stores/planner.ts(20,39): error TS2551: Property 'VITE_DATA_ULR' does not exist on type 'ImportMetaEnv'. Did you mean 'VITE_DATA_URL'?
```

Put the name right again. A running dev server watches `.env` the way it watches its configuration,
and restarts itself when the file changes (`.env changed, restarting server...`). The footer reports
the mode:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --text '#app > footer'
[vite] connecting...
[vite] connected.
== the text of #app > footer
Built with Vue 3.5.44, development build
```

## Replaced, not read

In a build, `import.meta.env.VITE_DATA_URL` is not looked up when the page runs. **Vite replaces the
expression with its value while it builds**, so the built file contains the string itself. To see
the other half of the rule in the comment, add a second variable without the prefix and build:

```
ana@dev:~/vue/planner$ echo 'PLANNER_NOTE=not-for-the-browser' >> .env
ana@dev:~/vue/planner$ npm run build > /dev/null
ana@dev:~/vue/planner$ grep -c 'courses.json' dist/assets/index-*.js
1
ana@dev:~/vue/planner$ cat dist/assets/*.js | grep -c 'not-for-the-browser'
0
```

**The address is in the bundle once; the note is in it nowhere.** Vite exposes only the names that
start with `VITE_`, because a `.env` file often holds things meant for tools and servers, and anything
in the bundle is public: every visitor downloads it and can read it with the browser's own tools. So
the prefix is a promise you make about a value, **this may be published**, and never a place for a
password or a private API key. A key that must stay secret stays on a server, and the browser asks
that server, which is what the `server` folder of Nuxt in lesson 18 is for. Take the note out of
`.env` again; the planner has no use for it.

The preview of that build says the other mode:

```
ana@dev:~/vue/planner$ look http://localhost:4173/ --text '#app > footer'
== the text of #app > footer
Built with Vue 3.5.44, production build
```

## A mode of your own

`MODE` is not limited to the two. `vite build --mode staging` builds for a mode called `staging`, and
Vite reads `.env.staging` after `.env`, so a name in both takes the value of the mode's file:

```
ana@dev:~/vue/planner$ echo 'VITE_DATA_URL=/staging.json' > .env.staging
ana@dev:~/vue/planner$ npx vite build --mode staging > /dev/null
ana@dev:~/vue/planner$ grep -o '/[a-z]*\.json' dist/assets/index-*.js
/staging.json
ana@dev:~/vue/planner$ rm .env.staging
ana@dev:~/vue/planner$ npm run build > /dev/null
```

The `rm` and the last build put the planner back as it was. The order, from weakest to strongest, is
`.env`, `.env.local`, `.env.[mode]` and `.env.[mode].local`, and a variable already set in the shell
that started Vite beats all four. The two `.local` files are for values on one computer only, and the
`.gitignore` that `create-vue` wrote already has a line `*.local`, so git leaves them out.
