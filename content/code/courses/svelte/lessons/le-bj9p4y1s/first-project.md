---
title: The planner, as an empty project
version: 1
---

**A SvelteKit project is a folder made by one command, and everything in this course happens in
it.** The command is `sv`, Svelte's own command-line tool, run through `npx` so that nothing is
installed globally. Run it from your home directory:

```sh
npx sv@1.1.1 create planner --template minimal --no-types --no-add-ons --install npm
```

Each option answers a question `sv` would otherwise ask. `--template minimal` is the smallest
project, with one page and nothing to delete. `--no-types` makes it plain JavaScript, which lesson
18 converts to TypeScript. `--no-add-ons` declines the optional tools it offers, such as a linter
and a test runner, which this course adds itself when it needs them: Vitest and Playwright in
lesson 19. `--install npm` installs the project's packages straight away. `npx` asks before
fetching `sv` itself the first time; answer `y`. It prints a welcome box while npm works and ends
with `You're all set!`.

## What it made

```
ana@dev:~$ cd planner
ana@dev:~/planner$ ls -A
.gitignore
.npmrc
.svelte-kit
.vscode
README.md
jsconfig.json
node_modules
package-lock.json
package.json
src
static
vite.config.js
ana@dev:~/planner$ ls src src/routes src/lib
src:
app.html
lib
routes

src/lib:
assets
index.js

src/routes:
+layout.svelte
+page.svelte
ana@dev:~/planner$ npm pkg get devDependencies
{
  "@sveltejs/adapter-auto": "^8.0.0",
  "@sveltejs/kit": "^3.0.0",
  "@sveltejs/vite-plugin-svelte": "^7.2.0",
  "svelte": "^5.57.1",
  "vite": "^8.3.0"
}
```

**Four things in it are yours to edit.** `src/routes` holds the pages, one folder per address, and
`+page.svelte` is the page at `/`. `src/lib` is for everything else you write, and lesson 3 starts
filling it. `static` holds files served exactly as they are. `package.json` says which packages the
project uses. The rest is generated or configuration you will rarely touch: `.svelte-kit` is
SvelteKit's working folder and `node_modules` holds the packages.

The `^` in front of each version means "this or any later 5.x", or 3.x, or 8.x. Two people who
install on different days can get different versions under the same `package.json`, and
`package-lock.json` is what stops that, by recording the exact versions installed. This course goes
one step further and writes the exact versions into `package.json` too, so that the file itself says
what the lessons were recorded with:

```
ana@dev:~/planner$ npm install --save-dev --save-exact svelte@5.57.2 @sveltejs/kit@3.1.0 vite@8.3.5 @sveltejs/vite-plugin-svelte@7.3.1 @sveltejs/adapter-auto@8.0.0

added 2 packages, removed 1 package, and audited 50 packages in 2s

11 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner$ npm config set save-exact true --location=project
ana@dev:~/planner$ cat .npmrc
engine-strict=true
save-exact=true
ana@dev:~/planner$ npm pkg get devDependencies
{
  "@sveltejs/adapter-auto": "8.0.0",
  "@sveltejs/kit": "3.1.0",
  "@sveltejs/vite-plugin-svelte": "7.3.1",
  "svelte": "5.57.2",
  "vite": "8.3.5"
}
```

`npm config set save-exact true --location=project` writes `save-exact=true` into the project's
own `.npmrc`, beside the `engine-strict=true` `sv` put there, so every package a later lesson adds
is pinned the same way without anybody remembering the flag. `engine-strict` makes npm refuse to
install a package whose declared Node version you do not have, instead of only warning about it.

Then the first commit, as the `git` course taught you to make one:

```
ana@dev:~/planner$ git init -q
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -qm "A new SvelteKit project" && git log --oneline
8e9c4e9 A new SvelteKit project
```

`.gitignore` came from `sv` and already leaves out `node_modules` and `.svelte-kit`, so the commit
holds what you would want to keep and nothing a reinstall makes again.

## Running it

`npm run dev` starts **Vite's development server**. It compiles each component when the browser
asks for it, and recompiles it the moment you save the file. Run it in a second terminal and leave
it running for the rest of the lesson:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

7:15:31 PM [vite] (ssr) connected.
7:15:31 PM [vite] (client) Forced re-optimization of dependencies

  VITE v8.3.5  ready in 1411 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

The `(ssr)` and `(client)` in front of the first two lines are Vite's two environments, one for
the code that renders pages on the server and one for the browser, which is the first sign of
something lesson 15 is about. The page is at
`http://localhost:5173/`. Back in the first terminal:

```
ana@dev:~/planner$ look http://localhost:5173/
at /
- heading "Welcome to SvelteKit" [level=1]
- paragraph:
  - text: Visit
  - link "svelte.dev/docs/kit":
    - /url: https://svelte.dev/docs/kit
  - text: to read the documentation
```

That is the page `src/routes/+page.svelte` makes. Replace that file with the planner's first
version, which is nothing more than a heading and a sentence inside a `<main>`:

```html
<!-- src/routes/+page.svelte -->
<main>
	<h1>Study planner</h1>
	<p>Three courses, six sessions, and one week to fit them in.</p>
</main>
```

Save it, and ask again:

```
ana@dev:~/planner$ look http://localhost:5173/
at /
- main:
  - heading "Study planner" [level=1]
  - paragraph: Three courses, six sessions, and one week to fit them in.
```

**Nothing was restarted.** Vite saw the file change, compiled it again and sent the new version to
any browser that had the page open, which is called **hot module replacement**. A browser window on
your desktop updates as you save, without a reload, and that loop is how you will work for the rest
of the course. `look` opens a fresh browser each time, so it shows the new page either way.
