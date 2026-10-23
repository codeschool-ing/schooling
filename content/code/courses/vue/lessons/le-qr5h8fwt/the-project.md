---
title: The planner, created
version: 1
---

**A Vue project is a folder that a tool called create-vue writes for you, and this course grows one
of them, a study planner, from this section to lesson 21.** The planner is small on purpose. It lists
the courses you are taking, opens one, lets you add study sessions with a date and a length, marks
them done, and adds up the week. Every idea in the course arrives as something the planner needs.

## create-vue

`npm create vue` downloads create-vue and runs it. Asked with no options, it asks a series of
questions; asked with a feature named, it asks none. Its `--default` gives a TypeScript project, which
is lesson 16's subject, so this course names the one feature it wants instead: **Prettier**, a program
that formats your code, and the cheapest way to say "JavaScript, please" without answering questions.
`--bare` leaves out the example components a new project would otherwise start with.

```
ana@dev:~/vue$ npm create vue@3.24.0 -- --prettier --bare planner
npm warn exec The following package was not found and will be installed: create-vue@3.24.0

> npx
> create-vue --prettier --bare planner

┌  Vue.js - The Progressive JavaScript Framework

Scaffolding project in /home/ana/vue/planner...
│
└  Done. Now run:

   cd planner
   npm install
   npm run format
   npm run dev

| Optional: Initialize Git in your project directory with:

   git init && git add -A && git commit -m "initial commit"
```

The `@3.24.0` pins create-vue itself, and the `--` hands everything after it to create-vue rather
than to npm. This is what it wrote:

```
ana@dev:~/vue/planner$ find . -type f | sort
./.gitignore
./.prettierrc.json
./.vscode/extensions.json
./.vscode/settings.json
./README.md
./index.html
./jsconfig.json
./package.json
./public/favicon.ico
./src/App.vue
./src/main.js
./vite.config.js
ana@dev:~/vue/planner$ cat package.json
{
  "name": "planner",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "format": "prettier --write --experimental-cli src/"
  },
  "dependencies": {
    "vue": "^3.5.42"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^6.0.8",
    "prettier": "3.9.6",
    "vite": "^8.2.2",
    "vite-plugin-vue-devtools": "^8.2.1"
  },
  "engines": {
    "node": "^22.18.0 || >=24.12.0"
  }
}
```

**Look at the versions.** `^3.5.42` means "3.5.42 or any later 3.x", so two people running
`npm install` a month apart can end up with different Vue. That is the convenience npm chose by
default, and this course turns it off: every package is pinned to the exact version it was recorded
with. Replace `package.json` with this:

```schooling-example
{"language": "json", "file": "package.json", "parts": [
 {"code": "{\n  \"name\": \"planner\",\n  \"version\": \"0.0.0\",\n  \"private\": true,\n  \"type\": \"module\",\n  \"scripts\": {\n    \"dev\": \"vite\",\n    \"build\": \"vite build\",\n    \"preview\": \"vite preview\",\n    \"format\": \"prettier --write --experimental-cli src/\"\n  },", "note": "Name, scripts and module type stay as create-vue wrote them. `npm run dev` runs `vite`."},
 {"code": "  \"dependencies\": {\n    \"vue\": \"3.5.44\"\n  },", "note": "Vue itself, pinned to 3.5.44: no caret, so no later version slips in."},
 {"code": "  \"devDependencies\": {\n    \"@vitejs/plugin-vue\": \"6.0.10\",\n    \"prettier\": \"3.9.6\",\n    \"vite\": \"8.3.5\"\n  },", "note": "The tools that build the project and never reach a browser. vite-plugin-vue-devtools is gone; the next paragraph says why."},
 {"code": "  \"engines\": {\n    \"node\": \"^22.18.0 || >=24.12.0\"\n  }\n}", "note": "The Node versions Vite 8 runs on. 22.22.0 is inside the first range."}
]}
```

**create-vue also added a plugin that puts Vue's developer tools inside the page.** It is useful, and
it fills every page with requests and a floating button that have nothing to do with your code. This
course leaves it out, and its configuration file loses the line that loaded it. The same tools exist
as a browser extension, *Vue.js devtools*, for Chrome and Firefox, if you want them in your own
browser.

```schooling-example
{"language": "javascript", "file": "vite.config.js", "parts": [
 {"code": "import { fileURLToPath, URL } from 'node:url'\n\nimport { defineConfig } from 'vite'\nimport vue from '@vitejs/plugin-vue'", "note": "Vite's configuration is a JavaScript module. `defineConfig` only helps an editor suggest the options."},
 {"code": "// https://vite.dev/config/\nexport default defineConfig({\n  plugins: [vue()],", "note": "The one plugin left teaches Vite what a `.vue` file is. Lesson 17 opens it up."},
 {"code": "  resolve: {\n    alias: {\n      '@': fileURLToPath(new URL('./src', import.meta.url)),\n    },\n  },\n})", "note": "`@` is a short name for the `src` folder, so `import x from '@/planner.js'` works from any depth."}
]}
```

And the page the browser opens first, given a language and a real title:

```schooling-example
{"language": "html", "file": "index.html", "parts": [
 {"code": "<!DOCTYPE html>\n<html lang=\"en\">\n  <head>\n    <meta charset=\"UTF-8\">\n    <link rel=\"icon\" href=\"/favicon.ico\">\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n    <title>Study planner</title>\n  </head>", "note": "`lang=\"en\"` tells a screen reader which voice to use. create-vue left it empty."},
 {"code": "  <body>\n    <div id=\"app\"></div>\n    <script type=\"module\" src=\"/src/main.js\"></script>\n  </body>\n</html>", "note": "Vue will take over this one element. Everything you write ends up inside it."}
]}
```

## Installing and starting it

```
ana@dev:~/vue/planner$ npm install

added 36 packages, and audited 37 packages in 8s

10 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/vue/planner$ ls
README.md
index.html
jsconfig.json
node_modules
package-lock.json
package.json
public
src
vite.config.js
ana@dev:~/vue/planner$ npm ls
planner@0.0.0 /home/ana/vue/planner
├── @vitejs/plugin-vue@6.0.10
├── prettier@3.9.6
├── vite@8.3.5
└── vue@3.5.44
```

`npm install` read `package.json`, fetched those packages and everything they need into
`node_modules`, and wrote **`package-lock.json`**, which records the exact version of every one of them,
the ones you did not name included. **Keep the lockfile with your project and commit it**: it is what
makes the next `npm install`, on any machine, fetch the same tree. `npm ls` shows the top of that tree,
and every version is the one pinned above.

Now the dev server. Start it in **a second terminal**, because it keeps running until you press
Ctrl-C:

```
ana@dev:~/vue/planner$ npm run dev

> planner@0.0.0 dev
> vite


  VITE v8.3.5  ready in 430 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

**Vite** is the program that serves the project while you work on it; lesson 17 is about what it does
and why Vue's author wrote it. Open `http://localhost:5173/` in your own browser and you will see a
heading. In the first terminal, `look` opens the same address in Chromium and prints the page's text:

```
ana@dev:~/vue/planner$ look http://localhost:5173/
[vite] connecting...
[vite] connected.
== the text of #app
You did it!

Visit vuejs.org to read the documentation
```

Two lines came before the text. They are the page's console: Vite's own script in the page, connecting
back to the dev server so that it can push your edits to the browser as you save them.
