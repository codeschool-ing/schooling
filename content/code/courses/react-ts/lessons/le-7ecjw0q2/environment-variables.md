---
title: Environment variables, and what they are not
version: 1
---

**Some values differ between the places an app runs**: the name it shows, the address of its API, a
key for a map service. Vite reads them from **`.env` files** in the project's root and gives the code
the ones it may see, through `import.meta.env`.

Two files. `.env` is read in every mode:

```properties
# Read by Vite in every mode. Only variables starting with VITE_ reach the browser.
VITE_PLANNER_NAME=My study planner
PLANNER_OWNER=ana
```

and `.env.development` only by the development server, on top of it:

```properties
# Read by `vite` (the development server) on top of .env.
VITE_PLANNER_NAME=My study planner (development)
```

TypeScript is told which variables the app reads, in `src/env.d.ts`, so that a typo in a name is an
error and the value has a type:

```ts
// The variables this app reads from import.meta.env, with their types. Vite's own,
// such as MODE and DEV, are already typed by vite/client.
interface ImportMetaEnv {
  readonly VITE_PLANNER_NAME?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
```

Then the week's heading reads the name, with a fallback, and for the length of this section,
`main.tsx` prints everything the code can see:

```
ana@dev:~/planner$ sed -i "s|<h1>Study planner</h1>|<h1>{import.meta.env.VITE_PLANNER_NAME ?? 'Study planner'}</h1>|" src/WeekScreen.tsx && grep -n h1 src/WeekScreen.tsx
15:      <h1>{import.meta.env.VITE_PLANNER_NAME ?? 'Study planner'}</h1>
ana@dev:~/planner$ sed -i '/^const router/i console.log(JSON.stringify(import.meta.env))\n' src/main.tsx && npx tsc -b && echo no errors
no errors
```

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 | sed -n '1,3p'
{"BASE_URL":"/","DEV":true,"MODE":"development","PROD":false,"SSR":false,"VITE_PLANNER_NAME":"My study planner (development)"}
- main:
  - heading "My study planner (development)" [level=1]
```

**What the browser received** is the line above the snapshot. Vite's own five: `BASE_URL`, `DEV`,
`MODE`, `PROD` and `SSR`. Then **`VITE_PLANNER_NAME`, with the development value**, because the
development server reads `.env.development` over `.env`. **`PLANNER_OWNER` is not there**: it does not
start with `VITE_`, so Vite never handed it to the code. That prefix is the whole of the protection.

Now the production build, and the preview server:

```
ana@dev:~/planner$ npm run build > /dev/null && grep -o 'My study planner[^`]*' dist/assets/index-*.js | sort | uniq -c
      2 My study planner
ana@dev:~/planner$ grep -c PLANNER_OWNER dist/assets/index-*.js
0
ana@dev:~/planner$ look http://localhost:4173/ --today 2026-10-21 | sed -n '1,3p'
{"BASE_URL":"/","DEV":false,"MODE":"production","PROD":true,"SSR":false,"VITE_PLANNER_NAME":"My study planner"}
- main:
  - heading "My study planner" [level=1]
```

- **The value is in the built file as text**, twice: once in the heading and once in the line that
  logs the environment. Vite does not look the variable up when the page runs; **it writes the value
  into the code at build time**. Changing it means building again.
- **`PLANNER_OWNER` is in no built file.**
- **The preview server shows `My study planner`**, from `.env` alone: `vite build` runs in
  `production` mode, which does not read `.env.development`. `vite build --mode staging` would read a
  `.env.staging`, for a build meant for somewhere else.

That first point is the one to remember. **A `VITE_` variable is public**: it is in a JavaScript file
that every visitor downloads, and anyone can read it. A secret, a database password or a private API
key, must never be one. Secrets belong on a server, where the browser cannot read them: in the API, or,
in lesson 15's project, in a Server Component, where an environment variable without the prefix stays
on the server. For values that are personal to one machine, Vite also reads **`.env.local`**, which the
template's `.gitignore` already keeps out of git, with its `*.local` line.

The `console.log` was for this section, and goes:

```
ana@dev:~/planner$ sed -i '/^console.log(JSON.stringify(import.meta.env))$/,+1d' src/main.tsx && grep -c console.log src/main.tsx
0
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 42ms on 29 files with 116 rules using 4 threads.
no errors
```
