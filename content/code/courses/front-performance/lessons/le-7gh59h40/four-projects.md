---
title: Four projects, side by side
version: 1
---

**This lesson builds the same two pages of the planner four times, once in each meta-framework,
in a folder of their own: `~/meta`.** The list of courses at `/` and a course's sessions at
`/courses/<slug>`, read on the server from the same `courses.json` as lesson 1. Nothing else: no
form and no button, because what is being compared is how each one routes, renders and sends a
page, not how it handles a click. That is what the framework courses are for.

| meta-framework | version | its UI framework | made with |
|---|---|---|---|
| Next.js | 16.4.3 | React 19.3 | `create-next-app` |
| Nuxt | 4.6.2 | Vue 3.5 | `create-nuxt` |
| SvelteKit | 3.1.0 | Svelte 5.57 | `sv` |
| Angular SSR | 21.2 | Angular 21.2 | the Angular CLI |

The four projects take about 1.1 GB of disk between them, almost all of it in their
`node_modules`. Lessons 2, 3 and 4 use them, and `~/meta` can be deleted after that.

## Angular 21, not 22

Angular's newest version is 22, and it refuses the Node this track installed:

```
ana@dev:~$ npx --yes @angular/cli@22.2.4 version
Node.js version v22.22.0 detected.
The Angular CLI requires a minimum Node.js version of v22.22.3 or v24.15.0 or v26.0.0.

Please update your Node.js version or visit https://nodejs.org/ for additional instructions.
```

**Angular 22 asks for Node 22.22.3 or later, and the track's Node is 22.22.0.** Installing a second
Node for one framework is exactly what this course does not do, so this lesson uses Angular 21,
whose CLI accepts any Node from 22.12. Angular 21 is still supported by the Angular team, and
everything this lesson shows works the same way in 22. If you installed a later Node 22 than the
track's, Angular 22 will run for you; the lesson's files do not change.

## Making them

Each one is made by its own program, with the options that give the smallest project: TypeScript,
no styling library, no linter, no Git repository of its own. Type these in a new folder:

```sh
mkdir ~/meta && cd ~/meta
npx create-next-app@16.4.3 next --ts --app --empty --no-tailwind --no-eslint --no-react-compiler --no-src-dir --import-alias "@/*" --use-npm --disable-git --no-agents-md --no-agent-feedback
npm create nuxt@4.0.1 nuxt -- --template minimal --packageManager npm --no-gitInit --modules=
npx sv@1.1.1 create svelte --template minimal --types ts --add sveltekit-adapter="adapter:node" --install npm
npx @angular/cli@21.2.28 new angular --ssr --defaults --skip-git --skip-tests --style=css --ai-config=none --skip-install
```

Each prints a progress report with coloured symbols and ends with the next steps it suggests;
those reports are not reproduced here. Three of them installed their packages. The Angular line
said `--skip-install`, because its install needs one more step first:

```
ana@dev:~/meta$ cd angular
ana@dev:~/meta/angular$ npm install
npm error Cannot read properties of null (reading 'edgesOut')
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-23T23_00_25_914Z-debug-0.log
ana@dev:~/meta/angular$ echo legacy-peer-deps=true > .npmrc
ana@dev:~/meta/angular$ npm install

added 422 packages, and audited 423 packages in 17s

102 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

**The npm that ships with Node 22.22.0 stops on this project's dependencies with a `TypeError`
from inside npm itself.** It is a bug in how that npm resolves *peer dependencies*, packages a
library expects you to have installed beside it. `legacy-peer-deps=true` in the project's own
`.npmrc` tells npm to install what `package.json` lists and leave peer dependencies to you, which
is safe here: the CLI already wrote every Angular package into `package.json`. The file applies
to every later `npm install` in that folder, and to nothing outside it.

## Exact versions, again

The programs that made the projects wrote ranges into `package.json`, such as `^4.6.2` and `~5.9.2`,
which let a later install take a newer version. `pin.mjs` replaces each range with the version npm
actually installed, read from `package-lock.json`. Save it in `~/meta`:

```javascript
// pin.mjs: replace each version range in package.json with the version installed.
import { readFileSync, writeFileSync } from "node:fs";

const pkg = JSON.parse(readFileSync("package.json", "utf8"));
const lock = JSON.parse(readFileSync("package-lock.json", "utf8"));
for (const field of ["dependencies", "devDependencies"]) {
  for (const name of Object.keys(pkg[field] ?? {})) {
    pkg[field][name] = lock.packages[`node_modules/${name}`].version;
  }
}
writeFileSync("package.json", JSON.stringify(pkg, null, 2) + "\n");
```

Then run it in each project, let npm record the change in the lockfile, and copy the planner's data
into each one. Angular serves its data from `public/`, as the planner does; the other three read it
from the project's own folder:

```
ana@dev:~/meta$ for d in next nuxt svelte angular; do (cd $d && node ../pin.mjs && npm install --silent); done
◆ Types generated in .nuxt.
ana@dev:~/meta$ grep -h -E '"(next|nuxt|@sveltejs/kit|@angular/core)":' */package.json
    "@angular/core": "21.2.25",
    "next": "16.4.3",
    "nuxt": "4.6.2",
    "@sveltejs/kit": "3.1.0",
ana@dev:~/meta$ for d in next nuxt svelte; do cp ~/planner/public/courses.json $d/; done
ana@dev:~/meta$ cp ~/planner/public/courses.json angular/public/
ana@dev:~/meta$ du -sh */node_modules
317M	angular/node_modules
491M	next/node_modules
231M	nuxt/node_modules
107M	svelte/node_modules
```

The versions in the table at the top are the ones those lines printed. Next.js and Angular can send
anonymous statistics about how their tools are used; `npx next telemetry disable` in `next` and
`npx ng analytics disable` in `angular` turn that off, and Nuxt's maker had already written it off
for this project. Nothing in this lesson depends on either.
