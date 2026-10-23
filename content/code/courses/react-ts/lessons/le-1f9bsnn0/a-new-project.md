---
title: A new project, with every version pinned
version: 1
---

**One command creates the project, and four more make it reproducible.** `create-vite` writes a
React and TypeScript app into a new folder; npm then installs what it asks for, at versions you
fix by hand so that your project and the one in these transcripts are made of the same code.

## Creating it

From your home directory:

```
ana@dev:~$ npm create vite@9.3.1 planner -- --template react-ts --no-interactive
npm warn exec The following package was not found and will be installed: create-vite@9.3.1

> npx
> cva planner --template react-ts --no-interactive


create-vite v9.3.1

│
◇  Scaffolding project in /home/ana/planner...
│
└  Done. Now run:

  cd planner
  npm install
  npm run dev

```

`npm create vite@9.3.1` downloads the package `create-vite` at that version and runs it. Everything
after the `--` is passed to it rather than to npm: the folder to create, the template, and
`--no-interactive`, which takes the defaults instead of asking questions. Without the version, npm
would fetch whatever `create-vite` is newest on the day you type it, and its template might not be
the one this course was written against.

`cd planner` and look at what it wrote:

```
ana@dev:~/planner$ ls -A
.gitignore
.oxlintrc.json
README.md
index.html
package.json
public
src
tsconfig.app.json
tsconfig.json
tsconfig.node.json
vite.config.ts
```

`index.html` is the page, and `src/` is the app; `src/main.tsx` was the file in the first section.
`public/` holds files served exactly as they are. The three `tsconfig` files configure TypeScript,
one for the app and one for the build configuration, joined by the third; lesson 19 reads them.
`vite.config.ts` configures Vite, and `.oxlintrc.json` configures Oxlint, a linter lesson 23 meets.

## What it asks for, and what that means

```
ana@dev:~/planner$ cat package.json
{
  "name": "planner",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "lint": "oxlint",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^19.3.1",
    "react-dom": "^19.3.1"
  },
  "devDependencies": {
    "@types/node": "^24.19.2",
    "@types/react": "^19.3.0",
    "@types/react-dom": "^19.3.0",
    "@vitejs/plugin-react": "^6.1.2",
    "oxlint": "^1.88.0",
    "typescript": "~6.0.3",
    "vite": "^8.3.4"
  }
}
```

Two packages run in the browser, `react` and `react-dom`, under `dependencies`. The seven under
`devDependencies` are tools that run on your computer while you work and never reach a visitor.

The characters in front of the numbers are ranges, and `javascript` lesson 21 explained them.
**`^19.3.1` means any 19 from 19.3.1 up**, so a `npm install` next month may fetch 19.4. `~6.0.3`
means any 6.0 from 6.0.3 up. A range is the template being polite: it lets you receive fixes
without asking. It also means two people who install the same `package.json` on different days can
get different code, and a course whose transcripts must match yours cannot have that.

One entry is also the wrong version for this computer. `@types/node` describes Node's own
interfaces to TypeScript, and the template asks for the descriptions of Node 24 while this course
runs Node 22. They only describe the build configuration, so nothing breaks today, and the right
version is still the one that matches the Node you run.

## Pinning it

First, tell npm to write exact versions in this project from now on. `--location=project` puts the
setting in a file in this folder, `.npmrc`, so it travels with the project and does not change how
npm behaves anywhere else:

```
ana@dev:~/planner$ npm config set save-exact true --location=project
ana@dev:~/planner$ cat .npmrc
save-exact=true
```

Then install each package at the version this course uses. Naming the versions replaces the ranges:

```
ana@dev:~/planner$ npm install react@19.3.1 react-dom@19.3.1

added 27 packages, and audited 28 packages in 12s

9 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner$ npm install --save-dev typescript@6.0.3 vite@8.3.5 @vitejs/plugin-react@6.1.2 @types/react@19.3.0 @types/react-dom@19.3.0 @types/node@22.20.5 oxlint@1.88.0

added 2 packages, changed 4 packages, and audited 30 packages in 11s

10 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

The first `npm install` read the whole `package.json` as well as the two names on its line, so
it installed everything the template asked for. The second changed four of those from the version the range had
picked to the one named, `@types/node` among them. Now the file says exactly one
version for each:

```
ana@dev:~/planner$ cat package.json
{
  "name": "planner",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "lint": "oxlint",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "19.3.1",
    "react-dom": "19.3.1"
  },
  "devDependencies": {
    "@types/node": "22.20.5",
    "@types/react": "19.3.0",
    "@types/react-dom": "19.3.0",
    "@vitejs/plugin-react": "6.1.2",
    "oxlint": "1.88.0",
    "typescript": "6.0.3",
    "vite": "8.3.5"
  }
}
ana@dev:~/planner$ npm ls
planner@0.0.0 /home/ana/planner
├── @types/node@22.20.5
├── @types/react-dom@19.3.0
├── @types/react@19.3.0
├── @vitejs/plugin-react@6.1.2
├── oxlint@1.88.0
├── react-dom@19.3.1
├── react@19.3.1
├── typescript@6.0.3
└── vite@8.3.5

```

**React is 19.3.1, TypeScript 6.0.3 and Vite 8.3.5**, and every lesson that adds a package adds it
the same way. npm's newest TypeScript on the day this was recorded was 7.0.2; the template asks for
6.0, and the course keeps the template's choice rather than second-guessing it.

`package.json` names your packages, and those packages have packages of their own: 30 in all, from
two lines of `dependencies`. **`package-lock.json` is the file that records every one of them**, at
the version installed and with a checksum of its contents:

```
ana@dev:~/planner$ ls -A
.gitignore
.npmrc
.oxlintrc.json
README.md
index.html
node_modules
package-lock.json
package.json
public
src
tsconfig.app.json
tsconfig.json
tsconfig.node.json
vite.config.ts
```

**Commit the lockfile with the project, and never `node_modules`**, which the template's
`.gitignore` already leaves out. Anybody who clones the project then runs `npm ci`, which installs
exactly what the lockfile says and refuses to start if it disagrees with `package.json`.

## Running it

The development server stays running while you work, so give it a terminal of its own:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.0 dev
> vite


  VITE v8.3.5  ready in 301 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

**Open `http://localhost:5173/` in your browser.** You get the template's page: two logos, a heading,
and a button that counts how many times it was pressed. Leave the server running. When you save a
file in `src/`, the page in your browser changes without a reload, and lesson 20 explains how.

The page Vite sends is not quite the `index.html` in the folder. From a second terminal:

```
ana@dev:~/planner$ curl -s http://localhost:5173/ | head -n 12
<!doctype html>
<html lang="en">
  <head>
    <script type="module">import { injectIntoGlobalHook } from "/@react-refresh";
injectIntoGlobalHook(window);
window.$RefreshReg$ = () => {};
window.$RefreshSig$ = () => (type) => type;</script>

    <script type="module" src="/@vite/client"></script>

    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
```

The development server added two scripts to the top. `/@vite/client` keeps a connection open to the
server and is told when a file changes; `/@react-refresh` lets the new version of a component replace
the old one in the running page without losing what is on screen. Neither exists in the build you
would publish, which lesson 20 makes and compares.
